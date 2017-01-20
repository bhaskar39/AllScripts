# Get the Server Name
$hostname = $env:COMPUTERNAME

# Get the available SQL Server Instances in the Server
$SQLServerInstances = (Get-ItemProperty 'HKLM:\Software\Microsoft\Microsoft SQL Server').InstalledInstances

# SQL Query Text for fetching the data
$sqlquery = @"
--drop table #jobstst
--drop table #jobst
--drop table #jobstss
--drop table #DBSTATS
Use master

set nocount on
set concat_null_yields_null OFF

DECLARE			@DBStatus			VARCHAR(8000),
                @dbsummary          VARCHAR(8000),
				@BackupCheck		VARCHAR(8000),
				@LowDiskSpace		VARCHAR(8000),
				@DBFileStats		VARCHAR(8000),
				@FailedJobs			VARCHAR(8000),
				@LowDBSpace			VARCHAR(8000),
				@DiskSpace		VARCHAR(8000),
				@JobStatus			VARCHAR(8000),
				@InstanceName       VARCHAR(500),
                @FinalXML			VARCHAR(8000),
				@serverDetails		VARCHAR(8000),
				@sqlErrorMsg		varchar(2000),
				@sqlErrorXML		varchar(2000),
				--@sqlErrorNo			INT,
                @st varchar(20),
                @uptime varchar(100),@edition varchar(30),@jcnt int,@totaldbsummary varchar(8000)

--drop  table #jobst
declare @a int
select @a=datediff(mi,crdate,getdate()) from sysdatabases where name='tempdb'
SELECT @uptime=@uptime+'<uptime time="'+cast(@a/24/60 AS varchar(5)) +' day(s) '+ CAST(@a/60%24 AS varchar(5))+' hour(s) '+CAST(@a%60 AS varchar(5))+' minute(s)'+'" />'

select @edition=cast(serverproperty('edition') as varchar(30))
Create table #jobstst(jobname varchar(100),LRD varchar(25),NRD varchar(25))
				Create  table #jobst
				(
				job_id uniqueidentifier,LRD int,LRT int,NRD int,NRT int,NRSC int,RTR int,RS int,RSID varchar(100),
				runnig int,CST int,CRA int,state int)
Create table #jobstss (jobname varchar(100),Lastrunstatus varchar(12),TR int,su int,fa int)

				Create table #jobsts (job_id uniqueidentifier,jobname varchar(100),runstatus int)
				
if @edition<>'Express Edition'


	 BEGIN


			create table #state(st varchar(20))
			insert into #state Exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'SQLServerAgent'
			select @st=st from #state
			drop table #state

			if @st='Running.'
			BEGIN
				select @sqlErrorMsg=@sqlErrorMsg+'' 
				select @jcnt=count(*) from msdb..sysjobs SJ where SJ.enabled=1 

				

				Insert into #jobst EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, ''

				insert into #jobstst
				select CAST(SJ.name AS VARCHAR(100))-- AS [Job Name]
				,CAST(isnull(stuff(stuff(SJH.LRD,(len(SJH.LRD)-1),0,'-'),(len(SJH.LRD)-3),0,'-')+ ' ' +stuff(stuff(SJH.LRT,(len(SJH.LRT)-1),0,':'),(len(SJH.LRT)-3),0,':'),'N/A') AS VARCHAR(25))-- AS LastRunDate
				,CAST(isnull(stuff(stuff(SJH.NRD,(len(SJH.NRD)-1),0,'-'),(len(SJH.NRD)-3),0,'-')+ ' ' +stuff(stuff(SJH.NRT,(len(SJH.NRT)-1),0,':'),(len(SJH.NRT)-3),0,':'),'N/A') AS VARCHAR(25)) --AS NextRunDate
				from msdb..sysjobs SJ
				LEFT JOIN #jobst SJH ON SJ.job_id=SJH.job_id
				LEFT JOIN msdb..sysjobhistory SJH1 ON SJ.job_id=SJH1.job_id
				and SJH1.instance_id=(select max(instance_id) from msdb..sysjobhistory
											 where job_id=SJ.job_id group by job_id)
				where --SJ.enabled=1 and
				--and SJH1.run_status=0
				--stuff(stuff(SJH.LRD,(len(SJH.LRD)-1),0,'-'),(len(SJH.LRD)-3),0,'-')+ ' ' +stuff(stuff(SJH.LRT,(len(SJH.LRT)-1),0,':'),(len(SJH.LRT)-3),0,':')>dateadd(dd,-1,getdate())
				(stuff(stuff(SJH.LRD,(len(SJH.LRD)-1),0,'-'),(len(SJH.LRD)-3),0,'-')+ ' ' +
				(CASE WHEN len(SJH.LRT)>4 THEN stuff(stuff(SJH.LRT,(len(SJH.LRT)-1),0,':'),(len(SJH.LRT)-3),0,':')
				      WHEN len(SJH.LRT)>2 THEN stuff(stuff(SJH.LRT,(len(SJH.LRT)-1),0,':'),(len(SJH.LRT)-3),0,'00:')
					ELSE stuff(SJH.LRT,(len(SJH.LRT)-1),0,'00:00:')END))> dateadd(dd,-1,getdate())
				--order by SJ.Name
				--select * from #jobstst

				insert into #jobsts
				select SJ.job_id
				,SJ.name 
				,SJH.run_status 
				from msdb..sysjobhistory SJH 
				inner join msdb..sysjobs SJ on SJH.job_id=SJ.job_id
				where
				step_id=0 and --len(SJH.run_time)>4 and
				(stuff(stuff(SJH.run_date,(len(SJH.run_date)-1),0,'-'),(len(SJH.run_date)-3),0,'-')+ ' ' +
				(CASE WHEN len(SJH.run_time)>4 THEN stuff(stuff(SJH.run_time,(len(SJH.run_time)-1),0,':'),(len(SJH.run_time)-3),0,':')
				      WHEN len(SJH.run_time)>2 THEN stuff(stuff(SJH.run_time,(len(SJH.run_time)-1),0,':'),(len(SJH.run_time)-3),0,'00:')
					ELSE stuff(SJH.run_time,(len(SJH.run_time)-1),0,'00:00:')END))>dateadd(dd,-1,getdate())
				--stuff(stuff(SJH.run_date,(len(SJH.run_date)-1),0,'-'),(len(SJH.run_date)-3),0,'-')+ ' ' +stuff(stuff(SJH.run_time,(len(SJH.run_time)-1),0,':'),(len(SJH.run_time)-3),0,':')>dateadd(dd,-1,getdate())
				--drop table #jobsts
				--select * from #jobsts
				insert into #jobstss
				select X.jobname
				,CASE SJH.run_status WHEN 0 THEN 'FAILED'
									 WHEN 1 THEN 'SUCCESS'
									 END LastRunstatus
				,(sum(success)+sum(failed)) [TotalRuns],sum(success) Success,sum(failed) Failed from
				(
				select job_id,jobname
				,count(jobname) as success,0 as failed 
				from #jobsts where runstatus=1
				group by job_id,jobname,runstatus
				UNION
				select job_id,
				jobname
				,0 as success,count(jobname) as failed 
				from #jobsts where runstatus=0
				group by job_id,jobname,runstatus
				)X
				LEFT JOIN msdb..sysjobhistory SJH ON X.job_id=SJH.job_id
				where SJH.instance_id=(select max(instance_id) from msdb..sysjobhistory
											  where job_id=SJH.job_id group by job_id)

				group by X.job_id,X.jobname,SJH.run_status
				--select * from #jobstss
				SELECT @JobStatus = @JobStatus + '<js jobName="'+JT1.jobname+'" lastRunStatus="'+JT1.Lastrunstatus+
												 '" lastRunDate="'+convert(varchar(25),JT2.LRD,120)+'" nextRunDate="'+convert(varchar(25),JT2.NRD,120)+'" totalRuns="'+cast(JT1.TR as varchar(5))+
												 '" success="'+cast(JT1.su as varchar(5))+'" failed="'+cast(JT1.fa as varchar(5) )+'" />' 
			--SELECT JT1.jobname,convert(varchar(25),JT2.LRD,120),convert(varchar(25),JT2.NRD,120),cast(JT1.TR as varchar(5)),cast(JT1.su as varchar(5)),cast(JT1.fa as varchar(5) )
				from #jobstss JT1
				LEFT JOIN  #jobstst JT2
				ON JT1.jobname=JT2.jobname
				--order by jobname

				SELECT @FailedJobs = @FailedJobs + '<fj insName="'+CAST(SERVERPROPERTY('servername') AS VARCHAR(50))+'" jobName="'+JT1.jobname+'" lastRunStatus="'+JT1.Lastrunstatus+
												 '" lastRunDate="'+convert(varchar(25),JT2.LRD,120)+'" nextRunDate="'+convert(varchar(25),JT2.NRD,120)+'" totalRuns="'+cast(JT1.TR as varchar(5))+
												 '" success="'+cast(JT1.su as varchar(5))+'" failed="'+cast(JT1.fa as varchar(5) )+'" />' 

				from #jobstss JT1
				LEFT JOIN  #jobstst JT2
				ON JT1.jobname=JT2.jobname
				WHERE JT1.Lastrunstatus='FAILED'

				
			END

			ELSE
				BEGIN
				Select @sqlErrorMsg = @sqlErrorMsg + 'SQL server Agent is not running.Check the service status'
				END
