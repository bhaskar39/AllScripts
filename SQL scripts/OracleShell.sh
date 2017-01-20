#! /bin/bash

cat > check.sql <<EOF
set termout off;
set pages 1000;
set feedback OFF;

SET MARKUP HTML ON SPOOL ON ENTMAP OFF -
HEAD "<TITLE>Oracle Database Information report</TITLE> -
<STYLE type='text/css'> -
<!-- body {font:10pt Tahoma,Arial,Helvetica,sans-serif; color:black; background:White;} --> - 
<!-- p {font:10pt Tahoma,Arial,Helvetica,sans-serif; color:black; background:White;} --> -
<!-- table {border-style:solid;border-width=0;} --> -
<!-- tr,td {border-style:solid; font:10pt Tahoma,Arial,Helvetica,sans-serif; color:Black; background:#f7f7e7; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px;} --> -
<!-- th {font:bold 10pt Tahoma,Arial,Helvetica,sans-serif; color:#336699; background:#cccc99; padding:0px 0px 0px 0px;} --> -
<!-- h1 {font:16pt Tahoma,Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;} --> -
<!-- h2 {font:bold 10pt Tahoma,Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:4pt; margin-bottom:0pt;} --> -
<!-- a {font:9pt Tahoma,Arial,Helvetica,sans-serif; color:#663300; background:#ffffff; margin-top:0pt; margin-bottom:0pt; vertical-align:top;} --> -
<!-- p.descHeader {font:14pt Tahoma,Arial,Helvetica,sans-serif; color:#0000ff; background:#ffffff; margin-top:0pt; margin-bottom:0pt; vertical-align:top;} --> -
</STYLE>" -
TABLE "WIDTH='90%' BORDER='1' ALIGN='center'"

column spoolfile new_value xspoolfile;
/* select 'dbinfo_'||instance_name||'-'||lower(HOST_NAME)||'.'||lower(to_char(sysdate,'DDMMYYYYHH24MI'))||'.htm' spoolfile from v$instance; */
select 'dbinfo_'||instance_name||'-'||lower(HOST_NAME)||'.latest.htm' spoolfile from v$instance;

spool &xspoolfile;

set head off;
select '<H1 align=center class=descHeader>'||upper(instance_name)||' running on '||upper(host_name)||' (as on '||to_char(sysdate,'DD-MM-YYYY HH24:MI')||')</H1>' from v$instance;
set head on;

PROMPT 	<table WIDTH='90%' BORDER='1' ALIGN='center'> -
	<tr><th align="left">CONTENTS</th>	</tr> -
	<tr><td><a href="#QI">Database Quick information</a></td></tr> -
	<tr><td><a href="#II">Instance Information</a></td>	</tr> -
	<tr><td><a href="#TS">Tablespace Information</a></td>	</tr> -
	<tr><td><a href="#DF">Datafiles and Tempfile Details</a></td> </tr> -
	<tr><td><a href="#OL">Online Logfile Details</a></td>		    </tr> -
	<tr><td><a href="#CF">Control File Information</a></td>		</tr> -
	<tr><td><a href="#OB">Database Objects Information</a></td> </tr> -
	  <tr><td><a href="#AVII"> Installed Products</a></td></tr>-
	<tr><td><a href="#SQ">Long Running SQl Information</a></td></tr> -
	  <tr><td><a href="#AVIII">  Datafile Statistics</a></td></tr>-
	<tr><td><a href="#DSIN">  Disk Statistics</a></td></tr>-
	</table>

PROMPT <a id="#QI" name="QI"></a><p class="descHeader">Database Quick Information:</p>

select * from (
	(select 1 SR#, 'Database Name' "Parameter",  to_char(NAME) "Value" from V$DATABASE) UNION
	(select 2 SR#, 'Server Name' "Parameter", machine from v$session where program like '%PMON%' and rownum < 2) UNION
	(select 3 SR#, 'Database Role' "Parameter",  to_char(DATABASE_ROLE) "Value" from V$DATABASE) UNION
	(select 4 SR#, 'Database Version' "Parameter",  to_char(min(VERSION)) "Value" from PRODUCT_COMPONENT_VERSION) UNION
	(select 5 SR#, 'Version Updated on' "Parameter",  to_char(VERSION_TIME) "Value" from V$DATABASE) UNION 
	(select 7 SR#, 'DB Open Mode' "Parameter",  to_char(OPEN_MODE) "Value" from V$DATABASE) UNION    
	(select 8 SR#, 'Archivelog Mode' "Parameter",  to_char(LOG_MODE) "Value" from V$DATABASE) UNION
	(select 9 SR#, 'Protection Mode' "Parameter",  to_char(PROTECTION_MODE) "Value" from V$DATABASE) UNION                
	(select 10 SR#, 'Protection Level' "Parameter",  to_char(PROTECTION_LEVEL) "Value" from V$DATABASE) UNION               
	(select 11 SR#, 'Remote Archiving' "Parameter",  to_char(REMOTE_ARCHIVE) "Value" from V$DATABASE) UNION                 
	(select 13 SR#, 'Total Database Size (MB)' "Parameter",  to_char(sum(bytes/(1024*1024)),'999999999.00') "Value" from dba_data_files)         
);

PROMPT <a id="#II" name="II"></a><p class="descHeader">Instance Information:</p>
	select 1 SR#, 
		'Instance Name' "Paramater", INSTANCE_NAME "Value" from v$instance
	UNION
	select 2 SR#, 
		'Running Since' "Paramater", to_char(STARTUP_TIME,'DD-MM-YYYY HH24:MI')||' ('||to_char(sysdate-startup_time,'990.0')||' Days)' "Value" from v$instance
	UNION
	select 3 SR#, 
		'Buffer Cache Hit' "Parameter",
  		to_char((1 - ( PHY.VALUE - LOB.VALUE - DIR.VALUE ) / SES.VALUE)*100,'900.99')||'%' "Value"
	  from V$SYSSTAT SES, V$SYSSTAT LOB, V$SYSSTAT DIR, V$SYSSTAT PHY
	 where SES.NAME = 'session logical reads'
 	   and LOB.NAME = 'physical reads direct (lob)'
	   and PHY.NAME = 'physical reads'
	   and DIR.NAME = 'physical reads direct'
	UNION
	select 4 SR#,
		'Library Cache Hit' "Parameter",
		to_char(sum(PINS - RELOADS) * 100 / sum (PINS),'900.99')||'%' "Value"
	from V$LIBRARYCACHE
	UNION
	select 5 SR#,
		'Dictionary Cache Hit' "Parameter",
		to_char( sum(GETS - GETMISSES)*100/sum(GETS),'900.99')||'%' "Value"
	from V$ROWCACHE
	UNION
	select 6 SR#,
		'In-Memory sort Hit' "Parameter",
		to_char(100*sum(A.VALUE - B.VALUE)/sum(A.VALUE),'900.99')||'%' "Value"
	from V$SYSSTAT A, V$SYSSTAT B
	where A.NAME = 'sorts (memory)'
 	  and B.NAME = 'sorts (disk)'
;



PROMPT 	<a id="TS" name="TS"></a><p class="descHeader">Tablespace Details:</p>
select  rownum    SR#,
 	dba_tablespaces.tablespace_name  Name,
 	initial_extent  IE,
 	next_extent  NE,
 	pct_increase  "PCT%",
 	min_extents  MinEx,
 	max_extents  MaxEx,
 	contents  Type,
 	block_size  "Block",
 	allocation_type  "Alloc",
 	bytes/(1024*1024) "Size(MB)",
 	status   "Status",
 	to_char(free_space*100/bytes,'900.00') "Free(%)"
from 	dba_tablespaces, 
	( select tablespace_name,sum(bytes) bytes from dba_data_files
     		group by tablespace_name
    	UNION
    	select tablespace_name,sum(bytes) bytes from dba_temp_files
     		group by tablespace_name
    	) dba_files,
   	(select tablespace_name, sum(bytes) free_space from dba_free_space
		group by tablespace_name ) dba_free_space
where dba_tablespaces.tablespace_name = dba_files.tablespace_name (+)
  and dba_tablespaces.tablespace_name = dba_free_space.tablespace_name (+)
 order by 1;
	

PROMPT <a id="#TS" name="DF"></a><p class="descHeader">Datafiles Information:</p>
select
 	tablespace_name  "Tablespace",
 	all_ts.file_id   "F#",
 	file_name  "Datafile Name",
	bytes/(1024*1024) "Size(MB)",
 	autoextensible  "Expand",
  	(select block_size from dba_tablespaces where tablespace_name = all_ts.tablespace_name) * increment_by / (1024 * 1024)  "Inc(MB)",
 	status   "Status",
	to_char(free_space*100/bytes,'900.00') "Free(%)"
from (select * from dba_data_files) all_ts,
	(select file_id,sum(bytes) free_space from dba_free_space
		group by file_id ) dba_free_space
where all_ts.file_id = dba_free_space.file_id
order by 1,2;

PROMPT <a id="#TS" name="DF"></a><p class="descHeader">Tempfiles Information:</p>
select
 	tablespace_name  "Tablespace",
 	all_ts.file_id   "F#",
 	file_name  "Datafile Name",
	bytes/(1024*1024) "Size(MB)",
 	autoextensible  "Expand",
  	(select block_size from dba_tablespaces where tablespace_name = all_ts.tablespace_name) * increment_by / (1024 * 1024)  "Inc(MB)",
 	status   "Status"
from (select * from dba_temp_files) all_ts
order by 1,2;

PROMPT <a id="#TS" name="OL"></a><p class="descHeader">Online Logfile Details:</p>
select v$logfile.group#,
	member	"Online log File",
 	bytes/(1024*1024) "Size(MB)",
 	archived "Archived",
 	v$log.status "Log Status",
 	v$logfile.status "Status"
from v$logfile, v$log
where v$logfile.group# = v$log.group#
 order by group#;


--PROMPT <a id="#UI" name="#UI"><p class="descHeader">Undo Performance (last 24h) : Using more than 10% of Undo Tablespace or query taking more than 5 mins :</p>

--PROMPT 	<table WIDTH='90%' BORDER='1' ALIGN='center'> -
--	<tr><th colspan=2>Legends</th></tr> -
--	<tr><td>Tx Cnt</td><td>Transactions Count</td></tr> -
--	<tr><td>Max Qry (S)</td>	<td>Maximum Query length in Seconds</td></tr> -
--	<tr><td>Max Cnr Tx</td>		<td>Maximum Concurrent Transactions</td></tr> -
--	<tr><td>Get Spc fo Tx</td>	<td>Get Space from other transactions</td></tr> -
--	<tr><td>USTCNT</td>		<td>Number of attempts to obtain undo space bt stealing unexpired extents from other transactions</td></tr> -
--	<tr><td>UBLC</td>		<td>Number of unexpired blocks removed from undo segments</td></tr> -
--	<tr><td>UBUC</td>		<td>Number of unexpired blocks used by transactions</td></tr> -
--	<tr><td>ESCC</td>		<td>Number of attempts to steal expired undo blocks from other undo segments</td></tr> -
--	<tr><td>EBLC</td>		<td>Number of expired undo blocks stolen from other undo segments</td></tr> -
--	<tr><td>EBUC</td>		<td>Number of expired undo blocks reused within the same undo segment</td></tr> -
--	<tr><td>SSC</td>		<td>Number of times the error ORA-01555 occured</td></tr> -
--	<tr><td>NSP</td>		<td>Number of times the space was requested but no free space was available in undo tablespace</td></tr> -
--	</table>
--select 
--	to_char(BEGIN_TIME,'DD HH24:MI') "START",    
--	to_char(END_TIME,'DD HH24:MI') "END",
--	NAME		"TS Name",
--	UNDOBLKS	"Undo Blks",
--	TXNCOUNT	"TX Cnt",
--	MAXQUERYLEN	"Max Qry (S)",
--	MAXCONCURRENCY	"Max Cnr Tx",
--	UNXPSTEALCNT	"USTCNT",
--	UNXPBLKRELCNT	"UBLC",
--	UNXPBLKREUCNT	"UBUC",
--	EXPSTEALCNT	"ESCC",
--	EXPBLKRELCNT	"EBLC",
--	EXPBLKREUCNT	"EBUC",
--	SSOLDERRCNT	"SSC",
--	NOSPACEERRCNT	"NSP"
--from v$undostat, v$tablespace
--where v$undostat.undotsn = v$tablespace.ts#
--and begin_time > (sysdate - 1)
 --and (undoblks > (select 0.1 * sum(bytes) from dba_tablespaces t, dba_data_files f where  contents = 'UNDO' and t.tablespace_name = f.tablespace_name) 
--	or maxquerylen > 5*60)
--order by begin_time;

PROMPT <a id="#CF" name="CF"><p class="descHeader">Controlfile Details:</p>
select * from v$controlfile order by 1;
--select * from v$controlfile_record_section;

PROMPT <a id="#OB" name="OB"><p class="descHeader">Database Objects Information:</p>
select distinct
 owner "Owner",
 tablespace_name  "Tablespace",
 (select count(*) from dba_tables
  where tablespace_name = all_ts.tablespace_name
    and owner = all_ts.owner
 ) "No of Tables",
 (select count(*) from dba_segments ds
	where segment_type = 'TABLE'
	  and tablespace_name = all_ts.tablespace_name
    	  and owner = all_ts.owner
	  and not exists ( select 'X' from dba_constraints
				where owner = ds.owner
				  and table_name = ds.segment_name
				  and constraint_type = 'P')
 ) "Tables without PK", 
 (select count(*) from dba_tables dt
	where tablespace_name = all_ts.tablespace_name
	  and owner = all_ts.owner
	  and (select count(*) from dba_indexes di
		where tablespace_name = all_ts.tablespace_name
		  and owner = all_ts.owner
		  and di.table_name = dt.table_name) > 5
 ) "Tables with 5+ indexes",
 (select count(*) from dba_indexes
  where tablespace_name = all_ts.tablespace_name
    and owner = all_ts.owner
 ) "No of Indexes"
 from (select tablespace_name,owner from dba_tables
       UNION
       select tablespace_name,owner from dba_indexes) all_ts
 where tablespace_name is not null
    and owner not in ( 'SYSTEM','SYS','SYSAUX','CTXSYS','DBSNMP','DMSYS','EXFSYS','MDSYS',
   'OLAPSYS','ORDSYS','SYSMAN','WKSYS','WK_TEST','WMSYS','XDBO','LAPSYS',
   'OUTLN','OE','XDB');


PROMPT <a id="#SQ" name="SQ"><p class="descHeader">Long Running SQL Information ( > 30 mins )</p>

column sql_text format a50 wrap on;
column "Time (Mins)" format 999990.99;
select 	
	elapsed_time/(1000*1000*60) "Time (Mins)",
	executions,
	sorts,
	disk_reads,
	optimizer_mode,
	cpu_time,
	substr(sql_text,1,200) sql_text
from v$sql
where elapsed_time > (30*60*1000*1000)
order by elapsed_time desc;

--PROMPT <a id="#AI" name="#AI"><p class="descHeader">APPENDIX-I: Database Parameters</p>
--select 	name		"Parameter",
--	description	"Description",
--	value		"Value"
--from v$parameter order by name;

--PROMPT <a id="#AII" name="#AII"><p class="descHeader">APPENDIX-II: Database installed Options</p>
--select * from v$option;

--PROMPT <a id="#AIII" name="#AIII"><p class="descHeader">APPENDIX-III: System Statistics ( V$SYSSTAT ) </p>
--select * from v$sysstat;

--PROMPT <a id="#AIV" name="#AIV"><p class="descHeader">APPENDIX-IV: Operating System Statistics ( V$OSSTAT) - Oracle 10g only  </p>
-- select * from v$OSSTAT;

--PROMPT <a id="#AV" name="#AV"><p class="descHeader">APPENDIX-V: System Global Area Statistics ( V$SGASTAT ) </p>
--select * from v$sgastat;

--PROMPT <a id="#AVI" name="#AVI"><p class="descHeader">APPENDIX-VI: Resource Limits </p>
--select * from v$resource_limit;

PROMPT <a id="#AVII" name="AVII"><p class="descHeader"> Installed Products </p>
select * from product_component_version;

PROMPT <a id="#AVIII" name="AVIII"><p class="descHeader"> Datafile Statistics </p>
select tablespace_name,file_name,
 	phyrds "Ph Rd",
 	phywrts "Ph Wr",
 	phyblkrd "Blk Rd"
from dba_data_files d, v$filestat f
where d.file_id = f.file#
order by 1,2;

--PROMPT <a id="#IX" name="#IX"><p class="descHeader">APPENDIX-IX: Database Processes </p>
--select 
--	PID,
--	SPID,
--	USERNAME,
--	TERMINAL,
--	PROGRAM,
--	BACKGROUND,
--	LATCHWAIT,
--	LATCHSPIN,
--	PGA_USED_MEM,
--	PGA_ALLOC_MEM,
--	PGA_MAX_MEM
--from v$process;

--PROMPT <a id="#X" name="#X"><p class="descHeader">APPENDIX-X: Wait Statistics </p>
--select * from V$WAITSTAT;

--PROMPT <a id="#XI" name="#XI"><p class="descHeader">APPENDIX-XI: System Events </p>
--select * from V$SYSTEM_EVENT Order by average_wait desc;

PROMPT Thanks,
PROMPT NETENRICH INDIA
spool off;
set markup html off;

exit;

EOF