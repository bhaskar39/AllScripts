
## ---------- Working with SQL Server ---------- ##
 
## - Get SQL Server Table data:

Try
{

    $ErrorActionPreference = "Stop"

    $SQLServer = 'localhost'
    $Database = $args[0]

    $SqlQuery = @'
/*Auto fix fragmentation above 5% and performs log backup for every index operation*/
SET NOCOUNT ON;

DECLARE @objectid int;

DECLARE @IndexType Varchar(20);

DECLARE @indexid int;

DECLARE @partitioncount bigint;

DECLARE @schemaname nvarchar(130);

DECLARE @objectname nvarchar(130);

DECLARE @indexname nvarchar(130);

DECLARE @partitionnum bigint;

DECLARE @partitions bigint;

DECLARE @frag float;

DECLARE @command nvarchar(4000);


DECLARE @dbid smallint;

DECLARE @Dbname Varchar(100);

DECLARE @Backuplog Varchar(Max);

DECLARE @Path Varchar(Max);

DECLARE @BackupDirectory NVARCHAR(100)   

DECLARE @filedate Varchar(100);

DECLARE @edition Varchar(200);

DECLARE @Backuplog1 Varchar(Max);

DECLARE @model Varchar(20);


EXEC master..xp_instance_regread @rootkey = 'HKEY_LOCAL_MACHINE',  
    @key = 'Software\Microsoft\MSSQLServer\MSSQLServer',  
    @value_name = 'BackupDirectory', @BackupDirectory = @BackupDirectory OUTPUT ;-- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function
 Set @path=@BackupDirectory
-- and convert object and index IDs to names.

SET @dbid = DB_ID();
SET @dbname=(SELECT DB_NAME() AS DataBaseName);
SET @filedate =  CONVERT(VARCHAR(20),GETDATE(),112); 
SET @edition=Convert(Varchar(50),SERVERPROPERTY('Edition'));
SET @model=(Convert(Varchar(20),DATABASEPROPERTYEX((SELECT DB_NAME() AS DataBaseName), 'Recovery')));
--Set @Version=Convert(Varchar(20),ServerProperty ('Productversion'))
SELECT

    [object_id] AS objectid,

 Index_type_desc as indextype,

    index_id AS indexid,

    partition_number AS partitionnum,

    avg_fragmentation_in_percent AS frag, page_count

INTO #work_to_do

FROM sys.dm_db_index_physical_stats (@dbid, NULL, NULL , NULL, N'LIMITED')

WHERE avg_fragmentation_in_percent > 5.0  -- Allow limited fragmentation

AND index_id > 0 -- Ignore heaps

AND page_count > 25; -- Ignore small tables

-- Declare the cursor for the list of partitions to be processed.

DECLARE partitions CURSOR FOR SELECT objectid,Indextype,indexid, partitionnum,frag FROM #work_to_do;

-- Open the cursor.

OPEN partitions;

-- Loop through the partitions.

WHILE (1=1)

BEGIN

FETCH NEXT

FROM partitions

INTO @objectid, @indextype,@indexid, @partitionnum, @frag;

IF @@FETCH_STATUS < 0 BREAK;

SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name)

FROM sys.objects AS o

JOIN sys.schemas as s ON s.schema_id = o.schema_id

WHERE o.object_id = @objectid;

SELECT @indexname = QUOTENAME(name)

FROM sys.indexes

WHERE object_id = @objectid AND index_id = @indexid;

SELECT @partitioncount = count (*)

FROM sys.partitions

WHERE object_id = @objectid AND index_id = @indexid;

-- 30 is an arbitrary decision point at which to switch between reorganizing and rebuilding.

IF @frag < 30.0
SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';


IF @frag >= 30.0 
SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD ';

Set @Backuplog1='backup Log ' +'['+ @dbname+']' + ' to disk = ' + '''' + @BackupDirectory + '\' + @dbname  + @filedate+'.Trn'+''''

Set @Backuplog='backup Log ' +'['+@dbname+']' + ' to disk = ' + '''' + @BackupDirectory + '\' + @dbname  + @filedate+'.Trn'+ '''with COMPRESSION'


IF @partitioncount > 1
SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));


--If (@edition like '%Enterprise Edition (64-bit)') and (@IndexType like '%CLUSTERED INDEX' or @IndexType Like '%NONCLUSTERED INDEX')
--Print @command+' with (Online=On)'
--else
Print (@command);
Exec (@command);

If @Edition not like 'Express%' and (@model like 'FULL%' or @model Like 'BULK_LOGGED%')
Exec (@backuplog);

ELSE

If @model like 'FULL%' or @model Like 'BULK_LOGGED%'
Exec (@backuplog1);


END

-- Close and deallocate the cursor.

CLOSE partitions;

DEALLOCATE partitions;

-- Drop the temporary table.

DROP TABLE #work_to_do;

'@
 
## - Connect to SQL Server using non-SMO class 'System.Data':
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server = $SQLServer;Database=$Database; Integrated Security = True"
    #$SqlConnection.ConnectionString = "Server = $SQLServer;uid=sa;pwd=Pass@123;Integrated Security = False"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $SqlQuery
    $SqlCmd.Connection = $SqlConnection

    ## - Extract and build the SQL data object '$DataSetTable'
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $Sqlconnection.FireInfoMessageEventOnUserErrors=$true

    $res = New-Object System.Collections.ArrayList
    #...
    #$handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-Host "$($_)"}
    $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] { $res.Add("$($_)")}
    $Sqlconnection.add_InfoMessage($handler)
    $SqlConnection.Open()
    $result = $SqlCmd.ExecuteNonQuery()

    if($res -ne $null)
    {
        Write-Host $res
        <#$NewArrayObj = New-Object System.Collections.ArrayList
        foreach($a in $res)
        {
            if(($a -eq 'go') -and ($a))
            {
                Continue
            }
            else
            {
                $Obj = New-Object psobject
                $db = ($a.Split('[')).Split(']')[1]
                $diskpath = $a.split("=")[1].trim()

                $obj | Add-Member -MemberType NoteProperty -Name "Database Name" -Value $db
                $Obj | Add-Member -MemberType NoteProperty -Name "Disk Path" -Value $diskpath
            }
            $NewArrayObj += $Obj
        }
        #>
        $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
        #$ParentFolder = $CurrentDir.Substring(0,$CurrentDir.LastIndexOf("\"))

        if(Test-Path "$PSScriptRoot\..\Output")
        {
            # skip
        }
        Else
        {
            $data = (New-Item -Path "$PSScriptRoot\..\" -Name Output -ItemType Directory -Force -ErrorAction Stop).FullName
        }

        $BackUpdbs = "$PSScriptRoot\..\Output\Automated_fix.txt"

        $res | Out-File $BackUpdbs -Force

    }
    else
    {
        Write-Output "Script has been executed successfully"
    }
    $SqlConnection.Close()
}
catch
{
    $Error[0].exception.Message
}
 
## - End of Script - ##