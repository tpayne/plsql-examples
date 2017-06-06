--
-- PL/SQL example for records
--
-- Requires the TEST table to be extended with a column TEST_DESC VARCHAR2


SET TERMOUT ON
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  TYPE tRec IS RECORD(
         uid test.test_uid%TYPE,
         name test.test_name%TYPE,
         descp test.test_desc%TYPE);
  testRec   tRec;
BEGIN
  -- Select one row only into record
  SELECT test_uid,test_name,test_desc INTO testRec
  FROM   test
  WHERE  rownum = 1;

  -- Print record  
  DBMS_OUTPUT.PUT_LINE(testRec.uid||','||testRec.name);
END;
/