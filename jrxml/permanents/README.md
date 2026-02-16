# JRXML — Rapport Permanents

Les fichiers `.jrxml` ne sont pas versionnés ici (ils sont gérés dans ReportServer). Ce dossier documente les modifications appliquées.

## Corrections par rapport à l'original OpenReport

1. **Polices** — `Times-Roman` → `Serif`, `Arial` → `SansSerif`
2. **Attributs PDF** — `pdfFontName`, `pdfEncoding`, `isPdfEmbedded` supprimés
3. **Guillemets** — Supprimés autour des `$P!{...}` dans les clauses `IN`
4. **Paramètre manquant** — `ADE6_Liste_des_UFR` ajouté dans `<parameter>`

## Paramètres déclarés dans le JRXML

```xml
<parameter name="ADE6_Schema" isForPrompting="false" class="java.lang.String"/>
<parameter name="ADE6_Annee" isForPrompting="false" class="java.lang.String"/>
<parameter name="ADE6_Liste_des_UFR" isForPrompting="false" class="java.lang.String"/>
<parameter name="ADE6_Liste_des_UFR_level_2" isForPrompting="false" class="java.lang.String">
    <defaultValueExpression><![CDATA[""]]></defaultValueExpression>
</parameter>
<parameter name="ADE6_Liste_Enseignants_Permanents" isForPrompting="false" class="java.lang.String">
    <defaultValueExpression><![CDATA[""]]></defaultValueExpression>
</parameter>
<parameter name="ADE6_Date_Debut" isForPrompting="false" class="java.util.Date">
    <defaultValueExpression><![CDATA[new java.util.Date()]]></defaultValueExpression>
</parameter>
<parameter name="ADE6_Date_Fin" isForPrompting="false" class="java.util.Date">
    <defaultValueExpression><![CDATA[new java.util.Date()]]></defaultValueExpression>
</parameter>
```
