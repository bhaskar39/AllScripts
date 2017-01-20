Param
(
    [Parameter(mandatory=$true)]
    $SQLServerName,
    [Parameter(mandatory=$true)]
    $DataBaseName,
    [Parameter(mandatory=$true)]
    $DBUserName,
    [Parameter(mandatory=$true)]
    $DBPassword
)

try
{
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=$SQLServerName;Database=$DatabaseName;Integrated Security=True;User Id=$DBUserName;Password=$DBPassword"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand

    $SqlCmd.CommandText = "USE $DataBaseName;EXEC sp_change_users_login 'Report'"
    $SqlCmd.Connection = $SqlConnection
    $SqlConnection.Open()
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $Null = $SqlAdapter.Fill($DataSet)

    if ( $DataSet.Tables.count -gt 0 ) {
                    $Rows = $DataSet.Tables[0]
    }
    $TableData = $Rows.Rows
    if($TableData -ne $Null)
    {
        foreach($TD in $TableData)
        {
            $UName = $TD.UserName
            $Sid = $TD.UserSID
            Write-Output "Fixing the user $UName mapping"
            $SQLfixLogin = "USE $DataBaseName;EXEC sp_change_users_login 'Auto_Fix','$UName'"
            $SqlCmd.Connection =$SqlConnection
            $SqlCmd.CommandTimeout = 600000
            $SqlCmd.CommandText = $SQLfixLogin
            $Res = $SqlCmd.ExecuteNonQuery()
        }
    }
    $SqlConnection.Close()
}
catch
{
    Write-Output "$($Error[0].Exception.Message)"
}
