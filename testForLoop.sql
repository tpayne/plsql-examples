--
-- PL/SQL example FOR LOOPs
--
SET TERMOUT ON
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  noRows NUMBER:=20; -- Counter
BEGIN
  FOR i IN 1..noRows
  LOOP
     DBMS_OUTPUT.PUT_LINE('Processed '||i||' OF '||noRows);
  END LOOP;
END;
/