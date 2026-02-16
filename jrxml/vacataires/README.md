# JRXML — Rapport Vacataires

Mêmes corrections que le rapport Permanents.

## Différences fonctionnelles

- Population filtrée sur `UPPER(PATH1) = 'VACATAIRES'`
- Types d'activités : `CM`, `TD`, `TP`, `CI`, **`PROJET`** (absent chez les permanents)
- Paramètre enseignants : `ADE6_Liste_Enseignants_Vacataires_Nommes_Annuel`
- Fonction Oracle : `FN_GET_VACATAIRES_FINAL` (à créer)
