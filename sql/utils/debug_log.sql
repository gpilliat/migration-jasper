-- =============================================================================
-- Utilitaires de debug
--
-- Les fonctions PIPELINED ne supportent pas PRAGMA AUTONOMOUS_TRANSACTION.
-- On utilise donc une procédure séparée pour logger depuis n'importe quel
-- contexte PL/SQL.
--
-- C'est grâce à cet outil que le problème de binding Oracle dupliqué
-- (Problème 6) a été identifié : les valeurs reçues par la fonction
-- étaient tracées et comparées aux valeurs attendues.
--
-- Usage :
--   ADESTATS.P_DEBUG_LOG('yr=['||p_yr||'] ufr=['||p_ufr||']');
--
-- Consultation :
--   SELECT * FROM ADESTATS.DEBUG_LOG ORDER BY ts DESC FETCH FIRST 20 ROWS ONLY;
--
-- Schéma : ADESTATS
-- =============================================================================

CREATE TABLE ADESTATS.DEBUG_LOG (
    ts  TIMESTAMP DEFAULT SYSTIMESTAMP,
    msg VARCHAR2(4000)
);

CREATE OR REPLACE PROCEDURE ADESTATS.P_DEBUG_LOG(p_msg VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO ADESTATS.DEBUG_LOG(msg) VALUES(p_msg);
    COMMIT;
END;
/
