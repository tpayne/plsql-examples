
set lines 200
set pages 99

spool Tuning_Queries.log

prompt ****************************************************
prompt General system information
prompt

select name, value from V$PARAMETER;
select * from NLS_INSTANCE_PARAMETERS;
select * from NLS_database_PARAMETERS

prompt ****************************************************
prompt Standard instance wait events...
prompt (Time waited is micro seconds - 1/1,000,000 of a second)
prompt

select event, TOTAL_WAITS, TOTAL_TIMEOUTS, TIME_WAITED, AVERAGE_WAIT
from v$system_event
order by TIME_WAITED desc
/

col wait_class 		format a15
col event      		format a40
col total_waits     format 999,999,999
col total_timeouts  format 999,999,999
col time_waited     format 999,999,999
col average_wait    format 999,999,999

select en.wait_class, se.event, se.TOTAL_WAITS, se.TOTAL_TIMEOUTS,
	   se.TIME_WAITED, se.AVERAGE_WAIT, si.startup_time
from   v$system_event se, v$event_name en, v$instance si
where  se.event = en.name
order by TIME_WAITED desc
/

prompt ****************************************************
prompt Session level wait events...
prompt (Time waited is micro seconds - 1/1,000,000 of a second)
prompt

break on sid skip 1 dup

col sid             format 999
col username        format a40
col machine         format a15
col schemaname      format a15
col osuser          format a15
col process         format 999999
col terminal        format a10
col program         format a40 wrap
col wait_class 		format a15
col event      		format a40 wrap
col total_waits     format 999,999,999
col total_timeouts  format 999,999,999
col time_waited     format 999,999,999
col average_wait    format 999,999,999

select vs.sid,vs.USERNAME,vs.machine,vs.schemaname,vs.osuser,vs.process,vs.terminal,vs.program,
       en.wait_class, iv.event, iv.TOTAL_WAITS, iv.TOTAL_TIMEOUTS,
	   iv.TIME_WAITED, iv.AVERAGE_WAIT, to_char(si.startup_time,'DD-MON-YYYY HH24:MI:SS')
from   v$session_event iv, v$event_name en, v$instance si,
       v$session vs
where  vs.sid = iv.sid + 1
and    iv.event = en.name
order by TIME_WAITED desc
/

prompt ****************************************************
prompt May want to also consider analysing V$SESSION_WAIT_HISTORY
prompt

select vs.sid,vs.USERNAME,vs.machine,vs.schemaname,vs.osuser,vs.process,vs.terminal,vs.program,
       swh.*
from   v$session vs, V$SESSION_WAIT_HISTORY swh
where  vs.sid = swh.sid + 1
/

prompt ****************************************************
prompt May also want to consider the use of V$EVENT_HISTOGRAM
prompt

select * from V$EVENT_HISTOGRAM
order by wait_count desc
/

prompt ****************************************************
prompt
prompt Select the heaviest queries
prompt

select sql_text, cpu_time
from sys.V_$SQLAREA
where cpu_time > 10000
order by 2 desc
/

spool off

prompt ****************************************************
prompt Done
prompt ****************************************************
