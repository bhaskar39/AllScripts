Param
(
    [Parameter(mandatory=$true)]
    $DBUserName,
    [Parameter(mandatory=$true)]
    $DBPassword,
    [Parameter(mandatory=$true)]
    $BackupFilePath
)

try
{
    if(Test-Path -Path $BackupFilePath)
    {
        $DestinationDBName = (Split-Path $BackupFilePath -Leaf).Replace('.bak','')

        $SQLServerName = "localhost"
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = "Server=$SQLServerName;Integrated Security=True;User Id=$DBUserName;Password=$DBPassword"
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.Connection = $SqlConnection
           
        $SqlCmd.CommandText = "Select name from master.dbo.sysdatabases"
        $SqlConnection.Open()
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd
        $DataSet = New-Object System.Data.DataSet
        $Res = $SqlAdapter.Fill($DataSet)
        if(($Res -ne $null) -and !($DataSet.Tables.name.Contains($DestinationDBName)))
        {
            $Expression = "Sqlcmd -S localhost -U $DBUserName -P $DBPassword -Q `"RESTORE DATABASE $DestinationDBName FROM DISK='"+$BackupFilePath+"'`""
            $Status = Invoke-Expression -Command $Expression
            if($Status -and $Status.Contains("successfully processed"))
            {
                Write-Output "Database has been restored successfully"
            }
            else 
            {
                Write-Output "Database restoration has been failed.$Status"
            }
        }
        else 
        {
            Write-Output "Database is already exist. Cannot restore into existing database"
        }
        $SqlConnection.Close()
    }
    else 
    {
        Write-Output "Database backup file does not exist or has not been downloaded."
    }
}
catch
{
    Write-Output "$($Error[0].Exception.Message)"
}