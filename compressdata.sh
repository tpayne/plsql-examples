#!/bin/sh
#
# script to reorganize an Oracle 11g database
#
command=`basename $0`
direct=`dirname $0`
trap 'stty echo; echo "${command} aborted"; exit_error; exit' 1 2 3 15
#
CWD=`pwd`

#General
tmpdir="/tmp/"
logfile=
sys_passwd=
verbose=0
opmode=0

#
# Echo messages
#
echo_mess()
{
if [ "x${logfile}" = "x" ]; then
   echo "${command}:" $*
else
   echo "${command}:" $* >> ${logfile} 2>&1
fi
}

debug_mess()
{
if [ ${verbose} -eq 0 ]; then
   :
else
   echo_mess $*
fi
return
}

catdebug()
{
if [ ${verbose} -eq 0 ]; then
   :
else
    if [ "x${logfile}" = "x" ]; then
       cat $*
    else
       cat $* >> ${logfile} 2>&1
    fi
fi
return
}
#
# Exit error
#
exit_error()
{
exit 1
}

#
# Usage
#
usage()
{
#
while [ $# -ne 0 ] ; do
        case $1 in
             -l) logfile=$2
                 shift 2;;
             -p) sys_passwd=$2
                 shift 2;;
             -mode) if [ "x$2" = "xindex" ]; then
                       opmode=1
                    elif [ "x$2" = "xtable" ]; then
                       opmode=2
                    elif [ "x$2" = "xarchive" ]; then
                       opmode=3
                    fi
                    shift 2;;
             --debug) set -xv ; shift;;
             -v) verbose=1
                 shift;;
             -?*) show_usage ; break;;
             --) shift ; break;;
             -|*) break;;
        esac
done

if [ "x${sys_passwd}" = "x" ]; then
   show_usage;
fi

return 0
}


show_usage()
{
echo "Usage: ${direct}/${command} -p <system_passwd>"
echo "          [-l <logile>]"
exit 1
}

####################
# Common utilities
####################
#
#Check directory
#
check_dir()
{
debug_mess "Checking $1 exists..."
if [ ! -d "$1" ]; then
   return 1
else
   return 0
fi
}
#
# Create dirs
#
crdir()
{
if [ ! -d "$1" ]; then
   mkdir "$1"
fi
}
#
# Who am I?
# What do I want?
#
check_iam_root()
{
tmpfile="${tmpdir}/mig$$.log"
remove_file ${tmpfile}
change=/bin/chown
if [ ! -f ${change} ] ; then
        change=/etc/chown
        if [ ! -f ${change} ] ; then
                change=/usr/bin/chown
                if [ ! -f ${change} ] ; then
                        echo_mess "chown not found"
                        echo_mess "Please ensure that this command is in the"
                        echo_mess "search path."
            exit_error
                fi
        fi
fi
echo > ${tmpfile}
${change} root ${tmpfile} 2>/dev/null
if [ $? -ne 0 ] ; then
    remove_file ${tmpfile}
    return 1
fi
${change} bin ${tmpfile} 2>/dev/null
if [ $? -ne 0 ] ; then
    remove_file ${tmpfile}
    return 1
fi
remove_file ${tmpfile}
return 0
}
#
# Who do I serve?
#
check_owner()
{
tmpfile="${tmpdir}/mig$$.log"
remove_file ${tmpfile}
change=/bin/chown
if [ ! -f ${change} ] ; then
        change=/etc/chown
        if [ ! -f ${change} ] ; then
                change=/usr/bin/chown
                if [ ! -f ${change} ] ; then
                        echo_mess "chown not found"
                        echo_mess "Please ensure that this command is in the"
                        echo_mess "search path."
                        exit_error
                fi
        fi
fi
echo > ${tmpfile}
${change} $1 ${tmpfile} 2>/dev/null
if [ $? -ne 0 ] ; then
        remove_file ${tmpfile}
        return 1
fi
remove_file ${tmpfile}
return 0
}
#
# Blat files
#
remove_file()
{
if [ -f "$1" ]; then
   rm -fr "$1" > /dev/null 2>&1
fi
}

remove_dir()
{
if [ -d "$1" ]; then
   rm -fr "$1" > /dev/null 2>&1
fi
}

