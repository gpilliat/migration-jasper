-- =============================================================================
-- Types Oracle pour les fonctions pipelinées (List of Values)
-- Ces types sont le contrat d'interface entre ReportServer et Oracle.
-- ReportServer attend deux colonnes : VALUE et LABEL.
--
-- Schéma : ADESTATS
-- =============================================================================

CREATE OR REPLACE TYPE ADESTATS.TYP_LOV_ROW AS OBJECT (
    VALUE   VARCHAR2(255),
    LABEL   VARCHAR2(255)
);
/

CREATE OR REPLACE TYPE ADESTATS.TYP_LOV_TAB AS TABLE OF ADESTATS.TYP_LOV_ROW;
/
