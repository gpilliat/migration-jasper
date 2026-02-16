# 04 — Configuration des Paramètres ReportServer

## Cascade du rapport Permanents

```
ADE6_Annee                          ← Racine (PROJECTID)
├─→ ADE6_Schema                     ← Caché (nom du schéma Oracle)
├─→ ADE6_Liste_des_UFR              ← Composante (niveau 1)
│   └─→ ADE6_Liste_des_UFR_level_2  ← Département (niveau 2, multi)
├─→ ADE6_Date_Debut                 ← Période
├─→ ADE6_Date_Fin                   ← Période
└─→ ADE6_Liste_Enseignants_Permanents ← Multi-sélection (dépend de tout)
```

## Paramètres détaillés

### ADE6_Annee
| Propriété | Valeur |
|---|---|
| Type | Datasource, Single, Dropdown |
| Obligatoire | Oui |
| Dépend de | — |
| Valeur par défaut | `7` (label: "ADE 2025-2026") |
| Return type | String |

```sql
SELECT DISTINCT PROJECTID, PROJECTNAME_2 AS "enseignement"
FROM ADESTATS.UHA_ADEPROJECTS
WHERE PROJECTID <= 7
ORDER BY 1 DESC
```

### ADE6_Schema
| Propriété | Valeur |
|---|---|
| Type | Datasource, Single, Dropdown |
| **Caché** | **Oui** |
| Obligatoire | Oui |
| Dépend de | ADE6_Annee |
| Return type | String |

```sql
-- Version dynamique
SELECT "SCHEMA"
FROM ADESTATS.UHA_ADEPROJECTS
WHERE PROJECTID = ${ADE6_Annee != null ? ADE6_Annee : -1}
```

### ADE6_Date_Debut / ADE6_Date_Fin
| Propriété | Valeur |
|---|---|
| Type | DateTime, mode Date |
| Obligatoire | Oui |
| Dépend de | — |
| Valeur par défaut | Date du jour |

### ADE6_Liste_des_UFR
| Propriété | Valeur |
|---|---|
| Type | Datasource, Single, Dropdown |
| Obligatoire | Oui |
| Dépend de | ADE6_Annee |
| Return type | String |

```sql
SELECT * FROM TABLE(ADESTATS.FN_GET_UFR_BY_YEAR(
    ${ADE6_Annee != null ? ADE6_Annee : -1}
))
```

### ADE6_Liste_des_UFR_level_2
| Propriété | Valeur |
|---|---|
| Type | Datasource, **Multi**, Popup |
| Obligatoire | Oui |
| Dépend de | ADE6_Annee, ADE6_Liste_des_UFR |
| Return type | String |

```sql
SELECT * FROM TABLE(ADESTATS.FN_GET_DEP_LEVEL2_BY_YEAR(
    ${ADE6_Annee != null ? ADE6_Annee : -1},
    ${ADE6_Liste_des_UFR != null ? ADE6_Liste_des_UFR : 'NULL'}
))
```

### ADE6_Liste_Enseignants_Permanents
| Propriété | Valeur |
|---|---|
| Type | Datasource, **Multi**, Popup |
| Obligatoire | Oui |
| Dépend de | ADE6_Annee, ADE6_Liste_des_UFR_level_2, ADE6_Date_Debut, ADE6_Date_Fin |
| Return type | String |

```sql
SELECT CAST(NULL AS VARCHAR2(255)) AS value,
       CAST(NULL AS VARCHAR2(255)) AS label
FROM DUAL WHERE 1=0
UNION ALL
SELECT t.value, t.label
FROM TABLE(ADESTATS.FN_GET_TEACHERS_FINAL(
    CAST(${ADE6_Annee != null ? ADE6_Annee : -1} AS NUMBER),
    CAST(${ADE6_Liste_des_UFR != null ? ADE6_Liste_des_UFR : 'NULL'} AS VARCHAR2(4000)),
    TO_CHAR(CAST(${ADE6_Date_Debut} AS TIMESTAMP), 'YYYYMMDD'),
    TO_CHAR(CAST(${ADE6_Date_Fin} AS TIMESTAMP), 'YYYYMMDD')
)) t
```

## Rapport Vacataires — Différences

Seul le dernier paramètre change :

- **Clé** : `ADE6_Liste_Enseignants_Vacataires_Nommes_Annuel`
- **Fonction** : `FN_GET_VACATAIRES_FINAL` (filtre `UPPER(PATH1) = 'VACATAIRES'`, inclut type `PROJET`)

## Correspondance RS ↔ JRXML

| Paramètre RS | Usage dans le JRXML | Type JRXML |
|---|---|---|
| `ADE6_Annee` | `$P{ADE6_Annee}` (bind) | `java.lang.String` |
| `ADE6_Schema` | `$P!{ADE6_Schema}` (injection texte) | `java.lang.String` |
| `ADE6_Date_Debut` | `$P{ADE6_Date_Debut}` (bind) | `java.util.Date` |
| `ADE6_Date_Fin` | `$P{ADE6_Date_Fin}` (bind) | `java.util.Date` |
| `ADE6_Liste_des_UFR` | `$P{ADE6_Liste_des_UFR}` (bind) | `java.lang.String` |
| `ADE6_Liste_des_UFR_level_2` | `$P!{...}` (injection texte) | `java.lang.String` |
| `ADE6_Liste_Enseignants_Permanents` | `$P!{...}` (injection texte) | `java.lang.String` |