#
# Get Machine & OS levels
#
get_machine()
{
(uname -m) > /dev/null 2>&1
if [ $? -ne 0 ]; then
        echo_mess "command uname not found"
        echo_mess "Please ensure that this command is in the search path"
        echo_mess "then restart the installation"
        exit 1
fi
machine_os="`uname -m`"
case "$machine_os" in
        sun4*)
                machine_os="`uname -s`""`uname -r`"
                break;;
        *i386* | *i486*)
                # Need more info
                machine_os="`uname -a`"
                break;;
        *9000*)
                machine_os="`uname -s`""`uname -r`"
                break;;
        *i686*)
                machine_os="`uname -o`"
                if [ "x${machine_os}" = "xCygwin" ]; then
                    :
                else
                    machine_os="`uname -m`"
                fi
                break;;

esac
return 0
}

####################
# Oracle interfaces
####################
#
# Check Oracle installation
#
check_oracle()
{
debug_mess "Checking $1 is an oracle installation..."
if [ ! -f "$1/bin/sqlplus" -o ! -f "$1/bin/oracle" ];
then
   return 1
else
   return 0
fi
}
#
# Check Oracle is running
#
check_running()
{
debug_mess "Checking if Oracle is running..."
sqlplus -s system/${sys_passwd} << EOF \
    | grep -i 'ORACLE not available' >/dev/null 2>&1
exit;
EOF
if [ $? -gt 0 ]; then
    return 0
else
    return 1
fi
}
#
#Test database connect
#
sqlconnect()
{
debug_mess "Checking if I can connect to $1..."
sqlplus -s $1 << EOF \
        | grep -i 'error' >/dev/null 2>&1
exit;
EOF

if [ $? -gt 0 ]; then
        :
else
        echo_mess "Unable to connect to ORACLE for $1"
        if [ "x$2" = "xfatal" ]; then
           exit 1
        else
           return 1
        fi
fi
}
#
# Change the password
#
change_passwd()
{
debug_mess "Changing the password for $1..."
sqlplus -s $1 << EOF > /dev/null 2>&1
alter user $2 identified by $2;
EOF
}
#
# Startup Oracle
#
startup_oracle()
{
debug_mess "Trying to kickstart Oracle in $1 mode..."
tmpfile="${tmpdir}/mig$$.log"
remove_file ${tmpfile}
sqlplus / as sysdba << EOSQL \
    > ${tmpfile} 2>&1
startup $1
exit
EOSQL

grep -i 'ORACLE instance started' ${tmpfile} > /dev/null 2>&1
if [ $? -gt 0 ]; then
   # Failed
   debug_mess "...and failed."
   catdebug ${tmpfile}
   remove_file ${tmpfile}
   return 1
else
   debug_mess "...and worked."
   remove_file ${tmpfile}
   return 0
fi
}
#
# Shutdown Oracle
#
shutdown_oracle()
{
debug_mess "Trying to shutdown Oracle in $1 mode..."
tmpfile="${tmpdir}/mig$$.log"
remove_file ${tmpfile}
sqlplus / as sysdba << EOSQL \
    > ${tmpfile} 2>&1
shutdown $1
exit
EOSQL

grep -i 'ORACLE instance shut down' ${tmpfile} > /dev/null 2>&1
if [ $? -gt 0 ]; then
   # Failed
   debug_mess "...and failed."
   if [ "x$2" = "x" ]; then
    catdebug ${tmpfile}
   fi
   remove_file ${tmpfile}
   return 1
else
   debug_mess "...and worked."
   remove_file ${tmpfile}
   return 0
fi
}

#
# Place into/out of archive log mode
#
archivelogmode()
{
tmpfile="${tmpdir}/mig$$.log"
archivemode=0
remove_file ${tmpfile}
debug_mess "Switching archive log mode to $1..."
if [ "x${1}" = "xdisable" ]; then
archivemode=1
sqlplus -s / as sysdba << EOF \
        > ${tmpfile} 2>&1
shutdown immediate
startup mount
alter database flashback off;
alter database noarchivelog;
alter database open;
archive log list;
exit;
EOF
elif [ "x${1}" = "xenable" ]; then
archivemode=2
sqlplus -s / as sysdba << EOF \
        > ${tmpfile} 2>&1
shutdown immediate
startup mount
alter database archivelog;
alter database flashback on;
alter database open;
archive log list;
exit;
EOF
else
    return 2;
fi

#grep -i 'error' ${tmpfile} >/dev/null 2>&1
#if [ $? -eq 0 ]; then
#    catdebug ${tmpfile}
#    remove_file ${tmpfile}
#    return 2
#fi

# Test archive mode...
sqlplus -s / as sysdba << EOF \
        > ${tmpfile} 2>&1
archive log list;
EOF

catdebug ${tmpfile}

if [ ${archivemode} -eq 1 ]; then
    grep -i 'No Archive Mode' ${tmpfile} >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        remove_file ${tmpfile}
        return 1
    fi
else
    grep -i 'No Archive Mode' ${tmpfile} >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        remove_file ${tmpfile}
        return 1
    fi
fi

remove_file ${tmpfile}
return 0
}

