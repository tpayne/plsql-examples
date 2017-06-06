--
-- PL/SQL example to show how to query tables based on user input
-- and how to fire exceptions
--
-- Requires a TEST table to be created and populated with some data
--  TEST_UID NUMBER
--  TEST_NAME VARCHAR2

BEGIN
  DECLARE
    tUid     test.test_uid%TYPE := &uid; -- Using %TYPE to slave the value type to the table - no.
    testName test.test_name%TYPE; -- Using %TYPE to slave the value type to the table - varchar2.
  BEGIN
    DECLARE
       tUid1    number := 10;
    BEGIN
       SELECT test_name
       INTO   testName
       FROM   test
       WHERE  test_uid = tUid1;
       DBMS_OUTPUT.PUT_LINE('First test is ' || testName);
       EXCEPTION
          WHEN no_data_found THEN
            DBMS_OUTPUT.PUT_LINE('Test ' || tUid || ' not found');
    END;
    SELECT test_name
    INTO   testName
    FROM   test
    WHERE  test_uid = tUid;
    DBMS_OUTPUT.PUT_LINE('First test is ' || testName);
    EXCEPTION
      WHEN no_data_found THEN
        DBMS_OUTPUT.PUT_LINE('Test ' || tUid || ' not found');
  END;
END;
/
