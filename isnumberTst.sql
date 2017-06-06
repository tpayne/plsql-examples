--
-- Example to test simple functions and show IF/THEN/ELSE logic
--

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

--
-- Invoke the function with user input
--
DECLARE
   testVal varchar2(10) := '&uid';
BEGIN
if isNumber(testVal) then
   DBMS_OUTPUT.PUT_LINE('A number');
ELSE
   DBMS_OUTPUT.PUT_LINE('Not a number');
END IF;
END;
/

--
-- Invoke the function as a test
--
DECLARE
   testVal number:= 23;
BEGIN
   IF isNumber(testVal) then
      IF testVal < 23 THEN
         DBMS_OUTPUT.PUT_LINE('INPUT is < 23');
      ELSIF testVal > 23 THEN
         DBMS_OUTPUT.PUT_LINE('INPUT is > 23');
      ELSE
         DBMS_OUTPUT.PUT_LINE('INPUT is = 23');
      END IF;
   ELSE
      DBMS_OUTPUT.PUT_LINE('Not a number');
   END IF;
END;
/
