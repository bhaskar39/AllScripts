
## ---------- Working with SQL Server ---------- ##
 
## - Get SQL Server Table data:

Try
{

    $SQLServer = 'localhost'

    $SqlQuery = @'
        select top 10 --rank() over(order by total_worker_time desc,sql_handle,statement_start_offset) as row_no
--,       (rank() over(order by total_worker_time desc,sql_handle,statement_start_offset))%2 as l1
      creation_time
,       last_execution_time
,       (total_worker_time+0.0)/1000 as total_worker_time
,       (total_worker_time+0.0)/(execution_count*1000) as [AvgCPUTime]
,       total_logical_reads as [LogicalReads]
,       total_logical_writes as [logicalWrites]
,       execution_count
,       total_logical_reads+total_logical_writes as [AggIO]
,       (total_logical_reads+total_logical_writes)/(execution_count + 0.0) as [AvgIO]
,   case when sql_handle IS NULL
                then ' '
                else ( substring(st.text,(qs.statement_start_offset+2)/2,(case when qs.statement_end_offset = -1        then len(convert(nvarchar(MAX),st.text))*2      else qs.statement_end_offset    end - qs.statement_start_offset) /2  ) )
        end as query_text 
,       db_name(st.dbid) as database_name
,       st.objectid as object_id
from sys.dm_exec_query_stats  qs
cross apply sys.dm_exec_sql_text(sql_handle) st
where total_worker_time > 0 and last_execution_time>DATEADD(hh, - 1, GETDATE())--Use this if required for last 1 hour
order by total_worker_time  desc
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
 
    ## - Create an Excel Application instance:
    if($DataSetTable -ne $null)
    {

        $DataSetTable1 = $DataSetTable.rows
        $outdata = $DataSetTable1 | fl
        write-output $outdata
        <#$xlsObj = New-Object -ComObject Excel.Application
 
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
        $outdata = $DataSetTable1 | fl
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

        $xlsFile = "$PSScriptRoot\..\Output\TopCPU.xlsx"
 
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