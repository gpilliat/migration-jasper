# 01 — Pourquoi ça casse : Incompatibilités OpenReport → ReportServer

Ce document explique les différences fondamentales entre OpenReport et ReportServer dans le traitement des rapports JasperReports, et pourquoi une migration "transparente" est impossible pour les rapports complexes.

## Les rapports SQL : aucun problème

Les rapports de type "SQL simple" (une requête, des paramètres scalaires, pas de JRXML) se migrent par copier-coller. ReportServer exécute la requête, affiche le résultat. Rien ne change.

## Les rapports JasperReports : tout change

Un rapport JasperReports (.jrxml) est un programme : il contient du SQL, des expressions Java, des paramètres typés, et une mise en page XML. Deux plateformes différentes l'exécutent différemment.

### Différence 1 : Deux moteurs d'expression superposés

ReportServer introduit sa propre couche d'expression **avant** JasperReports.

| Contexte | OpenReport | ReportServer |
|---|---|---|
| Requêtes des paramètres | Syntaxe Jasper `$P{...}` | Syntaxe JUEL `${...}` |
| Requête du JRXML | Syntaxe Jasper `$P{...}` / `$P!{...}` | Syntaxe Jasper `$P{...}` / `$P!{...}` |
| Évaluation | Un seul moteur, un seul pass | Deux moteurs, plusieurs passes |

Conséquence : les requêtes SQL des paramètres doivent être **réécrites** en syntaxe JUEL. Un même paramètre (`ADE6_Annee`) est référencé comme `${ADE6_Annee}` dans la config RS et comme `$P{ADE6_Annee}` dans le JRXML.

### Différence 2 : Le cycle de vie des paramètres

C'est la différence la plus impactante et la moins documentée.

**OpenReport** évalue les paramètres une seule fois, dans l'ordre de la cascade, puis injecte les valeurs dans le JRXML et exécute. Simple.

**ReportServer** a un cycle en plusieurs phases :

```
Phase 1 — Chargement de l'interface utilisateur
  Pour chaque paramètre Datasource :
    → Évaluer les ${...} via JUEL
    → Exécuter la requête SQL
    → Afficher les résultats dans la dropdown/popup
  Les dépendances ("Depends on") contrôlent l'ordre d'évaluation.
  ✅ Ça marche.

Phase 2 — Clic sur "Exécuter" / "Aperçu"
  RS construit le ParameterMap pour JasperReports.
  Pour chaque paramètre Datasource :
    → RS recalcule la valeur par défaut (getSingleDefaultValue)
    → RS ré-évalue la requête SQL via JUEL
    → Le scope JUEL ne contient PAS les valeurs sélectionnées par l'utilisateur
    → PropertyNotFoundException ❌

Phase 3 — Si Phase 2 passe, le moteur JasperReports prend le relais
  → Parse le JRXML
  → Remplace les $P{...} et $P!{...} par les valeurs
  → Exécute la requête Oracle
  → Génère le PDF
```

La Phase 2 est le point de rupture. RS ré-évalue des requêtes qui contiennent des `${...}` dans un contexte où ces variables n'existent plus. C'est un comportement interne de RS, non documenté, découvert par l'analyse des stacktraces.

### Différence 3 : Le formatage des multi-sélections

| Plateforme | Format produit pour `$P!{Liste}` |
|---|---|
| OpenReport | `val1','val2','val3` (le développeur ajoutait les guillemets dans le JRXML) |
| ReportServer | `'val1', 'val2'` (RS ajoute les guillemets automatiquement) |

Si le JRXML conserve les guillemets de l'époque OpenReport (`IN ('$P!{Liste}')`), le SQL résultant contient un double quoting → erreur Oracle ORA-00907.

### Différence 4 : La préparation des requêtes

ReportServer "prépare" les requêtes des paramètres Datasource en les wrappant :
```sql
SELECT * FROM ( <requête> ) WHERE ROWNUM < 0
```

Ce wrapper est incompatible avec les fonctions pipelinées Oracle (`TABLE(...)`), car Oracle ne peut pas inférer le type de retour sans exécuter la fonction.

### Différence 5 : Les polices

OpenReport tournait sous un environnement qui disposait des polices Windows (Times New Roman, Arial). ReportServer tourne sous Linux sans ces polices. JasperReports lève une exception fatale si une police référencée dans le JRXML n'est pas trouvée.

## Résumé : ce qui doit changer

| Composant | Changement nécessaire |
|---|---|
| JRXML — Polices | Réécriture : polices physiques → polices logiques Java |
| JRXML — Guillemets | Suppression des `'...'` autour des `$P!{...}` |
| JRXML — Paramètres | Ajout des déclarations `<parameter>` manquantes |
| SQL — Requêtes RS | Réécriture en syntaxe JUEL + pattern UNION ALL |
| Oracle — Logique métier | Création de fonctions PL/SQL dédiées |
| Architecture | Déport de la logique des JRXML vers Oracle |

## Pourquoi créer des fonctions Oracle

Sous OpenReport, le JRXML contenait directement les requêtes SQL complexes avec des `$P{...}` résolus en un pass. Ça marchait car tout était évalué dans le même contexte.

Sous ReportServer, cette approche ne fonctionne plus car :
1. Les `${...}` des paramètres RS sont évalués dans un contexte JUEL distinct
2. Le scope JUEL est vide lors de la ré-évaluation à l'exécution
3. Les types Java (Collection, Date, String) ne correspondent pas toujours aux types Oracle attendus

La solution : **encapsuler la logique SQL dans des fonctions Oracle** qui n'acceptent que des paramètres scalaires simples (NUMBER, VARCHAR2). ReportServer passe les scalaires, Oracle gère la complexité.

```
Avant (OpenReport) :
  JRXML contient un SELECT de 50 lignes avec 6 $P{...} et 3 $P!{...}
  → OR résout tout → Oracle exécute

Après (ReportServer) :
  RS passe 4 scalaires à une fonction Oracle
  La fonction gère le SQL dynamique (schéma, filtres, jointures)
  Le JRXML reste simple
```

C'est un changement d'architecture, pas un simple portage.