END
ELSE 
  BEGIN
  			Select @sqlErrorMsg = @sqlErrorMsg + 'No SQL AGENT'
END 

IF @jcnt=0
    BEGIN 
      SELECT '<jobStatus msg="* No enabled jobs on the SQL server" error="'+@sqlErrorMsg+'" >'
      
      SELECT '<js jobName="'+JT1.jobname+'" lastRunStatus="'+JT1.Lastrunstatus+
      												 '" lastRunDate="'+convert(varchar(25),JT2.LRD,120)+'" nextRunDate="'+convert(varchar(25),JT2.NRD,120)+'" totalRuns="'+cast(JT1.TR as varchar(5))+
      												 '" success="'+cast(JT1.su as varchar(5))+'" failed="'+cast(JT1.fa as varchar(5) )+'" />' 
      			--SELECT JT1.jobname,convert(varchar(25),JT2.LRD,120),convert(varchar(25),JT2.NRD,120),cast(JT1.TR as varchar(5)),cast(JT1.su as varchar(5)),cast(JT1.fa as varchar(5) )
      				from #jobstss JT1
      				LEFT JOIN  #jobstst JT2
      				ON JT1.jobname=JT2.jobname
      				--order by jobname
      SELECT '</jobStatus>'

    END
ELSE
    BEGIN
      SELECT '<jobStatus error="'+@sqlErrorMsg+'" >'
      
	SELECT '<js jobName="'+JT1.jobname+'" lastRunStatus="'+JT1.Lastrunstatus+
	      												 '" lastRunDate="'+convert(varchar(25),JT2.LRD,120)+'" nextRunDate="'+convert(varchar(25),JT2.NRD,120)+'" totalRuns="'+cast(JT1.TR as varchar(5))+
	      												 '" success="'+cast(JT1.su as varchar(5))+'" failed="'+cast(JT1.fa as varchar(5) )+'" />' 
	      			--SELECT JT1.jobname,convert(varchar(25),JT2.LRD,120),convert(varchar(25),JT2.NRD,120),cast(JT1.TR as varchar(5)),cast(JT1.su as varchar(5)),cast(JT1.fa as varchar(5) )
	      				from #jobstss JT1
	      				LEFT JOIN  #jobstst JT2
	      				ON JT1.jobname=JT2.jobname
      				--order by jobname
      
      
      SELECT '</jobStatus>'
    END
    
				drop table #jobsts
				drop table #jobst
				drop table #jobstst
				drop table #jobstss

IF @FailedJobs IS NOT NULL
BEGIN
SELECT @FailedJobs = '<failedJobs chk="1" error="'+@sqlErrorMsg+'" >'+ @FailedJobs+ '</failedJobs>'
END
ELSE
BEGIN
 IF @jcnt=0
    BEGIN 
       SELECT @FailedJobs = '<failedJobs chk="0" msg="* No enabled jobs on the SQL server" error="'+@sqlErrorMsg+'" >'+ @FailedJobs+ '</failedJobs>'
    END
 ELSE
    BEGIN
       SELECT @FailedJobs = '<failedJobs chk="0" msg="* All enabled jobs executed and completed successfully without any issues" error="'+@sqlErrorMsg+'" >'+ @FailedJobs+ '</failedJobs>'
    END
END

SELECT @DBStatus =  @DBStatus + 

'<dbs databaseName="'+ CAST(name AS VARCHAR(30)) + '" Status="' + CAST(DATABASEPROPERTYEX (name ,'status' ) AS VARCHAR(10))

+ '" />'

	from sysdatabases order by name


Select @dbsummary=@dbsummary+'<sdb insName="'+CAST(SERVERPROPERTY('servername') AS VARCHAR(50))+'" status="'+CAST(isnull(A.[Status],'TOTAL')as varchar(10))+'" count="'+CAST(SUM(A.[Count])as varchar(3))+'" />'
 from
(
select databasepropertyex(name,'status') [Status],count(*) [Count]
from sysdatabases 
group by databasepropertyex(name,'status')
UNION
Select 'ONLINE',0
UNion
Select 'OFFLINE',0

) A
group by A.Status
WITH ROLLUP
Order by Status desc

Select @totaldbsummary=@totaldbsummary+'<sdb insName="'+CAST(SERVERPROPERTY('servername') AS VARCHAR(50))+'" online="'+cast((select  count(*) [Count]
from sysdatabases 
where databasepropertyex(name,'status')= 'ONLINE') as varchar(3))+'" offline="'+cast((select  count(*) 
from sysdatabases 
where databasepropertyex(name,'status')= 'OFFLINE') as varchar(3))+'" total="'+cast((select count(name) from sysdatabases) as varchar(3))+'" />'


if @totaldbsummary IS NOT NULL
BEGIN

select @totaldbsummary= '<totaldbStatus>' +@totaldbsummary + '</totaldbStatus>'

END


if @DBStatus IS NOT NULL

BEGIN

select @DBStatus = '<dbStatus>' + @DBStatus + '</dbStatus>'

END

if @dbsummary IS NOT NULL

BEGIN

select @dbsummary = '<dbsummary>' + @dbsummary + '</dbsummary>'

END

--select @DBStatus  DBStatus


select  @BackupCheck = @BackupCheck +'<bc databaseName="' +CAST(d.name AS VARCHAR(30))+'" type="'+CASE WHEN d.dbid>4 THEN 'USERDB' ELSE 'SYSTEMDB' END+
'" status="'+CAST(DATABASEPROPERTYEX (name ,'status' ) AS VARCHAR(10))+
'" recoveryMode="'+CAST(DATABASEPROPERTYEX (name ,'recovery' ) AS VARCHAR(10))+
'" lastFullBackup="' +CASE d.name WHEN 'tempdb' THEN 'N/A' ELSE isnull(convert(varchar(25),F.LastDate,120),'N/A') END+
'" lastLogBackup="' +CASE d.name WHEN 'tempdb' THEN 'N/A' ELSE isnull(CASE DATABASEPROPERTYEX(d.name,'Recovery') WHEN 'FULL' THEN convert(varchar(25),L.LastDate,120)
	 ELSE 'N/A' END,'N/A') END+ '" />'
	FROM sysdatabases d
	left join 
		(
			SELECT database_name, 
					max(backup_finish_date) LastDate 
			FROM msdb..backupset
			WHERE type = 'D'
			GROUP BY database_name
		) F ON F.database_name = d.name
	left join 
		(
			SELECT database_name, 
					MAX(backup_finish_date) LastDate 
			FROM msdb..backupset 
			WHERE type = 'L' 
			GROUP BY database_name
		) L ON L.database_name = d.name
	   --WHERE d.name not in ('tempdb') 

 


if @BackupCheck is Not NULL

BEGIN
SELECT @BackupCheck = '<backupCheck>' + @BackupCheck + '</backupCheck>'
END



--select @BackupCheck BackupCheck




create table #test11(drive varchar(2),[size] float)
insert into #test11 exec xp_fixeddrives

SELECT @DiskSpace = @DiskSpace + '<ds drive="' + CAST(drive AS VARCHAR(30)) + 
		'" freeSpaceGB="' + CAST(ROUND(([size]/1024.0),2) as varchar(10)) + '" />'
		from  #test11

SELECT @LowDiskSpace = @LowDiskSpace + '<ld insName="'+cast(serverproperty('machinename') as varchar(50))+'" drive="' + CAST(drive AS VARCHAR(30)) + 
		'" freeSpaceGB="' + CAST(ROUND(([size]/1024.0),2) as varchar(10)) + '" />'
		from  #test11
WHERE [size]/1024.0<2.0 and drive not in ('X','Y')

IF @DiskSpace IS NOT NULL
	BEGIN
	select @DiskSpace = '<discSpace>'+ @DiskSpace +  '</discSpace>'
	END

IF @LowDiskSpace IS NOT NULL
	BEGIN
	select @LowDiskSpace = '<lowDiscSpace chk="1" >'+ @LowDiskSpace +  '</lowDiscSpace>'
	END
ELSE
BEGIN 
select @LowDiskSpace = '<lowDiscSpace chk="0" msg="* All disk drives have enough free space(>2 GB)" >'+ @LowDiskSpace +  '</lowDiscSpace>'
END
--select @LowDiskSpace LowDiskSpace


drop table #test11


