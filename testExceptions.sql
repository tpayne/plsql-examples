--
-- PL/SQL example for showing simple EXCEPTIONs
-- Any value that is not a number or lower than 20 will fire an exception

SET TERMOUT ON
SET SERVEROUTPUT ON SIZE 1000000;

-- Create a function to test if input is a number
--
CREATE OR REPLACE FUNCTION isNumber(
    iv_number IN VARCHAR2)
RETURN boolean IS
  numTst number:= 0;
BEGIN
   SELECT TO_NUMBER(iv_number)
   INTO   numTst
   FROM   DUAL;
   return TRUE;
   EXCEPTION
     WHEN others THEN
        RETURN FALSE;
END;
/

DECLARE
  tValue VARCHAR2(10):='&input'; 
  notNumber EXCEPTION;
  tooLow EXCEPTION;
BEGIN
  IF NOT isNumber(tValue) THEN
     RAISE notNumber;
  ELSE
     IF tValue < 20 THEN
        RAISE tooLow;
     ELSE 
        DBMS_OUTPUT.PUT_LINE('Value is '||tValue);
     END IF;
  END IF;
  
  EXCEPTION
     WHEN notNumber THEN
         DBMS_OUTPUT.PUT_LINE('Input value is not a number');
     WHEN tooLow THEN
         DBMS_OUTPUT.PUT_LINE('Input value is too low');
     WHEN others THEN
         DBMS_OUTPUT.PUT_LINE('Unknown exception occurred');
END;
/