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
