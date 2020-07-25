#!/bin/sh

logFile=/tmp/clearRedoLogs$$.log

echo Clearing REDO logs completely...
echo Logging output to ${logFile}...

rman << EOF > ${logFile} 2>&1
connect target /
show all;
CONFIGURE ARCHIVELOG DELETION POLICY TO none;
DELETE NOPROMPT ARCHIVELOG ALL;
CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO 'SBT_TAPE';
show all;
EOF

echo Done

