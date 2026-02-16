-- =============================================================================
-- FN_GET_TEACHERS_FINAL
-- Retourne la liste des enseignants permanents actifs sur une UFR et période.
--
-- Cette fonction a été créée spécifiquement pour la migration ReportServer.
-- Sous OpenReport, cette logique était directement dans le JRXML avec des
-- $P{...} résolus en un pass. Sous RS, il faut encapsuler dans une fonction
-- qui n'accepte que des scalaires.
--
-- ATTENTION - Binding Oracle :
--   Les named binds (:var) sont comptés par OCCURRENCE, pas par nom.
--   Ne jamais dupliquer un bind dans la requête dynamique.
--   Utiliser des guards en début de fonction plutôt que des IS NULL dans le SQL.
--
-- Schéma    : ADESTATS
-- Prérequis : TYP_LOV_TAB, TYP_LOV_ROW, UHA_ADEPROJECTS
-- Appelé par : Paramètre RS "ADE6_Liste_Enseignants_Permanents"
-- =============================================================================

CREATE OR REPLACE FUNCTION ADESTATS.FN_GET_TEACHERS_FINAL(
    p_project_id     IN NUMBER,
    p_ufr_param      IN VARCHAR2,
    p_date_debut_str IN VARCHAR2,   -- Format YYYYMMDD
    p_date_fin_str   IN VARCHAR2    -- Format YYYYMMDD
)
RETURN TYP_LOV_TAB PIPELINED
IS
    v_target_schema VARCHAR2(100);
    v_sql           VARCHAR2(32000);
    v_refcur        SYS_REFCURSOR;
    v_id            VARCHAR2(255);
    v_name          VARCHAR2(255);
    v_d_start       DATE;
    v_d_end         DATE;
BEGIN
    -- =============================
    -- Guards : retour vide propre si paramètres manquants
    -- (plutôt que IS NULL dans le SQL dynamique)
    -- =============================
    IF p_date_debut_str IS NULL OR p_date_fin_str IS NULL THEN
        RETURN;
    END IF;
    IF p_ufr_param IS NULL THEN
        RETURN;
    END IF;

    -- Conversion des dates
    BEGIN
        v_d_start := TO_DATE(p_date_debut_str, 'YYYYMMDD');
        v_d_end   := TO_DATE(p_date_fin_str, 'YYYYMMDD');
    EXCEPTION
        WHEN OTHERS THEN RETURN;
    END;

    -- Résolution du schéma dynamique via la table de mapping
    BEGIN
        SELECT "SCHEMA" INTO v_target_schema
        FROM ADESTATS.UHA_ADEPROJECTS
        WHERE PROJECTID = p_project_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN;
    END;

    -- SQL dynamique : le nom du schéma est concaténé (pas bindable)
    -- Les filtres sont bindés : un seul bind par variable
    v_sql := 'SELECT DISTINCT TO_CHAR(T1.ID), T1.NAME ' ||
             'FROM ' || v_target_schema || '.UHA_TEACHERS T1 ' ||
             'INNER JOIN ' || v_target_schema || '.UHA_TEACHERS_DEP_LIST T2 ' ||
             '  ON T1.ID = T2.TEACHER_ID ' ||
             '  AND T1.ADEPROJECTID = T2.ADEPROJECTID ' ||
             '  AND T1.PROJECTID = T2.PROJECTID ' ||
             'INNER JOIN ' || v_target_schema || '.UHA_TEACHERS_ACTIVITIES_LIST T3 ' ||
             '  ON T1.ID = T3.TEACHER_ID ' ||
             '  AND T1.ADEPROJECTID = T3.ADEPROJECTID ' ||
             '  AND T3.ACTIVITY_ID = T2.ACTIVITY_ID ' ||
             '  AND T3.EVENT_ID = T2.EVENT_ID ' ||
             '  AND T1.PROJECTID = T3.PROJECTID ' ||
             'WHERE T1.PROJECTID = :yr ' ||
             '  AND T2.DEP = :ufr ' ||
             '  AND TRUNC(T3.ACTIVITIES_DATE_TIME) BETWEEN :d1 AND :d2 ' ||
             '  AND T3.ACTIVITY_TYPE IN (''CI'', ''CM'', ''TD'', ''TP'') ' ||
             'ORDER BY 2';

    OPEN v_refcur FOR v_sql
        USING p_project_id, p_ufr_param, v_d_start, v_d_end;

    LOOP
        FETCH v_refcur INTO v_id, v_name;
        EXIT WHEN v_refcur%NOTFOUND;
        PIPE ROW(TYP_LOV_ROW(v_id, v_name));
    END LOOP;

    CLOSE v_refcur;
    RETURN;
END;
/
