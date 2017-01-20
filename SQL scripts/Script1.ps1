
try
{
    $SQLQuery = @"
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
"@

    # Create a SQL Client
    $SqlConnactionString = "Server=localhost;uid=sa;pwd=Pass@123Integrated Security=False"
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $sqlConnection.ConnectionString = $SqlConnactionString
    $sqlConnection.Open()
    $SqlCommand = New-Object System.Data.SqlClient.SqlCommand
    $SqlCommand.Connection = $sqlConnection
    $SqlCommand.CommandText = $SQLQuery
    #$result = $SqlCommand.ExecuteReader()
    $result = $SqlCommand.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($result)
    $DataTable

    if($DataTable -ne $null)
    {
        $ObjArray = New-Object System.Collections.ArrayList

        foreach($data in $DataTable)
        {
            $NewObj = New-Object psobject
            $NewObj | Add-Member -MemberType NoteProperty -Name "Database Name" -Value $data.DatabaseName

        }
    }
    else
    {
    }

}
catch
{
    $Error[0].Exception.Message
}