#
# Rebuild indexes...
#
rebuild_indexes()
{
tmpfile="${tmpdir}/mig$$.log"
remove_file ${tmpfile}
debug_mess "Rebuild indexes..."
debug_mess "- logfile is ${tmpfile}..."
sqlplus -s system/${sys_passwd} << EOF \
        | grep 'ALTER INDEX' | uniq | sqlplus -s system/${sys_passwd} \
    > ${tmpfile} 2>&1
set heading off
set echo off
set verify off
set lines 99
SELECT 'ALTER INDEX "'
    ||uc.owner||'"."'||uc.object_name||'" '||
    'REBUILD;'
FROM   sys.dba_objects uc
WHERE  (uc.object_type = 'INDEX')
AND    ((uc.owner = 'PCMS_SYS') OR
        (EXISTS (SELECT NULL FROM sys.dba_tables db1
                 WHERE  db1.table_name = 'ITEM_SPEC_CATALOGUE'
                 AND    uc.owner = db1.owner)))
ORDER BY 1 DESC
/
exit;
EOF

cat ${tmpfile} | grep -v 'ORA-14456:' | grep -i 'ORA-' >/dev/null 2>&1
if [ $? -eq 0 ]; then
    catdebug ${tmpfile}
    remove_file ${tmpfile}
    return 1
fi
catdebug ${tmpfile}
remove_file ${tmpfile}
return 0
}

#
# Coalesce tablespaces...
#
coalesce_tablespaces()
{
tmpfile="${tmpdir}/mig$$.log"
remove_file ${tmpfile}
debug_mess "Coalesce tablespaces..."
debug_mess "- logfile is ${tmpfile}..."
sqlplus -s system/${sys_passwd} << EOF \
        | grep 'ALTER TABLESPACE' | uniq | sqlplus -s system/${sys_passwd} \
    > ${tmpfile} 2>&1
set heading off
set echo off
set verify off
set lines 99
SELECT 'ALTER TABLESPACE "'
    ||uc.tablespace_name||'" '||
    'COALESCE;'
FROM   sys.dba_tablespaces uc
WHERE  uc.status = 'ONLINE'
AND    (uc.contents != 'TEMPORARY' AND uc.contents != 'UNDO')
ORDER BY 1 DESC
/
exit;
EOF

grep -i 'error' ${tmpfile} >/dev/null 2>&1
if [ $? -eq 0 ]; then
    catdebug ${tmpfile}
    remove_file ${tmpfile}
    return 1
fi
catdebug ${tmpfile}
remove_file ${tmpfile}
return 0
}

#
# Compress tables...
#
compress_tables()
{
tmpfile="${tmpdir}/mig$$.log"
remove_file ${tmpfile}
debug_mess "Rebuild tables..."
debug_mess "- logfile is ${tmpfile}..."
sqlplus -s system/${sys_passwd} << EOF \
        | grep 'ALTER TABLE' | uniq | sqlplus -s system/${sys_passwd} \
    > ${tmpfile} 2>&1
set heading off
set echo off
set verify off
set lines 999
column nl fold_after
SELECT 'ALTER TABLE "'
    ||uc.owner||'"."'||uc.object_name||'" '||
    'ENABLE ROW MOVEMENT;' nl,
       'ALTER TABLE "'
    ||uc.owner||'"."'||uc.object_name||'" '||
    'SHRINK SPACE;' nl,
       'ALTER TABLE "'
    ||uc.owner||'"."'||uc.object_name||'" '||
    'DISABLE ROW MOVEMENT;' nl
FROM   sys.dba_objects uc
WHERE  (uc.object_type = 'TABLE')
AND    ((uc.owner = 'PCMS_SYS') OR
        (EXISTS (SELECT NULL FROM sys.dba_tables db1
                 WHERE  db1.table_name = 'ITEM_SPEC_CATALOGUE'
                 AND    uc.owner = db1.owner)))
ORDER BY 1 DESC
/
exit;
EOF

cat ${tmpfile} | grep -v 'ORA-10637' | \
    grep -v 'ORA-14451' | grep -v 'ORA-10635' | grep -i 'ORA-' >/dev/null 2>&1

if [ $? -eq 0 ]; then
    debug_mess "Compression failed"
    catdebug ${tmpfile}
    remove_file ${tmpfile}
    return 1
fi
catdebug ${tmpfile}
remove_file ${tmpfile}
return 0
}

