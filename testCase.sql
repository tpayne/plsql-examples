--
-- PL/SQL example for using CASE & CURSOR statements
--
-- NEEDS ACCESS TO V$VERSION view
--

SET TERMOUT ON
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  noRows NUMBER:=0; -- Counter
  CURSOR curDbVersions IS -- Get 2 values from a view 
      SELECT TRIM(substr(banner,0,instr(banner,' '))) AS product,
             banner
      FROM v$version;
  rVersion curDbVersions%ROWTYPE;
BEGIN
  OPEN curDbVersions; -- Open the cursor
  LOOP
    FETCH curDbVersions INTO rVersion; -- Get the data
    EXIT WHEN curDbVersions%NOTFOUND;  -- Test if empty
    noRows := noRows + 1; -- Increment counter
    --
    -- Local variable...
    --
    DECLARE 
       strTemp VARCHAR2(100) := substr(rVersion.banner,length(rVersion.product)+1);
    BEGIN
       CASE rVersion.product -- Test the banner we case as "product"
          WHEN 'Oracle' THEN
             DBMS_OUTPUT.PUT_LINE('== Oracle RDBMS is '||strTemp);
          WHEN 'PL/SQL' THEN
             DBMS_OUTPUT.PUT_LINE('== PLSQL language version is '||strTemp);
          WHEN 'TNS' THEN
             DBMS_OUTPUT.PUT_LINE('== Network version is '||strTemp);
          WHEN 'NLSRTL' THEN
             DBMS_OUTPUT.PUT_LINE('== NLSRTL version is '||strTemp);
          ELSE
             DBMS_OUTPUT.PUT_LINE('== '||rVersion.banner);
       END CASE;
    END;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE(curDbVersions%ROWCOUNT|| ' rows found, '||noRows||' rows processed');
  CLOSE curDbVersions; -- Close the cursor  
END;
/