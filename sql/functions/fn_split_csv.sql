-- =============================================================================
-- FN_SPLIT_CSV
-- Transforme une chaîne CSV en table Oracle.
--
-- Créée pour gérer le passage des multi-sélections ReportServer vers
-- des clauses IN dans le JRXML. RS formate les collections en CSV,
-- cette fonction les re-transforme en lignes Oracle.
--
-- Usage dans un JRXML :
--   AND DEP IN (SELECT * FROM TABLE(ADESTATS.FN_SPLIT_CSV('$P!{MaListe}')))
--
-- Schéma : ADESTATS
-- =============================================================================

CREATE OR REPLACE FUNCTION ADESTATS.FN_SPLIT_CSV(p_csv IN VARCHAR2)
RETURN SYS.ODCIVARCHAR2LIST PIPELINED
IS
BEGIN
    IF p_csv IS NULL THEN
        RETURN;
    END IF;

    FOR i IN 1 .. REGEXP_COUNT(p_csv, '[^,]+') LOOP
        PIPE ROW(TRIM(REGEXP_SUBSTR(p_csv, '[^,]+', 1, i)));
    END LOOP;

    RETURN;
END;
/