#
# Run compression...
#
compressData()
{
echo_mess "Compressing the data in Oracle..."

# Check if oracle is up and running...
# if it is shut it down

echo_mess "- Kicking everything off so only me using..."

check_running
if [ $? -eq 0 ]; then
   shutdown_oracle immediate
   if [ $? -gt 0 ]; then
      echo_mess "Error: Unable to shutdown Oracle instance ${ORACLE_SID}"
      exit_error
   fi
fi

startup_oracle restrict
if [ $? -gt 0 ]; then
   echo_mess "Error: Unable to startup Oracle instance ${ORACLE_SID}"
   exit_error
fi

# Oracle now running in desired mode.
echo_mess " - Placing Oracle in no archive log mode..."
archivelogmode disable
if [ $? -gt 0 ]; then
   echo_mess "Error: Unable to successfully place Oracle in no archive log mode."
   shutdown_oracle immediate
   exit_error
fi

check_running

if [ $? -eq 0 ]; then
   shutdown_oracle immediate
   if [ $? -gt 0 ]; then
      echo_mess "Error: Unable to shutdown Oracle instance ${ORACLE_SID}"
      exit_error
   fi
fi

startup_oracle restrict
if [ $? -gt 0 ]; then
   echo_mess "Error: Unable to startup Oracle instance ${ORACLE_SID}"
   exit_error
fi

if [ ${opmode} -eq 0 -o ${opmode} -eq 1 ]; then
    #
    # Now to rebuild all the indexes...
    #
    echo_mess " - Rebuilding indexes... (this may take a while)"
    rebuild_indexes
    if [ $? -gt 0 ]; then
       echo_mess "Error: Index rebuild failed"
       exit_error
    fi
    echo_mess " - Rebuilding indexes done"
fi

if [ ${opmode} -eq 0 -o ${opmode} -eq 2 ]; then
    echo_mess " - Compressing tables... (this may take a while)"
    compress_tables
    if [ $? -gt 0 ]; then
       echo_mess "Error: Table compression failed"
       exit_error
    fi
    echo_mess " - Compressing tables done"
fi

echo_mess " - Coalesce tablespaces..."
coalesce_tablespaces
if [ $? -gt 0 ]; then
   echo_mess "Error: Unable to coalesce tablespaces"
   exit_error
fi

#
# Work down, now finish.
#
shutdown_oracle immediate
if [ $? -gt 0 ]; then
   echo_mess "Error: Unable to shutdown Oracle instance ${ORACLE_SID}"
   exit_error
fi

# Oracle now running in desired mode.
echo_mess " - Placing Oracle in archive log mode..."
archivelogmode enable
if [ $? -gt 0 ]; then
   echo_mess "Error: Unable to successfully place Oracle in no archive log mode."
   exit_error
fi

echo_mess " - Restarting Oracle in normal modes..."

check_running
if [ $? -eq 0 ]; then
   shutdown_oracle immediate
   if [ $? -gt 0 ]; then
      echo_mess "Error: Unable to shutdown Oracle instance ${ORACLE_SID}"
      exit_error
   fi
fi

startup_oracle
if [ $? -gt 0 ]; then
   echo_mess "Error: Unable to startup Oracle instance ${ORACLE_SID}"
   exit_error
fi

echo_mess "Data compression done."
return 0
}

# Check Oracle directories...
check_oracle_dir()
{
if [ "x${machine_os}" = "xCygwin" ]; then
    return 0
fi

##
## Check Oracle homes exist
##
check_dir ${ORACLE_HOME}
if [ $? -gt 0 ]; then
   echo_mess "Error: Directory ${ORACLE_HOME} does not exist."
   return 1
fi

##
## Check if these are Oracle homes
##
check_oracle ${ORACLE_HOME}
if [ $? -gt 0 ]; then
   echo_mess "Error: Directory ${ORACLE_HOME} is not an Oracle installation."
   return 1
fi
return 0
}
###################################
###################################
##
## Main compression
##

usage $*
get_machine

check_oracle_dir
if [ $? -gt 0 ]; then
   echo_mess "Error: Oracle environment not setup."
   exit 1
fi

check_running
if [ $? -eq 0 ]; then
    sqlconnect system/${sys_passwd}
    if [ $? -gt 0 ]; then
       # Could not connect...
       echo_mess "Error: Connect failed. Please check Oracle is running and the password is correct."
       exit 1
    fi
fi

compressData
if [ $? -gt 0 ]; then
   echo_mess "Error: Compression failed. Please check log file ${logfile}."
   exit 1
fi

echo_mess "${command}: Done `date`."

cd $CWD
exit 0