CREATE TABLE #DBSTATS (
   dbname   sysname,
   fn varchar(200) NULL,
   lname    sysname,
   usage    varchar(20),
   [size]   decimal(9, 2) NULL ,
   [used]   decimal(9, 2) NULL ,
   autogrow varchar(5) NULL
) 

IF OBJECT_ID('tempdb..#temp_log') IS NOT NULL
BEGIN
   DROP TABLE #temp_log
END 

CREATE TABLE #temp_log
(
   DBname          sysname,
   LogSize         real,
   LogSpaceUsed    real,
   Status          int
) 

IF OBJECT_ID('tempdb..#temp_sfs') IS NOT NULL
BEGIN
   DROP TABLE #temp_sfs
END 

CREATE TABLE #temp_sfs
(
   fileid          int,
   filegroup       int,
   totalextents    int,
   usedextents     int,
   name            varchar(1024),
   filename        varchar(1024)
) 

DECLARE @dbname sysname
       ,@sql varchar(8000) 

IF OBJECT_ID('tempdb..#temp_db') IS NOT NULL
BEGIN
    DROP TABLE #temp_db
END 

SELECT name INTO #temp_db
   FROM master.dbo.sysdatabases
   WHERE DATABASEPROPERTY(name,'IsOffline') = 0
   AND has_dbaccess(name) = 1
   ORDER BY name 

WHILE (1 = 1)
BEGIN
   SET @dbname = NULL 

   SELECT TOP 1 @dbname = name
   FROM #temp_db
   ORDER BY name 

   IF @dbname IS NULL
      GOTO _NEXT 

   SET @sql = ' USE [' + @dbname + '] 

      TRUNCATE TABLE #temp_sfs 

      INSERT INTO #temp_sfs
         EXECUTE(''DBCC SHOWFILESTATS'') 

      INSERT INTO #DBSTATS (dbname, lname, usage, [size], [used])
         SELECT db_name(), name, ''Data''
         , totalextents * 64.0 / 1024.0
         , usedextents * 64.0 / 1024.0
         FROM #temp_sfs 
      
      INSERT INTO #DBSTATS (dbname, lname, usage, [size], [used])
         SELECT db_name(), name, ''Log'', null, null
         FROM sysfiles
         WHERE status & 0x40 = 0x40

	  UPDATE #DBSTATS 
		SET autogrow= ( CASE WHEN sf.growth > 0 THEN ''Yes'' ELSE ''No'' END ) 
		FROM #DBSTATS ds INNER JOIN sysfiles sf ON ds.lname COLLATE SQL_Latin1_General_CP1_CI_AS = sf.name COLLATE SQL_Latin1_General_CP1_CI_AS
WHERE ds.dbname='''+ @dbname+''' 
      UPDATE #DBSTATS 
		SET fn = filename
		FROM #DBSTATS ds INNER JOIN sysfiles sf ON ds.lname COLLATE SQL_Latin1_General_CP1_CI_AS = sf.name COLLATE SQL_Latin1_General_CP1_CI_AS
		WHERE ds.dbname=' +''''+ @dbname +''''
--PRINT (@sql)
    EXEC(@sql) 

    DELETE FROM #temp_db WHERE name = @dbname
END 

_NEXT: 

INSERT INTO #temp_log
   EXECUTE ('DBCC SQLPERF(LOGSPACE)') 

UPDATE #DBSTATS
   SET size = B.LogSize
   , used = LogSize * LogSpaceUsed / 100
FROM #DBSTATS A
INNER JOIN #temp_log B
    ON (A.dbname = B.DBname)AND(A.usage = 'Log') 

SELECT '<dbFileStatus>' 

--SELECT @DBFileStats=@DBFileStats+
select 
'<dfs dbName="'+dbname+'" type="'+CASE WHEN db_id(dbname)>4 THEN 'USERDB' ELSE 'SYSTEMDB' END+'" fileType="'+usage+'" fileName="'+fn+'" totalMB="'+cast([size] as varchar(10))
   +'" usedMB="'+cast(used as varchar(10))+'" freeMB="'+cast(([size]-used) as varchar(10))+'" usedPct="'
   +cast((cast(used/[size]*100 AS numeric(9,2))) as varchar(10))+'" freePct="'+
   cast((cast(100-(used/[size]*100) AS numeric(9,2))) as varchar(10))+
	'" autoGrow="'+autogrow+'" />'
FROM #DBSTATS
ORDER BY dbname, usage 

SELECT '</dbFileStatus>'
--SELECT @DBFileStats

select @LowDBSpace=@LowDBSpace+'<lds insName="'+CAST(SERVERPROPERTY('servername') AS VARCHAR(50))+'" dbName="'+dbname+'" type="'+CASE WHEN db_id(dbname)>4 THEN 'USERDB' ELSE 'SYSTEMDB' END+'" fileType="'+usage+'" fileName="'+fn+'" totalMB="'+cast([size] as varchar(10))
   +'" freePct="'+
   cast((cast(100-(used/[size]*100) AS numeric(9,2))) as varchar(10))+
'" autoGrow="'+autogrow+'" />'
FROM #DBSTATS
WHERE (100-(used/[size]*100))<5 --and autogrow='No'
ORDER BY dbname, usage 


DROP TABLE #DBSTATS
DROP TABLE #temp_db
DROP TABLE #temp_sfs
DROP TABLE #temp_log 

IF @DBFileStats IS NOT NULL

	BEGIN
	SELECT @DBFileStats = '<dbFileStatus>' +  @DBFileStats + '</dbFileStatus>'
	END
IF @LowDBSpace IS NOT NULL

	BEGIN
	SELECT @LowDBSpace = '<lowDbSpace chk="1" >' +  @LowDBSpace + '</lowDbSpace>'
	END
 ELSE
  BEGIN
  SELECT @LowDBSpace = '<lowDbSpace chk="0" msg="* All databases have enough free space(>=5%) or autogrow enabled on their data and log files " >'+ @LowDBSpace + '</lowDbSpace>'
  END 

--drop table #FileStats 
--drop table #logdetails 
select @serverDetails = '<date>'+convert(varchar(25),getdate(),120)+'</date>'
--select @InstanceName = '<date>'+convert(varchar(25),getdate(),120)+'</date>'

    CREATE TABLE #tempTotal  
      
    (  
    DatabaseName varchar(255),  
    Field VARCHAR(255),  
    Value VARCHAR(255)  
    )  
    CREATE TABLE #temp  
    (  
    ParentObject VARCHAR(255),  
    Object VARCHAR(255),  
    Field VARCHAR(255),  
    Value VARCHAR(255)  
    )  
    EXECUTE sp_MSforeachdb '  
    INSERT INTO #temp EXEC(''DBCC DBINFO ( ''''?'''') WITH TABLERESULTS'')  
    INSERT INTO #tempTotal (Field, Value, DatabaseName)  
    SELECT Field, Value, ''?'' FROM #temp  
    TRUNCATE TABLE #temp';  
    ;WITH cte as  
    (  
    SELECT  
    ROW_NUMBER() OVER(PARTITION BY DatabaseName, Field ORDER BY Value DESC) AS rn,  
    DatabaseName,  
    Value  
    FROM #tempTotal t1  
    WHERE (Field = 'dbi_dbccLastKnownGood')  
    )  
    SELECT  
    DatabaseName,  
    Value as dbccLastKnownGood  
    FROM cte  
    WHERE (rn = 1)  
    DROP TABLE #temp  
    DROP TABLE #tempTotal  

--select @FinalXML =  @serverDetails+@uptime +@JobStatus + @FailedJobs +@dbsummary+ @DBStatus + @BackupCheck  + @DBFileStats+@LowDBSpace + @DiskSpace+@LowDiskSpace
select @serverDetails
select @uptime 
--select @JobStatus 
select @FailedJobs
select @dbsummary
select @totaldbsummary
select @DBStatus 
select @BackupCheck 
--select @DBFileStats
select @LowDBSpace
select @DiskSpace
select @LowDiskSpace


