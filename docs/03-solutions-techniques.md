# 03 — Problèmes Rencontrés et Solutions

Journal technique détaillé de chaque problème rencontré, classé par ordre de découverte.

---

## Problème 1 : Polices manquantes

**Erreur** : `JRFontNotFoundException: Font "Times-Roman" is not available to the JVM`

**Cause** : Le serveur RS tourne sous Linux sans les polices Windows. JasperReports est fatal par défaut sur les polices manquantes.

**Solution** : Réécriture de tous les JRXML. Remplacement des polices physiques (`Times-Roman`, `Arial`, `Helvetica`) par les polices logiques Java (`Serif`, `SansSerif`, `Monospaced`). Suppression des attributs `pdfFontName`, `pdfEncoding`, `isPdfEmbedded`.

**Impact** : Chaque JRXML de 500+ lignes nécessite des dizaines de corrections manuelles.

---

## Problème 2 : Double quoting des multi-sélections

**Erreur** : `ORA-00907: parenthèse de droite absente`

**Cause** : OpenReport n'ajoutait pas de guillemets aux multi-sélections. Le développeur écrivait `IN ('$P!{Liste}')` et OR injectait `val1','val2','val3`. ReportServer ajoute automatiquement les guillemets (`'val1', 'val2'`). Le JRXML qui garde ses propres guillemets produit `IN (''val1', 'val2'')`.

**Solution** : Supprimer les guillemets dans le JRXML : `IN ($P!{Liste})`.

---

## Problème 3 : Incompatibilité fonctions pipelinées Oracle

**Erreur** : `Query could not be prepared`

**Cause** : RS wrappe les requêtes en `SELECT * FROM (...) WHERE ROWNUM < 0` pour lire les métadonnées. Oracle ne peut pas inférer le type de retour d'une fonction pipelinée (`TABLE(...)`) sans l'exécuter.

**Solution** : Préfixer avec un bloc "dummy" qui définit explicitement la structure :

```sql
SELECT CAST(NULL AS VARCHAR2(255)) AS value,
       CAST(NULL AS VARCHAR2(255)) AS label
FROM DUAL WHERE 1=0
UNION ALL
SELECT t.value, t.label FROM TABLE(MA_FONCTION(...)) t
```

---

## Problème 4 : PropertyNotFoundException au chargement

