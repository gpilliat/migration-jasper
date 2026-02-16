# 02 — Guide de Migration d'un Rapport JasperReports

Procédure pas-à-pas pour migrer un `.jrxml` d'OpenReport vers ReportServer.

## Étape 1 : Réécriture du JRXML

Avant tout import dans ReportServer, le fichier `.jrxml` doit être corrigé.

### 1.1 Polices

Remplacer **toutes** les polices physiques par des polices logiques Java.

```xml
<!-- ❌ Avant -->
<font fontName="Times-Roman" pdfFontName="Helvetica-Bold" size="10"
      isPdfEmbedded="false" pdfEncoding="CP1252"/>

<!-- ✅ Après -->
<font fontName="Serif" size="10"/>
```

| Rechercher | Remplacer par |
|---|---|
| `fontName="Times-Roman"` | `fontName="Serif"` |
| `fontName="Times New Roman"` | `fontName="Serif"` |
| `fontName="Arial"` | `fontName="SansSerif"` |
| `fontName="Helvetica"` | `fontName="SansSerif"` |
| `fontName="Courier New"` | `fontName="Monospaced"` |
| `fontName=""` | supprimer l'attribut |

Supprimer les attributs : `pdfFontName`, `pdfEncoding`, `isPdfEmbedded`.

### 1.2 Guillemets dans les clauses IN

```sql
-- ❌ OpenReport (guillemets manuels)
AND DEP IN ('$P!{Liste_UFR}')

-- ✅ ReportServer (guillemets automatiques)
AND DEP IN ($P!{Liste_UFR})
```

Rechercher `('$P!{` et `}')` dans tout le JRXML.

### 1.3 Déclarations de paramètres manquantes

Vérifier que **chaque** `$P{...}` et `$P!{...}` utilisé dans la `<queryString>` a un `<parameter>` correspondant déclaré en haut du JRXML :

```xml
<parameter name="ADE6_Liste_des_UFR" isForPrompting="false" class="java.lang.String">
    <defaultValueExpression><![CDATA[""]]></defaultValueExpression>
</parameter>
```

OpenReport était tolérant sur les paramètres non déclarés. ReportServer ne l'est pas.

### 1.4 Vérification rapide

```bash
# Lister tous les paramètres utilisés dans la queryString
grep -oP '\$P!?\{[^}]+\}' rapport.jrxml | sort -u

# Lister tous les paramètres déclarés
grep -oP 'parameter name="[^"]+"' rapport.jrxml | sort -u

# Comparer les deux listes
```

---

## Étape 2 : Création des fonctions Oracle (si cascade)

Si le rapport a des paramètres en cascade (la valeur d'un paramètre dépend d'un autre), il faut créer des fonctions Oracle de service.

### Pourquoi

ReportServer ne sait pas résoudre les cascades de manière fiable à l'exécution (voir [01-pourquoi-ca-casse.md](01-pourquoi-ca-casse.md)). La logique de filtrage doit être déportée dans des fonctions Oracle qui acceptent des paramètres scalaires.

### Structure type

```sql
CREATE OR REPLACE FUNCTION ADESTATS.FN_GET_MA_LISTE(
    p_annee IN NUMBER,
    p_filtre IN VARCHAR2
) RETURN TYP_LOV_TAB PIPELINED IS
    -- Types prérequis : TYP_LOV_ROW(VALUE, LABEL) et TYP_LOV_TAB
BEGIN
    IF p_filtre IS NULL THEN RETURN; END IF;  -- Guard
    -- ... logique métier ...
    PIPE ROW(TYP_LOV_ROW(v_value, v_label));
    RETURN;
END;
```

Voir le dossier `sql/` pour les exemples complets.

---

## Étape 3 : Configuration dans ReportServer

### 3.1 Créer le rapport Jasper

1. Clic droit sur le dossier → **Insérer** → **Rapport Jasper**
2. Uploader le `.jrxml` corrigé
3. Sélectionner la **Datasource**

### 3.2 Créer les paramètres

Pour chaque paramètre de type liste (Datasource), la requête SQL doit respecter le **pattern UNION ALL** :

```sql
SELECT CAST(NULL AS VARCHAR2(255)) AS value,
       CAST(NULL AS VARCHAR2(255)) AS label
FROM DUAL WHERE 1=0
UNION ALL
SELECT t.value, t.label
FROM TABLE(ADESTATS.FN_GET_MA_LISTE(...)) t
```

Ce pattern est **obligatoire** pour les fonctions pipelinées. Sans lui, RS échoue en phase de préparation.

### 3.3 Syntaxe JUEL pour les variables

```sql
-- ❌ Syntaxe Jasper (ne marche pas dans les requêtes RS)
WHERE ID = $P{Annee}

-- ❌ Avec guillemets (erreur de type)
WHERE ID = '${Annee}'

-- ✅ Correct (RS gère le typage)
WHERE ID = ${Annee}

-- ✅ Avec protection null (recommandé pour les cascades)
WHERE ID = ${Annee != null ? Annee : -1}
```

### 3.4 Dépendances

Si un paramètre B utilise `${A}` dans sa requête : cocher **A** dans "Dépend de" de **B**.

---

## Étape 4 : Validation

La validation de l'interface (les listes se chargent) **ne suffit pas**. Il faut impérativement tester la génération PDF.

### Checklist

- [ ] Polices remplacées (`Serif` / `SansSerif` / `Monospaced`)
- [ ] Attributs PDF legacy supprimés
- [ ] Guillemets retirés autour des `$P!{...}`
- [ ] Tous les `$P{...}` ont un `<parameter>` déclaré
- [ ] Requêtes RS avec le pattern `UNION ALL`
- [ ] Variables JUEL protégées `${... != null ? ... : default}`
- [ ] Dépendances cochées dans RS
- [ ] **Génération PDF testée** (pas seulement l'aperçu des listes)
