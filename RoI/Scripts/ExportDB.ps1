<#
    .SYNOPSIS
    It is a standaole script for installing the MAP Tool.

#>
Begin
{
    #$Script:UserName = $args[0]
    #$Script:Password = $args[1]
    $Script:DatabaseName = $args[0]
    # Name the Log file based on script name
    [DateTime]$LogFileTime = Get-Date
    $FileTimeStamp = $LogFileTime.ToString("dd-MMM-yyyy_HHmmss")
    $LogFileName = "$ClientID-$($MyInvocation.MyCommand.Name.Replace('.ps1',''))-$FileTimeStamp.log"
    $LogFilePath = "C:\MapTool\$LogFileName"

    Function Write-LogFile
    {
        Param([String]$FilePath, [String]$LogText, [Switch]$Overwrite = $false)

        [DateTime]$LogTime = Get-Date
        $TimeStamp = $LogTime.ToString("dd-MMM-yyyy hh:mm:ss tt")
        $InputLine = "[$TimeStamp] : $LogText"

        If($FilePath -like "*.???")
        { $CheckPath = Split-Path $FilePath; }
        Else
        { $CheckPath = $FilePath }

        If(Test-Path -Path $CheckPath -ErrorAction SilentlyContinue)
        {
            # Correct path Now check if it is a File or Folder
            ($IsFolder = (Get-Item $FilePath -ErrorAction SilentlyContinue) -is [System.IO.DirectoryInfo]) | Out-Null
            If($IsFolder)
            {
                If($FilePath.EndsWith("\")) { $FilePath = $FilePath.TrimEnd(1) }
                $FilePath = "$FilePath\Log_$($LogTime.ToString('dd-MMM-yyyy_hh.mm.ss')).log"
            }
        }
        Else
        {
            Try
            {
                If(-not($FilePath -like "*.???"))
                {
                    If($FilePath.EndsWith("\")) { $FilePath = $FilePath.TrimEnd(1) }
                    $FilePath = "$FilePath\Log_$($LogTime.ToString('dd-MMM-yyyy_HH.mm.ss')).log"
                    (New-Item -Path $FilePath -ItemType File -Force -ErrorAction Stop) | Out-Null
                }
                Else
                {
                    (New-Item -Path $CheckPath -ItemType Directory -Force -ErrorAction Stop) | Out-Null
                }
            }
            Catch
            { 
                "Error creating output folder for Log file $(Split-Path $FilePath).`n$($Error[0].Exception.Message)"
            }
        }

        If($Overwrite)
        {
            $InputLine | Out-File -FilePath $FilePath -Force
        }
        Else
        {
            $InputLine | Out-File -FilePath $FilePath -Force -Append
        }
    }
    Write-LogFile -FilePath $LogFilePath -LogText "####[ Script Execution started: $($MyInvocation.MyCommand.Name)." -Overwrite

    Function Export-Database
    {
        Param
        (
            $FileSharePath
        )
        Try
        {
            $DatabaseName = hostname
            $Datasource = "(localdb)\maptoolkit"
            $database = $Script:DatabaseName
            $SqlConnactionString = "Server=$DataSource;Database=$database;Integrated Security=True"
            $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
            $sqlConnection.ConnectionString = $SqlConnactionString
            $sqlConnection.Open()
            $SqlCommand = New-Object System.Data.SqlClient.SqlCommand
            $SqlCommand.Connection = $sqlConnection
            $SqlCommand.CommandTimeout = 0
            $SqlCommand.CommandText = "backup database $database to Disk = '"+$FileSharePath+"\"+$DatabaseName+".bak'"
            $result = $SqlCommand.ExecuteNonQuery()

            $UpdateContent = Add-Content -Value "$DatabaseName.bak" -Path "$FileSharePath\DBFiles.txt" -Force
            $sqlConnection.Close()
        }
        Catch
        {
            $ObjOut = "Error while Exporting the Database. $($Error[0].Exception.Message).'r'n"
            Write-LogFile -FilePath $LogFilePath -LogText $ObjOut
            $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
            Write-Output $output
            Exit            
        }
    }
}
Process
{

    # Getting the mapped logical drives
    $DeviceID = ""
    ($Drives = Get-WmiObject -Class Win32_MappedLogicalDisk -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) | Out-Null
    if($Drives -ne $null)
    {
        foreach($Drive in $Drives)
        {
            if($Drive.ProviderName -eq '\\rtechstr.file.core.windows.net\mapfileshare')
            {
                $DeviceID = $Drive.DeviceID
            }
        }
    }
    Else
    {
        Write-LogFile -FilePath $LogFilePath -LogText "Drive was not mounted properly.`r`n"
        $ObjOut = "Drive was not mounted properly."
        $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
        Write-Output $output
        exit
    }#>
    # Hardcoded Path since FileShare will be mapped to the VM at this drive.
    
    $DestinationFilePath = "$DeviceID\Assesments\CustomerBackups"
    try
    {
        if(Test-Path $DestinationFilePath)
        {
            $FoutPut = Export-Database -FileSharePath $DestinationFilePath
            if($?)
            {
                Write-LogFile -FilePath $LogFilePath -LogText "Database Backup file has been exported successfully.`r`n"
                $ObjOut = "Database Backup file has been exported successfully."
                #$output = (@{"Response" = [Array]$ObjOut; Status = "Success"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
                Write-Output $ObjOut
            }
            Else
            {
                Write-LogFile -FilePath $LogFilePath -LogText "There was error while exporting the database file.$($error[0].Exception.Message).`r`n"
                $ObjOut = "There was error while exporting the database file.$($error[0].Exception.Message)."
                $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
                Write-Output $output
                Exit
            }
        }
        else
        {
            Write-LogFile -FilePath $LogFilePath -LogText "The Destination file share does not exist.`r`n"
            $ObjOut = "The Destination file share does not exist."
            $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
            Write-Output $output
            Exit
        }

        # Unmapping the FileShare
        # Removing the fileshare mapping
        $CommandToRemove = "cmd.exe /c 'net use "+$DeviceID+" /delete'"
        ($ExeStatus = Invoke-Expression -Command $CommandToRemove -ErrorAction Stop -WarningAction SilentlyContinue) | Out-Null
        if($?)
        {
            Write-LogFile -FilePath $LogFilePath -LogText "Fileshare has been removed.`r`n"
            $ObjOut = "Fileshare has been removed."
            $output = (@{"Response" = [Array]$ObjOut; Status = "Success"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
            Write-Output $output
        }
        Else
        {
            Write-LogFile -FilePath $LogFilePath -LogText "Error in removing the fileshare.$($Error[0].Exception.Message)`r`n"
            $ObjOut = "Error in removing the fileshare.$($Error[0].Exception.Message)"
            $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
            Write-Output $output
            exit
        }
    }
    catch
    {
        $ObjOut = "There was an error while performing the database export operation. $($Error[0].Exception.Message).'r'n"
        Write-LogFile -FilePath $LogFilePath -LogText $ObjOut
        $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
        Write-Output $output
        Exit  
    }
}
End
{
    #
}