--
--select @FinalXML
"@
$SQLVersionQuery = @"
        SELECT 'BuildClrVersion' ColumnName, SERVERPROPERTY('BuildClrVersion') ColumnValue
        UNION ALL
        SELECT 'Collation', SERVERPROPERTY('Collation')
        UNION ALL
        SELECT 'CollationID', SERVERPROPERTY('CollationID')
        UNION ALL
        SELECT 'ComparisonStyle', SERVERPROPERTY('ComparisonStyle')
        UNION ALL
        SELECT 'ComputerNamePhysicalNetBIOS', SERVERPROPERTY('ComputerNamePhysicalNetBIOS')
        UNION ALL
        SELECT 'Edition', SERVERPROPERTY('Edition')
        UNION ALL
        SELECT 'EditionID', SERVERPROPERTY('EditionID')
        UNION ALL
        SELECT 'EngineEdition', SERVERPROPERTY('EngineEdition')
        UNION ALL
        SELECT 'InstanceName', SERVERPROPERTY('InstanceName')
        UNION ALL
        SELECT 'IsClustered', SERVERPROPERTY('IsClustered')
        UNION ALL
        SELECT 'IsFullTextInstalled', SERVERPROPERTY('IsFullTextInstalled')
        UNION ALL
        SELECT 'IsIntegratedSecurityOnly', SERVERPROPERTY('IsIntegratedSecurityOnly')
        UNION ALL
        SELECT 'IsSingleUser', SERVERPROPERTY('IsSingleUser')
        UNION ALL
        SELECT 'LCID', SERVERPROPERTY('LCID')
        UNION ALL
        SELECT 'LicenseType', SERVERPROPERTY('LicenseType')
        UNION ALL
        SELECT 'MachineName', SERVERPROPERTY('MachineName')
        UNION ALL
        SELECT 'NumLicenses', SERVERPROPERTY('NumLicenses')
        UNION ALL
        SELECT 'ProcessID', SERVERPROPERTY('ProcessID')
        UNION ALL
        SELECT 'ProductVersion', SERVERPROPERTY('ProductVersion')
        UNION ALL
        SELECT 'ProductLevel', SERVERPROPERTY('ProductLevel')
        UNION ALL
        SELECT 'ResourceLastUpdateDateTime', SERVERPROPERTY('ResourceLastUpdateDateTime')
        UNION ALL
        SELECT 'ResourceVersion', SERVERPROPERTY('ResourceVersion')
        UNION ALL
        SELECT 'ServerName', SERVERPROPERTY('ServerName')
        UNION ALL
        SELECT 'SqlCharSet', SERVERPROPERTY('SqlCharSet')
        UNION ALL
        SELECT 'SqlCharSetName', SERVERPROPERTY('SqlCharSetName')
        UNION ALL
        SELECT 'SqlSortOrder', SERVERPROPERTY('SqlSortOrder')
        UNION ALL
        SELECT 'SqlSortOrderName', SERVERPROPERTY('SqlSortOrderName')

"@
    $RAMQuery = @"
    DECLARE @total_buffer INT;
    SELECT @total_buffer = cntr_value   FROM sys.dm_os_performance_counters
    WHERE RTRIM([object_name]) LIKE '%Buffer Manager'   AND counter_name = 'Total Pages';
    ;WITH src AS(   SELECT        database_id, db_buffer_pages = COUNT_BIG(*) 
    FROM sys.dm_os_buffer_descriptors       --WHERE database_id BETWEEN 0 AND 32766       
    GROUP BY database_id)SELECT   [db_name] = CASE [database_id] WHEN 32767        THEN 'Resource DB'        ELSE DB_NAME([database_id]) END,   db_buffer_pages,   db_buffer_MB = db_buffer_pages / 128,   db_buffer_percent = CONVERT(DECIMAL(6,3),        db_buffer_pages * 100.0 / @total_buffer)
    FROM src
    ORDER BY db_buffer_MB DESC; 
"@

$LastRunCode = @"
    CREATE TABLE #tempTotal  
      
    (  
    DatabaseName varchar(255),  
    Field VARCHAR(255),  
    Value VARCHAR(255)  
    )  
    CREATE TABLE #temp  
    (  
    ParentObject VARCHAR(255),  
    Object VARCHAR(255),  
    Field VARCHAR(255),  
    Value VARCHAR(255)  
    )  
    EXECUTE sp_MSforeachdb '  
    INSERT INTO #temp EXEC(''DBCC DBINFO ( ''''?'''') WITH TABLERESULTS'')  
    INSERT INTO #tempTotal (Field, Value, DatabaseName)  
    SELECT Field, Value, ''?'' FROM #temp  
    TRUNCATE TABLE #temp';  
    ;WITH cte as  
    (  
    SELECT  
    ROW_NUMBER() OVER(PARTITION BY DatabaseName, Field ORDER BY Value DESC) AS rn,  
    DatabaseName,  
    Value  
    FROM #tempTotal t1  
    WHERE (Field = 'dbi_dbccLastKnownGood')  
    )  
    SELECT  
    DatabaseName,  
    Value as dbccLastrundate
    FROM cte  
    WHERE (rn = 1)  
    DROP TABLE #temp  
    DROP TABLE #tempTotal
"@


function Get-SQLResIns
{
    Param 
    (
        [string]$SQLIns,
        [string]$Query
    )

    $SqlConnactionString = "Server=`'$SQLIns`';Integrated Security=True"
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $sqlConnection.ConnectionString = $SqlConnactionString
    $sqlConnection.Open()
    $SqlCommand = New-Object System.Data.SqlClient.SqlCommand
    $SqlCommand.Connection = $sqlConnection
    $SqlCommand.CommandText = $Query
    #$result = $SqlCommand.ExecuteReader()
    $result = $SqlCommand.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($result)
    $FinalResultRam = $DataTable
    Return $FinalResultRam
}
# Create a temporary directory for SQL Automation operation
$CurrentDir = (Get-Location).Path
#$CurrentDir = (New-Item -Path $CurrentDir -Name SQLAutomation -ItemType Directory -Force -ErrorAction Stop).FullName

# Create a SQL Query text file in rge above created directory
$sqlquerypath = "$CurrentDir\sqlquery.txt"
$sqlquery = Set-Content -Value $sqlquery -Path $sqlquerypath -Force -ErrorAction Stop

# Get the Server Status
$wmiQuery = "Select * from Win32_PingStatus Where Address = `'$hostname`'"
$PingStatus = Get-WmiObject -Query $wmiQuery

