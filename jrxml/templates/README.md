# JRXML de Test Minimal

Ce template sert à isoler les problèmes : si le rapport plante avec ce JRXML,
le problème vient de ReportServer (config paramètres, dépendances), pas du JRXML.

## Utilisation

1. Remplacer le JRXML du rapport par ce template
2. Conserver tous les paramètres RS tels quels
3. Tester l'exécution PDF
4. Si ça passe → le problème est dans le JRXML original
5. Si ça plante → le problème est dans la config RS

## Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<jasperReport xmlns="http://jasperreports.sourceforge.net/jasperreports"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://jasperreports.sourceforge.net/jasperreports
              http://jasperreports.sourceforge.net/xsd/jasperreport.xsd"
              name="test_minimal" pageWidth="595" pageHeight="842">

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

    <queryString><![CDATA[SELECT 1 AS dummy FROM DUAL]]></queryString>

    <field name="DUMMY" class="java.math.BigDecimal"/>

    <detail>
        <band height="40">
            <staticText>
                <reportElement x="10" y="10" width="400" height="20"/>
                <textElement><font fontName="SansSerif" size="12"/></textElement>
                <text><![CDATA[Test minimal OK — le moteur JasperReports fonctionne.]]></text>
            </staticText>
        </band>
    </detail>
</jasperReport>
```
