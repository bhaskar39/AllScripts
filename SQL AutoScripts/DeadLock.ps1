
## ---------- Working with SQL Server ---------- ##
 
## - Get SQL Server Table data:

Try
{

    $SQLServer = 'localhost'

    $SqlQuery = @'
WITH events_cte AS (
  SELECT
    xevents.event_data,
    DATEADD(mi,
    DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
    xevents.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS [event time] ,
    xevents.event_data.value(
      '(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(128)')
      AS [client app name],
    xevents.event_data.value(
      '(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(max)')
      AS [client host name],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="database_name"]/value)[1]', 'nvarchar(max)')
      AS [database name],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="database_id"]/value)[1]', 'int')
      AS [database_id],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="object_id"]/value)[1]', 'int')
      AS [object_id],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="index_id"]/value)[1]', 'int')
      AS [index_id],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="duration"]/value)[1]', 'bigint') / 1000
      AS [duration (ms)],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="lock_mode"]/text)[1]', 'varchar')
      AS [lock_mode],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="login_sid"]/value)[1]', 'int')
      AS [login_sid],
    xevents.event_data.query(
      '(event[@name="blocked_process_report"]/data[@name="blocked_process"]/value/blocked-process-report)[1]')
      AS blocked_process_report,
    xevents.event_data.query(
      '(event/data[@name="xml_report"]/value/deadlock)[1]')
      AS deadlock_graph
  FROM    sys.fn_xe_file_target_read_file
    ('C:\Program Files\Microsoft SQL Server\blocked_process*.xel',
     'C:\Program Files\Microsoft SQL Server\blocked_process*.xem',
     null, null)
    CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as xevents
)
SELECT
  CASE WHEN blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NULL
       THEN 'Deadlock'
       ELSE 'Blocked Process'
       END AS ReportType,
  --[event time],
  --CASE [client app name] WHEN '' THEN ' -- N/A -- '
    --                     ELSE [client app name]
      --                   END AS [client app _name],
  --CASE [client host name] WHEN '' THEN ' -- N/A -- '
    --                      ELSE [client host name]
      --                    END AS [client host name],
  --[database name],
  --COALESCE(OBJECT_SCHEMA_NAME(object_id, database_id), ' -- N/A -- ') AS [schema],
  --COALESCE(OBJECT_NAME(object_id, database_id), ' -- N/A -- ') AS [table],
  --index_id,
  --[duration (ms)],
  --lock_mode,
  --COALESCE(SUSER_NAME(login_sid), ' -- N/A -- ') AS username,
  CASE WHEN blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NULL
       THEN deadlock_graph
       ELSE blocked_process_report
       END AS Report
FROM events_cte
where [event time]>DATEADD(MINUTE, - 15, GETDATE())----get result only for 15 Minutes
ORDER BY [event time] DESC

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
    $DataSet = New-Object System.Data.DataSet
    $data = $SqlAdapter.Fill($DataSet)
    $DataSetTable = $DataSet.Tables["Table"]
    ## ---------- Working with Excel ---------- ##

    if($DataSetTable -ne $null)
    {
        $DataSetTable1 = $DataSetTable.rows
        #$outdata = $DataSetTable1 | fl
        #write-output $outdata

        $DeadLock = $DataSetTable1 | Where-Object {$_.ReportType -eq "Deadlock"}

        if($DeadLock -ne $null)
        {
            $DeadLockXml = $DeadLock.Report

            Write-Output $DeadLockXml
            #$victim = $DeadLock.'deadlock-list'.deadlock.victim
            #Write-Output $victim

            #$DeadLockProcesses = $DeadLockXml.deadlock.'process-list'.'process'
            #$OutputData = $DeadLockProcesses | fl
            #Write-Output $OutputData
        }
        else
        {
            Write-Output "No Deadlock processes found"
        }
        <#
        ## - Create an Excel Application instance:
        $xlsObj = New-Object -ComObject Excel.Application
 
        ## - Create new Workbook and Sheet (Visible = 1 / 0 not visible)
        $xlsObj.Visible = 0
        $xlsWb = $xlsobj.Workbooks.Add()
        $xlsSh = $xlsWb.Worksheets.item(1)
 
        ## - Build the Excel column heading:
        [Array] $getColumnNames = $DataSetTable.Columns | Select ColumnName
 
        ## - Build column header:
        [Int] $RowHeader = 1
        foreach ($ColH in $getColumnNames)
        {
            $xlsSh.Cells.item(1, $RowHeader).font.bold = $true
            $xlsSh.Cells.item(1, $RowHeader) = $ColH.ColumnName;
            $RowHeader++
        }
 
        ## - Adding the data start in row 2 column 1:
        [Int] $rowData = 2
        [Int] $colData = 1
        $DataSetTable1 = $DataSetTable.rows
        foreach ($rec in $DataSetTable1)
        {
            foreach ($Coln in $getColumnNames)
            {
                ## - Next line convert cell to be text only:
                $xlsSh.Cells.NumberFormat = "@"
                ## - Populating columns:
                $b = $rec.$($Coln.ColumnName)
                $xlsSh.Cells.Item($rowData, $colData) = "$b" #$rec.$($Coln.ColumnName).ToString()
                $ColData++
            }
            $rowData++ 
            $ColData = 1
        }
        $raw1 = $xlsRng = $xlsSH.usedRange
        $raw2 = $xlsRng.EntireColumn.AutoFit()
        ## - Saving Excel file - if the file exist do delete then save

        #$CurrentDir = (Get-Location).Path
        $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
        #$ParentFolder = $CurrentDir.Substring(0,$CurrentDir.LastIndexOf("\"))

        if(Test-Path "$PSScriptRoot\..\Output")
        {
            # skip
        }
        Else
        {
            $data = (New-Item -Path "$PSScriptRoot\..\" -Name Output -ItemType Directory -Force -ErrorAction Stop).Path
        }

        $xlsFile = "$PSScriptRoot\..\Output\TopIOPS.xlsx"
 
        if (Test-Path $xlsFile)
        {
            Remove-Item $xlsFile
            $xlsObj.ActiveWorkbook.SaveAs($xlsFile)
        }
        else
        {
            $xlsObj.ActiveWorkbook.SaveAs($xlsFile)
        }
 
        ## Quit Excel and Terminate Excel Application process:
        $xlsObj.Quit()
        #(Get-Process Excel*) | foreach ($_) { $_.kill() }#>
    }
    else
    {
         Write-Output "Query did not return any data"
    }
}
catch
{
    $Error[0].exception.Message
}
 
## - End of Script - ##