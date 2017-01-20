## ---------- Working with SQL Server ---------- ##
 
## - Get SQL Server Table data:

Try
{

    $SQLServer = 'localhost'

    $SqlQuery = @'
        SELECT dtl.request_session_id AS WaitingSessionID,
        der.blocking_session_id AS BlockingSessionID,
        --dowt.resource_description,
        der.wait_type,
        ((dowt.wait_duration_ms)/60000) as Blocking_Since_Minutes,
        DB_NAME(dtl.resource_database_id) AS DatabaseName,
        --dtl.resource_associated_entity_id AS WaitingAssociatedEntity,
        dtl.resource_type AS WaitingResourceType,
        dtl.request_type AS WaitingRequestType,
        dest.[text] AS BlockedTSql,
        dtlbl.request_type BlockingRequestType,
        destbl.[text] AS BlockingTsql,
        des.host_name as Host,
        des.program_name program,
        des.login_name as login
        FROM sys.dm_tran_locks AS dtl
        JOIN sys.dm_os_waiting_tasks AS dowt
        ON dtl.lock_owner_address = dowt.resource_address
        JOIN sys.dm_exec_requests AS der
        ON der.session_id = dtl.request_session_id
        CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) AS dest
        LEFT JOIN sys.dm_exec_requests derbl
        ON derbl.session_id = dowt.blocking_session_id
        OUTER APPLY sys.dm_exec_sql_text(derbl.sql_handle) AS destbl
        LEFT JOIN sys.dm_tran_locks AS dtlbl
        ON derbl.session_id = dtlbl.request_session_id
        inner join sys.dm_exec_sessions as des
        on des.session_id=der.blocking_session_id
        --where dowt.wait_duration_ms>900000--Uncomment this if you want to check blocking more than 15 minutes
        group by der.blocking_session_id,dtl.request_session_id,dowt.resource_description,
        der.wait_type,
        dowt.wait_duration_ms,
        DB_NAME(dtl.resource_database_id),
        dtl.resource_associated_entity_id,
        dtl.resource_type,
        dtl.request_type,
        dest.[text],
        dtlbl.request_type,
        destbl.[text],
        des.host_name,
        des.program_name,
        des.login_name

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
                $xlsSh.Cells.Item($rowData, $colData) = "$b" #$rec.$($Coln.ColumnName)
                $ColData++
            }
            $rowData++ 
            $ColData = 1
        }

        $raw1 = $xlsRng = $xlsSH.usedRange
        $raw2 = $xlsRng.EntireColumn.AutoFit()
        ## - Saving Excel file - if the file exist do delete then save

        ## - Saving Excel file - if the file exist do delete then save

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

        $xlsFile = "$PSScriptRoot\..\Output\Blocking.xlsx"
 
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
        #(Get-Process Excel*) | foreach ($_) { $_.kill() }
    }
    Else
    {
        Write-Output "Query did not return any data"
    }
}
catch
{
    $Error[0].exception.Message
}
 
## - End of Script - ##