**Erreur** : `PropertyNotFoundException: Cannot find property ADE6_Annee` (au chargement de l'interface)

**Cause** : RS évalue les requêtes de tous les paramètres au chargement. Si un paramètre enfant référence `${ADE6_Annee}` et que le parent n'est pas encore évalué, JUEL ne trouve pas la variable.

**Solution** : Protéger toutes les expressions JUEL :

```sql
${ADE6_Annee != null ? ADE6_Annee : -1}
```

Et déclarer les dépendances ("Depends on") dans RS.

---

## Problème 5 : PropertyNotFoundException à l'EXÉCUTION

**Erreur** : Même que le problème 4, mais après sélection des paramètres, au clic "Aperçu" ou "Export PDF".

```
PropertyNotFoundException: Cannot find property ADE6_Annee
  at DatasourceParameterDefinition.getSingleDefaultValue
  at JasperStyleParameterParser.appendQueryChunk
```

**Cause** : RS **ré-évalue** les requêtes des paramètres Datasource au moment de l'exécution. Le scope JUEL est différent de celui du chargement — les variables des paramètres parents n'y sont plus.

La stacktrace révèle que l'erreur vient de `getSingleDefaultValue` : RS recalcule les valeurs par défaut, ce qui déclenche la ré-évaluation des requêtes.

**Analyse de l'export XML** : L'export complet du rapport RS a confirmé que même avec des requêtes en dur (sans `${...}`), la simple **déclaration d'une dépendance** ("Depends on") semble suffire à déclencher la résolution JUEL du parent.

**Ce qui a été testé sans succès** :
- Protection `!= null` sur toutes les requêtes
- JRXML de test minimal (`SELECT 1 FROM DUAL`)
- Requêtes en dur sans aucun `${...}`

**Statut** : ✅ Résolu. La suppression des dépendances fantômes et la protection systématique de toutes les expressions JUEL ont permis de débloquer l'exécution.

**Différence fondamentale avec OpenReport** :
```
OpenReport  : Évalue une fois → injecte → exécute
ReportServer : Évalue → utilisateur sélectionne → ré-évalue → injecte → exécute
```

---

## Problème 6 : Binding Oracle avec variables nommées dupliquées

**Symptôme** : Une fonction PL/SQL retourne 0 lignes alors que le SQL direct fonctionne.

**Cause** : En SQL dynamique Oracle, les named binds (`:var`) sont comptés par **occurrence**, pas par nom :

```sql
-- Oracle attend 4 binds positionnels, pas 2
v_sql := 'WHERE (:yr IS NULL OR col = :yr) AND (:ufr IS NULL OR dep = :ufr)';
OPEN v_refcur FOR v_sql USING p_yr, p_yr, p_ufr, p_ufr;
-- Si l'ordre est incorrect → résultats vides ou erronés
```

**Solution** : Supprimer les conditions `IS NULL` redondantes. Utiliser des guards en début de fonction et un seul bind par variable :

```sql
IF p_ufr IS NULL THEN RETURN; END IF;
v_sql := 'WHERE col = :yr AND dep = :ufr AND dt BETWEEN :d1 AND :d2';
OPEN v_refcur FOR v_sql USING p_yr, p_ufr, v_d1, v_d2;
```

**Diagnostic** : Résolu grâce à une table de debug (`DEBUG_LOG`) avec une procédure autonome (`PRAGMA AUTONOMOUS_TRANSACTION`) qui trace les valeurs reçues par la fonction en production.

---

## Problème 7 : Groovy inutilisable dans l'éditeur web RS

**Erreur** : `Script1.groovy: 1: Unexpected input: '&'`

**Cause** : L'éditeur web RS encode les caractères spéciaux en entités HTML (`'` → `&#39;`, `"` → `&quot;`) **avant** de stocker le script. Le compilateur Groovy reçoit du HTML.

**Solution** : Abandon total de Groovy. Toute la logique est déportée côté Oracle.

---

## Problème 8 : Passage de listes Java vers PL/SQL

**Contexte** : Sous OpenReport, la multi-sélection passait un scalaire via `$P{...}`. Sous RS, le même paramètre peut être un objet `Collection` Java.

**Solution** : Deux approches selon le contexte :

1. **Dans les requêtes RS** : fonctions Oracle qui acceptent des scalaires uniquement
2. **Dans le JRXML** : fonction utilitaire `FN_SPLIT_CSV` qui transforme une chaîne CSV en table Oracle :

```sql
-- Dans le JRXML
AND DEP IN (
    SELECT * FROM TABLE(ADESTATS.FN_SPLIT_CSV('$P!{Liste}'))
)
```

---

## Tableau récapitulatif

| # | Problème | Couche | Statut | Solution |
|---|---|---|---|---|
| 1 | Polices manquantes | JRXML | ✅ | Polices logiques Java |
| 2 | Double quoting | JRXML | ✅ | Supprimer guillemets `$P!{...}` |
| 3 | Fonctions pipelinées | RS Config | ✅ | Pattern UNION ALL |
| 4 | PropertyNotFound (chargement) | RS Config | ✅ | Protection `!= null` + dépendances |
| 5 | PropertyNotFound (exécution) | RS Engine | ✅ | Suppression dépendances fantômes + protection JUEL |
| 6 | Binding Oracle dupliqué | PL/SQL | ✅ | Simplification + guards |
| 7 | Groovy cassé | RS Editor | ✅ | Abandon → Oracle |
| 8 | Listes Java → SQL | Architecture | ✅ | Fonctions Oracle + FN_SPLIT_CSV |
