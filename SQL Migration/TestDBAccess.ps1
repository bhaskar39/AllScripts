Param
(
    [Parameter(mandatory=$true)]
    $SQLServerName,
    [Parameter(mandatory=$true)]
    $DataBaseName,
    [Parameter(mandatory=$true)]
    $DBUserName,
    [Parameter(mandatory=$true)]
    $DBPassword,
    $SQLQuery
)

try
{
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=$SQLServerName;Database=$DatabaseName;Integrated Security=True;User Id=$DBUserName;Password=$DBPassword"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    if($SQLQuery -eq $Null)
    {
        $SqlCmd.CommandText = "Select * from sys.tables"
    }
    Else
    {
        $SqlCmd.CommandText = $SQLQuery
    }
    $SqlCmd.Connection = $SqlConnection
    $SqlConnection.Open()
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $Null = $SqlAdapter.Fill($DataSet)
    $SqlConnection.Close()
    if ( $DataSet.Tables.count -gt 0 ) {
                    $Rows = $DataSet.Tables[0]
    }
    return $Rows
}
catch
{
    Write-Output "$($Error[0].Exception.Message)"
}
