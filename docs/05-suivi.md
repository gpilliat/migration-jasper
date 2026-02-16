# 05 — Suivi d'Avancement

## Rapports JasperReports

| Rapport | JRXML | Paramètres RS | Fonctions Oracle | Exécution PDF | Statut |
|---|---|---|---|---|---|
| Permanents | ✅ Réécrit | ✅ Cascade OK | ✅ Déployées | ✅ Validé | ✅ Fonctionnel |
| Vacataires | ✅ Réécrit | ✅ Cascade OK | ✅ Déployées | ✅ Validé | ✅ Fonctionnel |

## Composants PL/SQL

| Objet | Schéma | Statut |
|---|---|---|
| `TYP_LOV_ROW` / `TYP_LOV_TAB` | ADESTATS | ✅ Déployé et testé |
| `FN_GET_TEACHERS_FINAL` | ADESTATS | ✅ Déployé et testé |
| `FN_GET_VACATAIRES_FINAL` | ADESTATS | ✅ Déployé et testé |
| `FN_GET_UFR_BY_YEAR` | ADESTATS | ✅ Déployé et testé |
| `FN_GET_DEP_LEVEL2_BY_YEAR` | ADESTATS | ✅ Déployé et testé |
| `FN_SPLIT_CSV` | ADESTATS | ✅ Déployé et testé |
| `P_DEBUG_LOG` + `DEBUG_LOG` | ADESTATS | ✅ Déployé |

## Retour d'expérience

La migration a nécessité environ **8 problèmes techniques majeurs** à résoudre, tous documentés dans [03-solutions-techniques.md](03-solutions-techniques.md). Les plus coûteux en temps :

1. **PropertyNotFoundException à l'exécution** — le plus difficile à diagnostiquer car l'interface fonctionnait parfaitement, seule la génération PDF plantait
2. **Binding Oracle dupliqué** — résolu grâce à la table `DEBUG_LOG` qui a permis de tracer les valeurs reçues par les fonctions
3. **Réécriture des JRXML** — travail systématique mais fastidieux (polices, guillemets, paramètres manquants)