# Create a xml file to store the sql query result
$xmlfile = (New-Item -Name CompleteOutFile.xml -ItemType File -Path $CurrentDir -Force -ErrorAction Stop).FullName
$xmlfileData = Add-Content -Value "<?xml version=`"1.0`"?><root>" -Path $xmlfile -ErrorAction Stop
Try 
{
    $InstanceStateObj = New-Object System.Collections.ArrayList
    if($PingStatus.StatusCode -eq 0)
    {
        foreach ($a in $SQLServerInstances)
        {   
            $SQLInstancesStatus = Get-Service -DisplayName "SQL Server ($a)"
            $newObj = New-Object psobject

            if($a -eq 'MSSQLServer')
            {
                $ServerName = $hostname
            }
            Else
            {
                $ServerName = "$hostname\$a"
            }

            if($SQLInstancesStatus.Status -eq 'Running')
            {
                $newObj | Add-Member -MemberType NoteProperty -Name 'SQLServer Name' -Value "$ServerName"
                $newObj | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Running'
            }
            Else
            {
                $newObj | Add-Member -MemberType NoteProperty -Name 'SQLServer Name' -Value "$ServerName"
                $newObj | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Stopped'
            }
            $InstanceStateObj += $newObj

            if($SQLInstancesStatus.Status -eq 'Running')
            {
                $xmlfileData = Add-Content -Value "<instance name=`"$ServerName`" error="""" >" -Path $xmlfile

                # Create command to run the sqlquery
                #$commandExpression = "cmd.exe /c sqlcmd.exe -S $ServerName -U Sa -P Pass@123 -i `'$CurrentDir\sqlquery.txt`'"
                $commandExpression = "cmd.exe /c sqlcmd.exe -S $ServerName -E -i `'$CurrentDir\sqlquery.txt`'" 
                $OutStatus = Invoke-Expression -Command $commandExpression -ErrorAction Stop
                $sqlOutPut = @()
                if($OutStatus)
                {
                    foreach ($line in $OutStatus)
                    {
                        if(($line -match "--") -or (!($line.StartsWith('<'))) -or (!$line))
                        {
                            continue
                        }
                        $sqlOutPut += $line   
                    }
                }
                $xmlfileData = Add-Content -Value $sqlOutPut -Path $xmlfile

                # Fetch all SQL related services on SQL Server
                $AllServervices = Get-WmiObject -Query "Select * from Win32_Service Where Name like '%SQL%' and Name!='MySQL'"

                # Append the data to xml file
                $AppendServiceData = @"
                <Services>
"@
                foreach($service in $AllServervices)
                {
                    $AppendServiceData += @"
                    <st serviceName=`"$($service.Name)`" type=`"$($service.StartMode)`" Status=`"$($service.state)`" />
"@
                }
                $AppendServiceData += @"
                </Services>
"@  
                $xmlfileData = Add-Content -Value $AppendServiceData -Path $xmlfile
                $xmlfileData = Add-Content -Value "</instance>" -Path $xmlfile
            }
        }
    }
    Else # In case if the server is not available
    {
        foreach ($a in $SQLServerInstances)
        {   
            $SQLInstancesStatus = Get-Service -DisplayName "SQL Server ($a)"
            $newObj = New-Object psobject

            if($a -eq 'MSSQLServer')
            {
                $ServerName = $hostname
            }
            Else
            {
                $ServerName = "$hostname\$a"
            }

            if($SQLInstancesStatus.Status -eq 'Running')
            {
                $newObj | Add-Member -MemberType NoteProperty -Name 'SQLServer Name' -Value "$ServerName"
                $newObj | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Not Reachable'
            }
            Else
            {
                $newObj | Add-Member -MemberType NoteProperty -Name 'SQLServer Name' -Value "$ServerName"
                $newObj | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Not Reachable'
            }
            $InstanceStateObj += $newObj
        }
    }
    $xmlfileData = Add-Content -Value "</root>" -Path $xmlfile

    # Get the content from XML FIle
    $xmlDataFromOut = [xml](Get-Content $xmlfile)

    # Create a html for report generation
    $htmlFile = (New-Item -Path $CurrentDir -Name CheckSqlReport.html -ItemType File -Force -ErrorAction Stop).FullName

    # Set the Initial information on HTML Page
    $field1 = @"
    <fieldset><a name="top"></a><br><br>
    <b>Hi All,<br><br><b>This is an automated DBA Checklist Report for the following SQL servers as on <font color="#347C17">$(Get-date -Format 'MM/dd/yyy hh:mm:ss tt')</font>.Please click on the server name to see the report for that server.</b><br><br>
    <TABLE border="0"><TR><TH bgcolor="#B7CEEC">SQL servers</TH><TH bgcolor="#B7CEEC">Status</TH></TR>
"@

    # Append the server and instances statue information
    foreach ($server in $InstanceStateObj)
    {
        $lines = @"
            <TR>
            <TD bgcolor=`"#C2DFFF`"><a href=`"#$($server.'SQLServer Name')`">$($server.'SQLServer Name')</a></TD>
"@
        if($server.Status -eq 'Running')
        {
            $lines += @"
                <TD bgcolor="#C2DFFF"><font color="#347C17">$($server.Status)</font></TD></TR>
"@
        }
        else
        {
            $lines += @"
                <TD bgcolor="#C2DFFF"><font color="#FF0000">$($server.Status)</font></TD></TR>
"@
        }
        $field1 += $lines
    }
        $field1 += @"
            </TABLE><br><br></fieldset><br>
"@

    # Append the data to html file
    $htmlFileData = Add-Content -Value $field1 -Path $htmlFile

    # Add the style information to html
    $HeaderInfo = @"
        <?xml version="1.0" encoding="UTF-16"?>
        <HEAD><TITLE>Checklist for SQL Server</TITLE><style type="text/css">
        h3 {color:#2B60DE}
        TH {color:BLACK}
        h4 {color:#25587E}
        th {background:#B7CEEC}
        td {background:#C2DFFF}
        </style></HEAD>
"@
    $htmlFileData = Add-Content -Value $HeaderInfo -Path $htmlFile

    # Field for Overall Summary information on html page
    #                #<h4>Database Status Summary</h4>
    $field2 = @"
        <BODY>
        <fieldset>
            <fieldset style="text-align:left;">
                <legend><font color="#2B60DE"><h3><b>Overall Summary/issues</b></h3></font></legend>
"@

    $field2 += @"
    <br><h4>Database Status Summary</h4>
"@

    if($PingStatus.StatusCode -eq 0) # If the server is available only
    {
        $DBSummaryHtml = @"
            <TABLE border="0">
                <TR>
                    <TH bgcolor="#B7CEEC">Server</TH>
                    <TH bgcolor="#B7CEEC">Online</TH>
                    <TH bgcolor="#B7CEEC">Offline</TH>
                    <TH bgcolor="#B7CEEC">Total</TH>
                </TR>
"@
        # Get total db status from xml data
        $TotalDBStatus = $xmlDataFromOut.root.instance.totaldbstatus.sdb | Select -Property @{N='Server';E={$_.insName}},@{N='Online';E={$_.online}},@{N='Offline';E={$_.offline}},@{N='Total';E={$_.total}}

        foreach ($TotalDB in $TotalDBStatus)
        {
            $DBSummaryHtml +=@"
                <TR>
                    <TD bgcolor="#C2DFFF">$($TotalDB.Server)</TD>
                    <TD bgcolor="#C2DFFF"><font color="#347C17">$($TotalDB.online)</font></TD>
                    <TD bgcolor="#C2DFFF"><font color="#FF0000">$($TotalDB.offline)</font></TD>
                    <TD bgcolor="#C2DFFF"><b>$($TotalDB.total)</b></TD>
                </TR>
"@
        }
        $DBSummaryHtml += @"
        </TABLE>
"@
        $field2 += $DBSummaryHtml
        #$htmlFileData = Add-Content -Value $field2 -Path C:\Temp\CheckSqlReport.html
        $FailedScheduledJobs = $xmlDataFromOut.root.instance.failedJobs | Where-Object {$_.Chk -eq '1'}
        $InsFailedJobs =  $xmlDataFromOut.root.instance
        $FailedJobsList = $FailedScheduledJobs.fj
        
        if($FailedScheduledJobs)
        {
            $FailedScheduledJobs += @"
                <h4>Failed scheduled job(s)</h4>
                <TABLE border="0">
                    <TR>
                    <TH bgcolor="#B7CEEC">Server</TH>
                    <TH bgcolor="#B7CEEC">JobName</TH>
                    <TH bgcolor="#B7CEEC">Last Run Status</TH>
                    <TH bgcolor="#B7CEEC">Last Run Date</TH>
                    <TH bgcolor="#B7CEEC">Next Run Date</TH>
                    <TH bgcolor="#B7CEEC">Total Runs</TH>
                    <TH bgcolor="#B7CEEC">Success</TH>
                    <TH bgcolor="#B7CEEC">Failed</TH>
                    </TR>
"@
            #foreach ($FData in $InsFailedJobs)
            #{
                foreach($FJobs in $FailedJobsList)
                {
                    $FailedScheduledJobs += @"
                        <TR>
                            <TD bgcolor="#C2DFFF">$($FJobs.insName)</TD>
                            <TD bgcolor="#C2DFFF">$($FJobs.jobName)</TD>
                            <TD bgcolor="#C2DFFF"><font color="#FF0000">$($FJobs.lastRunStatus)</font></TD>
                            <TD bgcolor="#C2DFFF">$($FJobs.lastRunDate)</TD>
                            <TD bgcolor="#C2DFFF">$($FJobs.nextRunDate)</TD>
                            <TD bgcolor="#C2DFFF">$($FJobs.totalRuns)</TD>
                            <TD bgcolor="#C2DFFF">$($FJobs.success)</TD>
                            <TD bgcolor="#C2DFFF">$($FJobs.failed)</TD>
                        </TR>
"@
                }
            #}
            $FailedScheduledJobs += @"
                </TABLE>
"@
            $field2 += $FailedScheduledJobs
        }
        Else 
        {
            $field2 += @"
            <br><b>* All scheduled jobs on all servers executed and finished successfully without anyissues</b><br>
"@
        }
    }

    $field2 += @"
        <h4>Low free space database(s) \ file(s)</h4>
"@
    if($PingStatus.StatusCode -eq 0)
    {
        $lowdbfilesChk = $xmlDataFromOut.root.instance.lowDbSpace | Where-Object {$_.Chk -eq '1'}
        $lowdbfilesChkins = $lowdbfilesChk.lds

        if($lowdbfilesChk.Count -ne 0)
        {
            $lowdbfileschkhtml += @"
                    <TABLE border="0">
                    <TR>
                        <TH bgcolor="#B7CEEC">Server</TH>
                        <TH bgcolor="#B7CEEC">Database Name</TH>
                        <TH bgcolor="#B7CEEC">DB Type</TH>
                        <TH bgcolor="#B7CEEC">File Type</TH>
                        <TH bgcolor="#B7CEEC">File Name</TH>
                        <TH bgcolor="#B7CEEC">Total(MB)</TH>
                        <TH bgcolor="#B7CEEC">Free(%)</TH>
                        <TH bgcolor="#B7CEEC">Autogrow</TH>
                    </TR>
"@
                foreach($ldbss in $lowdbfilesChkins)
                {
                    $lowdbfileschkhtml += @"
                        <TR>
                            <TD bgcolor="#C2DFFF">$($ldbss.insName)</TD>
                            <TD bgcolor="#C2DFFF">$($ldbss.dbName)</TD>
                            <TD bgcolor="#C2DFFF">$($ldbss.type)</TD>
                            <TD bgcolor="#C2DFFF">$($ldbss.fileType)</TD>
                            <TD bgcolor="#C2DFFF">$($ldbss.fileName)</TD>
                            <TD bgcolor="#C2DFFF">$($ldbss.totalMB)</TD>
"@
                    if([decimal]$ldbss.freePct -ge 5)
                    {
                        $lowdbfileschkhtml += @"
                        <TD bgcolor="#C2DFFF"><font color="#347C17">$($ldbss.freePct)</font></TD>
"@
                    }
                    else
                    {
                        $lowdbfileschkhtml += @"
                        <TD bgcolor="#C2DFFF"><font color="#FF0000">$($ldbss.freePct)</font></TD>
"@
                    }
                    $lowdbfileschkhtml += @"
                            <TD bgcolor="#C2DFFF">$($ldbss.autogrow)</font></TD>
                        </TR>       
"@
                }
            $lowdbfileschkhtml += @"
                </TABLE>
                <br>
"@
            $field2 += $lowdbfileschkhtml
        }
        Else 
        {
            $field2 += @"
        <br> <b>* All databases have enough free space(>=5%)</b><br>
        <br>
"@
        }

        $LowDiskSpacesSummary = $xmlDataFromOut.root.instance.lowDiscSpace | ?{$_.Chk -eq '1'}
        if($LowDiskSpacesSummary.Count -eq 0)
        {
            $field2 += @"
        <br><b>$($xmlDataFromOut.root.instance.lowDiscSpace.msg)</b><br>
"@        
        }
        else
        {
            $LowDiskDetails = $xmlDataFromOut.root.instance.lowDiscSpace.ld

            $LowdiskDetailsHtml = @"
                    <TABLE border="0">
                    <TR>
                        <TH bgcolor="#B7CEEC">Server</TH>
                        <TH bgcolor="#B7CEEC">Drive Name</TH>
                        <TH bgcolor="#B7CEEC">Free Space(GB)</TH>
                    </TR>
"@         
            foreach($ldspace in $LowDiskDetails)
            {
                $LowdiskDetailsHtml += @"
                    <TR>
                    <TD bgcolor="#C2DFFF">$($ldspace.insName)</TD>
                    <TD bgcolor="#C2DFFF">$($ldspace.drive)</TD>
"@
                if($ldspace.freeSpaceGB -ge 2)
                {
                    $LowdiskDetailsHtml +=@"
                        <TD bgcolor="#C2DFFF"><font color="#347C17">$($ldspace.freeSpaceGB)</TD></TR>   
                        </TABLE>           
"@
                }
                else 
                {
                    $LowdiskDetailsHtml += @"
                        <TD bgcolor="#C2DFFF"><font color="#FF0000">$($ldspace.freeSpaceGB)</TD></TR>     
                        </TABLE>          
"@
                }
            }

            $field2 += $LowdiskDetailsHtml
        }  
        #$LowDBSummaryHtml =@"
        #<TABLE border="0">
        #            <TR>
        #                <TH bgcolor="#B7CEEC">Server</TH>
        ##                <TH bgcolor="#B7CEEC">Database Name</TH>
        #                <TH bgcolor="#B7CEEC">DB Type</TH>
        #                <TH bgcolor="#B7CEEC">File Type</TH>
        #                <TH bgcolor="#B7CEEC">File Name</TH>
        #                <TH bgcolor="#B7CEEC">Total(MB)</TH>
        #                <TH bgcolor="#B7CEEC">Free(%)</TH>
        #                <TH bgcolor="#B7CEEC">Autogrow</TH>
        #            </TR>
    #"#@
    #    $lowdbfiles = $xmlDataFromOut.root.instance.lowDbSpace.lds #| Select -Property @{N='Server';E={$_.insName}},@{N='Database Name';E={$_.dbName}},@{N='DB Type';E={$_.type}},@{N='File Type';E={$_.fileType}},@{N='File Name';E={$_.fileName}},@{N='Total(MB)';E={$_.totalMB}},@{N='Free (%)';E=#{$_.freePct}},@{N='Auto Grow';E={$_.autoGrow}}

    #   foreach ($lowdb in $lowdbfiles)
    #   {
    #       $LowDBSummaryHtml +=@"
    #               <TR>
    #                   <TD bgcolor="#C2DFFF">$($lowdb.insName)</TD>
    #                   <TD bgcolor="#C2DFFF">$($lowdb.dbName)</TD>
    #                   <TD bgcolor="#C2DFFF">$($lowdb.type)</TD>
    #                   <TD bgcolor="#C2DFFF">$($lowdb.fileType)</TD>
    #                   <TD bgcolor="#C2DFFF">$($lowdb.fileName)</TD>
    #                   <TD bgcolor="#C2DFFF">$($lowdb.totalMB)</TD>
    #"@
    #       if($lowdb.freePct -ge 5)
    #      {
    #         $LowDBSummaryHtml +=@"
    #                 <TD bgcolor="#C2DFFF"><font color="#347C17">$($lowdb.freePct)</font></TD>
    #"@
    #       }
    #       else
    #       {
    #          $LowDBSummaryHtml +=@"
    #                 <TD bgcolor="#C2DFFF"><font color="#FF0000">$($lowdb.freePct)</font></TD>
    #"@            
    #       }
    #      
    #      $LowDBSummaryHtml +=@"
    #                  <TD bgcolor="#C2DFFF">$($lowdb.autoGrow)</TD>
    #              </TR>
    #"@        
    #   }
    #   $LowDBSummaryHtml +=@"
    #   </TABLE>
    #"@
    #   $field2 += $LowDBSummaryHtml
        
    }

    $LowDiskSpace = $xmlDataFromOut.root.instance.lowDiscSpace
    $field2 += @"

            </fieldset><a href="#top" style="float:right">Go to Top</a>
        </fieldset>
        </BODY>
"@

    $htmlFileData = Add-Content -Value $field2 -Path $htmlFile

    $LoopVar = $InstanceStateObj | Where-Object {$_.Status -eq 'Running'}

    $InstancesData = $xmlDataFromOut.root.instance
    foreach($LoopVar in $InstancesData)
    {
        $FCode = @"
            <?xml version="1.0" encoding="UTF-16"?>
            <HEAD>
            <TITLE>Checklist for SQL Server</TITLE>
            <style type="text/css">
            h3 {color:#2B60DE}
            TH {color:BLACK}
            h4 {color:#25587E}    
            th {background:#B7CEEC}
            td {background:#C2DFFF}
            </style></HEAD>
            <BODY>
            <fieldset>
                <fieldset style="text-align:center;"><a name=`"$($LoopVar.name)`"><h2>Database Checklist for <font color="#566D7E">$($LoopVar.name)</font> as on <font color="#566D7E">$($LoopVar.date)</font></h2></a><h4>SQL Server Uptime: <font color="#347C17">$($LoopVar.uptime.time)</font></h4></fieldset>
                <fieldset style="text-align:left;"><legend><font color="black"><h3><b>Summary/issues</b></h3></font></legend>
                
"@
         #<h4>Database Status Summary</h4>  
        $VerRes = Get-SQLResIns -SQLIns $($LoopVar.name) -Query $SQLVersionQuery
        $VerRes = $VerRes | Select -Property @{N='Server Attribute';E={$_.ColumnName}},@{N='Value';E={$_.ColumnValue}} | ConvertTo-Html -Fragment
        $FCode += @"
        <h4>SQL Server Information</h4>
        $VerRes
        <h4>Database Status Summary</h4> 
"@ 
        $DBStatusSummaryHtml = @"
                <TABLE border="0">
                        <TR>
                            <TH bgcolor="#B7CEEC">Status</TH>
                            <TH bgcolor="#B7CEEC">Count</TH>
                        </TR>
"@
        $DBStatusSummary = $LoopVar.dbsummary.sdb #| Select -Property @{N='Status';E={$_.status}},@{N='Count';E={$_.count}}

        foreach($Dbs in $DBStatusSummary)
        {
            if($Dbs.status -eq 'ONLINE')
            {
                $DBStatusSummaryHtml += @"
                        <TR>
                            <TD bgcolor="#C2DFFF">$($Dbs.status)</TD>
                            <TD bgcolor="#C2DFFF"><font color="#347C17">$($Dbs.count)</font></TD>
                        </TR>
"@
            }
            elseif($Dbs.status -eq 'OFFLINE') 
            {
                $DBStatusSummaryHtml += @"
                        <TR>
                            <TD bgcolor="#C2DFFF">$($Dbs.status)</TD>
                            <TD bgcolor="#C2DFFF"><font color="#FF0000">$($Dbs.count)</font></TD>
                        </TR>
"@ 
            }
            else 
            {
                $DBStatusSummaryHtml += @"
                        <TR>
                            <TD bgcolor="#C2DFFF">$($Dbs.status)</TD>
                            <TD bgcolor="#C2DFFF">$($Dbs.count)</font></TD>
                        </TR>
"@ 
            }
        }

        $DBStatusSummaryHtml += @"
            </TABLE><br>
"@     
        $FCode += $DBStatusSummaryHtml

        $FailedIntanceScheJobs = $LoopVar.failedJobs
        if($FailedIntanceScheJobs.Chk -eq 0)
        {
            if($FailedIntanceScheJobs.error)
            {
                $FCode += @"
                <font color="#FF0000">$($FailedIntanceScheJobs.error)</font>
"@
            }
            else 
            {
                $FCode += @"
                <b><font color="BLACK">$($FailedIntanceScheJobs.msg)</font></b>
"@            
            }
        }
        Elseif($FailedIntanceScheJobs.Chk -eq 1) 
        {
            $FailedJobSummaryHtml =@"
            <TABLE border="0">
                <TR>
                <TH bgcolor="#B7CEEC">JobName</TH>
                <TH bgcolor="#B7CEEC">Last Run Status</TH>
                <TH bgcolor="#B7CEEC">Last Run Date</TH>
                <TH bgcolor="#B7CEEC">Next Run Date</TH>
                <TH bgcolor="#B7CEEC">Total Runs</TH>
                <TH bgcolor="#B7CEEC">Success</TH>
                <TH bgcolor="#B7CEEC">Failed</TH>
                </TR>
"@
            foreach($FJob in $FailedIntanceScheJobs)
            {
                $FailedJobSummaryHtml += @"
                        <TR>
                            <TD bgcolor="#C2DFFF">$($FJob.jobName)</TD>
                            <TD bgcolor="#C2DFFF"><font color="#FF0000">$($FJob.lastRunStatus)</TD>
                            <TD bgcolor="#C2DFFF">$($FJob.lastRunDate)</TD>
                            <TD bgcolor="#C2DFFF">$($FJob.nextRunDate)</TD>
                            <TD bgcolor="#C2DFFF">$($FJob.totalRuns)</TD>
                            <TD bgcolor="#C2DFFF">$($FJob.success)</TD>
                            <TD bgcolor="#C2DFFF">$($FJob.failed)</TD>
                        </TR>
"@
            }
        }else{}

        $RAMInfo = Get-SQLResIns -SQLIns $($LoopVar.name) -Query $RAMQuery
        $RAMInfo = $RAMInfo | Select -Property @{N='DB Name';E={$_.db_name}},@{N='Buffer Pages';E={$_.db_buffer_pages}},@{N='DB Buffer(MB)';E={$_.db_buffer_mb}},@{N='DB Buffer %';E={$_.db_buffer_percent}} | ConvertTo-Html -Fragment

        $FCode += @"
        <br><h4> Database RAM Information </h4>
        $RAMInfo
"@

        $FCode += @"
            <h4>Low free space database(s) \ file(s)</h4>
"@
            
        $DBlowFreeSummaryhtml =@"
                <TABLE border="0">
                        <TR>
                            <TH bgcolor="#B7CEEC">Database Name</TH>
                            <TH bgcolor="#B7CEEC">DB Type</TH>
                            <TH bgcolor="#B7CEEC">File Type</TH>
                            <TH bgcolor="#B7CEEC">File Name</TH>
                            <TH bgcolor="#B7CEEC">Total(MB)</TH>
                            <TH bgcolor="#B7CEEC">Free(%)</TH>
                            <TH bgcolor="#B7CEEC">Autogrow</TH>
                        </TR>
"@
        $DBLowFreeDBFiles = $LoopVar.lowDbSpace.lds #| Select -Property @{N='Server';E={$_.insName}},@{N='Database Name';E={$_.dbName}},@{N='File Type';E={$_.fileType}},@{N='File Name';E={$_.fileName}},@{N='Total(MB)';E={$_.totalMB}},@{N='Free (%)';E={$_.freePct}},@{N='Auto Grow';E={$_.autoGrow}} | ConvertTo-Html -Fragment
        foreach($DBLow in $DBLowFreeDBFiles)
        {
            $DBlowFreeSummaryhtml += @"
                        <TR>
                            <TD bgcolor="#C2DFFF">$($DBLow.dbName)</TD>
                            <TD bgcolor="#C2DFFF">$($DBLow.type)</TD>
                            <TD bgcolor="#C2DFFF">$($DBLow.fileType)</TD>
                            <TD bgcolor="#C2DFFF">$($DBLow.fileName)</TD>
                            <TD bgcolor="#C2DFFF">$($DBLow.totalMB)</TD>
"@

            if($DBLow.freePct -gt 5)
            {
                $DBlowFreeSummaryhtml += @"
                            <TD bgcolor="#C2DFFF"><font color="#347C17">$($DBLow.freePct)</font></TD>
"@
            }
            else 
            {
                $DBlowFreeSummaryhtml += @"
                            <TD bgcolor="#C2DFFF"><font color="#FF0000">$($DBLow.freePct)</font></TD>
"@            
            }
            $DBlowFreeSummaryhtml += @"
                            <TD bgcolor="#C2DFFF">$($DBLow.autoGrow)</TD></TR>
"@
        }
        $DBlowFreeSummaryhtml += @"
                </TABLE>
"@
        $FCode += $DBlowFreeSummaryhtml

        $DiskSpaceMsg = $LoopVar.lowDiscSpace
        if($DiskSpaceMsg.Chk -eq 0)
        {
            $FCode += @"
        <br><b>$($DiskSpaceMsg.msg)</b><br>
"@        
        }

        $FCode += @"
            </fieldset>
            <fieldset style="text-align:left;"><legend><font color="black"><h3><b>Detailed Checklist</b></h3></font></legend><h4>SQL Server Services Status</h4>
"@

        $SQLServerServiceStatushtml = @"
                        <TABLE border="0">
                        <TR>
                            <TH bgcolor="#B7CEEC">Service</TH>
                            <TH bgcolor="#B7CEEC">Type</TH>
                            <TH bgcolor="#B7CEEC">Status</TH>
                        </TR>
"@
        $SQLServerServiceStatus = $LoopVar.Services.st #| Select -Property @{N='Service';E={$_.serviceName}},@{N='Type';E={$_.type}},@{N='Status';E={$_.status}} | ConvertTo-Html -Fragment

        foreach($SQLSer in $SQLServerServiceStatus)
        {
            $SQLServerServiceStatushtml += @"
                                <TR>
                            <TD bgcolor="#C2DFFF">$($SQLSer.serviceName)</TD>
                            <TD bgcolor="#C2DFFF">$($SQLSer.type)</TD>
"@
            if($SQLSer.status -eq 'Running')
            {
                $SQLServerServiceStatushtml += @"
                            <TD bgcolor="#C2DFFF"><font color="#347C17">$($SQLSer.status)</TD></TR>
"@
            }
            else 
            {
                $SQLServerServiceStatushtml += @"
                            <TD bgcolor="#C2DFFF"><font color="#FF0000">$($SQLSer.status)</TD></TR>
"@
            }
        }
        $SQLServerServiceStatushtml += @"
                    </TABLE>
"@

        $FCode += $SQLServerServiceStatushtml
        $FCode +=@"
            <h4>Database Status</h4>
"@

        $DBStatusBkpHtml = @"
                    <TABLE border="0">
                    <TR>
                        <TH bgcolor="#B7CEEC">Database Name</TH>
                        <TH bgcolor="#B7CEEC">DB Type</TH>
                        <TH bgcolor="#B7CEEC">Recovery Model</TH>
                        <TH bgcolor="#B7CEEC">Status</TH>
                        <TH bgcolor="#B7CEEC">Last Full Backup</TH>
                        <TH bgcolor="#B7CEEC">Last Log Backup</TH>
                    </TR>
"@
        $DBStatusBkp = $LoopVar.backupCheck.bc #| Select -Property @{N='Database Name';E={$_.databaseName}},@{N='DB Type';E={$_.type}},@{N='Recovery Model';E={$_.recoveryMode}},@{N='Status';E={$_.status}},@{N='Last Full Backup';E={$_.lastFullBackup}},@{N='Last Log Backup';E={$_.lastLogBackup}} | ConvertTo-Html -Fragment

        foreach($DBBkp in $DBStatusBkp)
        {
            $DBStatusBkpHtml += @"
                    <TR>
                        <TD bgcolor="#C2DFFF">$($DBBkp.databaseName)</TD>
                        <TD bgcolor="#C2DFFF">$($DBBkp.type)</TD>
                        <TD bgcolor="#C2DFFF">$($DBBkp.recoveryMode)</TD>
"@

            if($DBBkp.status -eq "ONLINE")
            {
                $DBStatusBkpHtml += @"
                        <TD bgcolor="#C2DFFF"><font color="#347C17">$($DBBkp.status)</TD>
"@
            }
            else 
            {
                $DBStatusBkpHtml += @"
                        <TD bgcolor="#C2DFFF"><font color="#FF0000">$($DBBkp.status)</TD>
"@            
            }
            
            $DBStatusBkpHtml += @"
                        <TD bgcolor="#C2DFFF">$($DBBkp.lastFullBackup)</TD>
                        <TD bgcolor="#C2DFFF">$($DBBkp.lastLogBackup)</TD>
                    </TR>
"@
        }

        $DBStatusBkpHtml += @"
        </TABLE>
"@

        $FCode += $DBStatusBkpHtml

        $FCode += @"
            <h4>Database Files Status</h4>
"@

        # Database full status report 
        $DBStatusFullHtml = @"
                        <TABLE border="0">
                        <TR>
                            <TH bgcolor="#B7CEEC">Database Name</TH>
                            <TH bgcolor="#B7CEEC">DB Type</TH>
                            <TH bgcolor="#B7CEEC">File Type</TH>
                            <TH bgcolor="#B7CEEC">File Name</TH>
                            <TH bgcolor="#B7CEEC">Total(MB)</TH>
                            <TH bgcolor="#B7CEEC">Used(MB)</TH>
                            <TH bgcolor="#B7CEEC">Free(MB)</TH>
                            <TH bgcolor="#B7CEEC">Used(%)</TH>
                            <TH bgcolor="#B7CEEC">Free(%)</TH>
                            <TH bgcolor="#B7CEEC">Autogrow</TH>
                        </TR>
"@

        $DBStatusFull = $LoopVar.dbFileStatus.dfs #| Select -Property @{N='Database Name';E={$_.dbName}},@{N='DB Type';E={$_.type}},@{N='File Type';E={$_.fileType}},@{N='File Name';E={$_.fileName}},@{N='Total(MB)';E={$_.totalMB}},@{N='Used(MB)';E={$_.usedMB}},@{N='Free(MB)';E={$_.freeMB}},@{N='Used(%)';E={$_.usedPct}},@{N='Free(%)';E={$_.freePct}},@{N='Autogrow';E={$_.autoGrow}} | ConvertTo-Html -Fragment

        foreach($DBFullStat in $DBStatusFull)
        {
            $DBStatusFullHtml += @"
                        <TR>
                            <TD bgcolor="#C2DFFF">$($DBFullStat.dbName)</TD>
                            <TD bgcolor="#C2DFFF">$($DBFullStat.type)</TD>
                            <TD bgcolor="#C2DFFF">$($DBFullStat.fileType)</TD>
                            <TD bgcolor="#C2DFFF">$($DBFullStat.fileName)</TD>
                            <TD bgcolor="#C2DFFF">$($DBFullStat.totalMB)</TD>
                            <TD bgcolor="#C2DFFF">$($DBFullStat.usedMB)</TD>
                            <TD bgcolor="#C2DFFF">$($DBFullStat.freeMB)</TD>
                            <TD bgcolor="#C2DFFF">$($DBFullStat.usedPct)</TD>
"@
            if([decimal]$DBFullStat.freePct -ge 5)
            {
                $DBStatusFullHtml += @"
                            <TD bgcolor="#C2DFFF"><font color="#347C17">$($DBFullStat.freePct)</font></TD>
"@
            }
            Else 
            {
                $DBStatusFullHtml += @"
                            <TD bgcolor="#C2DFFF"><font color="#FF0000">$($DBFullStat.freePct)</font></TD>
"@            
            }                        
            $DBStatusFullHtml += @"
                <TD bgcolor="#C2DFFF">$($DBFullStat.autogrow)</TD></TR>
"@
        }
        $DBStatusFullHtml += @"
                </TABLE>
"@    
        $FCode += $DBStatusFullHtml

        $FCode += @"
            <h4>Jobs Status</h4>
"@

        $JobstatusHtml = @"
                <TABLE border="0">
                    <TR>
                        <TH bgcolor="#B7CEEC">JobName</TH>
                        <TH bgcolor="#B7CEEC">Last Run Status</TH>
                        <TH bgcolor="#B7CEEC">Last Run Date</TH>
                        <TH bgcolor="#B7CEEC">Next Run Date</TH>
                        <TH bgcolor="#B7CEEC">Total Runs</TH>
                        <TH bgcolor="#B7CEEC">Success</TH>
                        <TH bgcolor="#B7CEEC">Failed</TH>
                    </TR>
"@
        $Jobstatus = $LoopVar.jobStatus #| Select -Property @{N='Job Name';E={$_.databaseName}},@{N='Last Run Status';E={$_.type}},@{N='Last Run Date';E={$_.fileType}},@{N='Next Run Date' | ConvertTo-Html -Fragment
        $JobsInfo = $LoopVar.jobStatus.js

        if($Jobstatus.error)
        {
            $JobstatusHtml += @"
            </TABLE>
            <font color="#FF0000">$($Jobstatus.error)</font>
"@
        }
        elseif($Jobstatus.msg) 
        {
            
        }
        else 
        {
            foreach($Job in $JobsInfo)
            {
                $JobstatusHtml += @"
                        <TR>
                            <TD bgcolor="#C2DFFF">$($Job.jobName)</TD>
"@
                if($Job.lastRunStatus -eq "SUCCESS")
                {
                    $JobstatusHtml += @"
                            <TD bgcolor="#C2DFFF"><font color="#347C17">$($Job.lastRunStatus)</TD>
"@
                }
                else 
                {
                    $JobstatusHtml += @"
                            <TD bgcolor="#C2DFFF"><font color="#FF0000">$($Job.lastRunStatus)</TD>
"@                
                }

                $JobstatusHtml += @"
                            <TD bgcolor="#C2DFFF">$($Job.lastRunDate)</TD>
                            <TD bgcolor="#C2DFFF">$($Job.nextRunDate)</TD>
                            <TD bgcolor="#C2DFFF">$($Job.totalRuns)</TD>
                            <TD bgcolor="#C2DFFF">$($Job.success)</TD>
                            <TD bgcolor="#C2DFFF">$($Job.failed)</TD>
                        </TR>
"@            
            }
            $JobstatusHtml += @"
            </TABLE>
"@
        }
        $FCode += $JobstatusHtml

        $FCode += @"
            <h4>Drive Details</h4>
"@

        $DriveDetailsHtml = @"
            <TABLE border="0">
                    <TR>
                        <TH bgcolor="#B7CEEC">Drive Name</TH>
                        <TH bgcolor="#B7CEEC">Free Space(GB)</TH>
                    </TR>
"@
        $DriveDetails = $LoopVar.discSpace.ds #| Select -Property @{N='Drive Name';E={$_.drive}},@{N='Free Space(GB)';E={$_.freeSpaceGB}} | ConvertTo-Html -Fragment

        foreach($DDetails in $DriveDetails)
        {
            $DriveDetailsHtml += @"
                    <TR>
                        <TD bgcolor="#C2DFFF">$($DDetails.drive)</TD>
"@
            if([decimal]($DDetails.freeSpaceGB) -ge 2)
            {
                $DriveDetailsHtml += @"
                        <TD bgcolor="#C2DFFF"><font color="#347C17">$($DDetails.freeSpaceGB)</TD></TR>
"@
            }
            else 
            {
                $DriveDetailsHtml += @"
                        <TD bgcolor="#C2DFFF"><font color="#FF0000">$($DDetails.freeSpaceGB)</TD></TR>
"@            
            }
        }
        $DriveDetailsHtml += @"
        </TABLE>
"@
        $FCode += $DriveDetailsHtml

        $LastRunStatus = Get-SQLResIns -SQLIns $($LoopVar.name) -Query $LastRunCode
        $LastRunStatus = $LastRunStatus | Select @{N='Database Name';E={$_.DatabaseName}},@{N='Last Run Date';E={([datetime]$_.dbccLastrundate).ToUniversalTime()}} | ConvertTo-Html -Fragment

        if($LastRunStatus -ne $null)
        {
            $FCode += @"
            <br><h4> Last Run Status </h4>
            $LastRunStatus 
"@
        }
        $FCode += @"
            </fieldset><a href="#top" style="float:right">Go to Top</a></fieldset></BODY>
"@

        $htmlFileData = Add-Content -Value $FCode -Path $htmlFile
    }
    $LastLine = Add-Content -Value "<hr color=`"#000000`"><br>Thanks,<br>NetEnrich.<br>" -Path $htmlFile 

    # Remove the temporary files 
    Remove-Item -Path "$CurrentDir\sqlquery.txt" -Force
    Remove-Item -Path $xmlfile -Force
}
catch 
{
    # Create a html for report generation
    $htmlFile = New-Item -Path $CurrentDir -Name CheckSqlReport.html -ItemType File -Force
    $ErrorData = @"
        <HEAD><TITLE>Checklist for SQL Server</TITLE><style type="text/css">
        h3 {color:#2B60DE}
        TH {color:BLACK}
        h4 {color:#25587E}
        th {background:#B7CEEC}
        td {background:#C2DFFF}
        </style></HEAD>
		<Body>
			<fieldset>
			<b>Hi All,
			<br><br>Exception occured during the script execution. Below is the error information.</b>
			<br>
			<br>
			<font color='red'>Error Message: $($Error[0].Exception.Message)</font>
            <br>
            <font color='red'>Line: $($Error[0].InvocationInfo.Line)</font>
            <br>
            <font color='red'>Line Number: $($Error[0].InvocationInfo.ScriptLineNumber)</font>
		</Body>
"@
    $data = Set-Content -Value $ErrorData -Path $htmlFile
}




