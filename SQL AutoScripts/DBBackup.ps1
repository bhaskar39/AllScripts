
## ---------- Working with SQL Server ---------- ##
 
## - Get SQL Server Table data:

Try
{

    $SQLServer = 'localhost'

    $SqlQuery = @'
Declare @dbname varchar(60)
Declare @backuptype varchar(30)
Declare @filedate varchar(20)
Declare @fullpath varchar(200)
Declare @diffpath varchar(200)
Declare @sqlstmt varchar(2000)
Declare @model varchar(20)
--create table #failedbackups(dbname varchar(60),backuptype varchar(30))
DECLARE @BackupDirectory NVARCHAR(100)   
EXEC master..xp_instance_regread @rootkey = 'HKEY_LOCAL_MACHINE',  
    @key = 'Software\Microsoft\MSSQLServer\MSSQLServer',  
    @value_name = 'BackupDirectory', @BackupDirectory = @BackupDirectory OUTPUT ;  
 
--SELECT @BackupDirectory AS [SQL Server default backup Value]
Set @fullpath=@BackupDirectory
--set @diffpath=@BackupDirectory

Select @filedate =  CONVERT(VARCHAR(20),GETDATE(),112) 
Declare cur_backup cursor
for
(SELECT 
   --CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   msdb.dbo.backupset.database_name,msdb.dbo.backupset.type,recovery_model_desc
   --MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date 
   --DATEDIFF(hh, MAX(msdb.dbo.backupset.backup_finish_date), GETDATE()) AS [Backup Age (Hours)] 
FROM    msdb.dbo.backupset 
join sys.databases on sys.databases.name=msdb.dbo.backupset.database_name
WHERE   sys.databases.state=0 and  msdb.dbo.backupset.type = 'D'  or  msdb.dbo.backupset.type = 'L'
--or  msdb.dbo.backupset.type = 'I' ---Enable this if Differential backup is required
GROUP BY msdb.dbo.backupset.database_name,msdb.dbo.backupset.type,recovery_model_desc
HAVING      (MAX(msdb.dbo.backupset.backup_finish_date) < DATEADD(hh, - 24, GETDATE())) --Change the no.of hours as per requirement

UNION  

--Databases without any backup history 
SELECT      
   --CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,  
   sys.databases.NAME AS database_name,msdb.dbo.backupset.type,recovery_model_desc
   --NULL AS [Last Data Backup Date]  
   --9999 AS [Backup Age (Hours)]  
FROM 
   sys.databases LEFT JOIN msdb.dbo.backupset 
       ON sys.databases.name  = msdb.dbo.backupset.database_name 
WHERE msdb.dbo.backupset.database_name IS NULL AND sys.databases.name <> 'tempdb' AND sys.databases.state=0)

open cur_backup
fetch next from cur_backup into @dbname,@backuptype,@model
while @@FETCH_STATUS=0
begin
if @backuptype ='D'--Full backup
begin 
     
                set @sqlstmt =  'backup database ' + '['+@dbname+ ']'+ ' to disk = ' + '''' + @BackupDirectory  + '\' + @dbname+'_'+ @filedate +'.bak'+ '''-- with COMPRESSION'--Enable Compression if needed
                exec (@sqlstmt)
                print @sqlstmt
                print'go'
               
end

if @backuptype is NULL--DB with no backups
begin 
set @sqlstmt =  'backup database ' + '['+@dbname+ ']'+ ' to disk = ' + '''' + @BackupDirectory  + '\' + @dbname+'_'+ @filedate +'.bak'+ '''-- with COMPRESSION'--Enable Compression if needed
                exec (@sqlstmt)
                print @sqlstmt
                print'go'

end

if @backuptype='L' and @model='FULL'--Log backup
begin 
set @sqlstmt =  'backup Log ' +'['+@dbname+']' + ' to disk = ' + '''' + @BackupDirectory + '\' + @dbname  + @filedate+'.Trn'+ '''-- with COMPRESSION'--Enable Compression if needed
                exec (@sqlstmt)
                print @sqlstmt
                print'go'
                
end


fetch next from cur_backup  into @dbname,@backuptype,@model
end
close cur_backup
deallocate cur_backup


'@
 
## - Connect to SQL Server using non-SMO class 'System.Data':
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server = $SQLServer; Integrated Security = True"
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
        Write-Output "Success"
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

        $BackUpdbs = "$PSScriptRoot\..\Output\BackUpdbs.txt"

        $NewArrayObj | Out-File $BackUpdbs -Force

    }
    else
    {
        Write-Output "The query did not return anything"
    }

}
catch
{
    $Error[0].exception.Message
}
 
## - End of Script - ##