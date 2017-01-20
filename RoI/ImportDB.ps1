<#
    .SYNOPSIS
    It is a standaole script for installing the MAP Tool.

#>
Begin
{
    $Script:CustomerName = $args[0]
    $Script:UserName = $args[1]
    $Script:Password = $args[2]

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

    Function Import-Database
    {
        Param
        (
            $FileSharePath,
            $DataBaseFileName
        )
        Try
        {
            # Fetch the ShortCode for customer
            $DatabaseName = "Assess-MGMT"
            $Datasource = "localhost"
            $Sqlquery1 = "select dbshortCode,* from customer where Name like $Script:CustomerName"
            $SqlConnactionString = "Server=$DataSource;uid=$Script:UserName; pwd=$Script:Password;Database=$DatabaseName;Integrated Security=False"
            $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
            $sqlConnection.ConnectionString = $SqlConnactionString
            $sqlConnection.Open()
            $SqlCommand = New-Object System.Data.SqlClient.SqlCommand
            $SqlCommand.Connection = $sqlConnection
            $SqlCommand.CommandText = $Sqlquery1
            $result = $SqlCommand.ExecuteReader()
            $DataTable = New-Object System.Data.DataTable
            $DataTable.Load($result)

            if($DataTable[0].Rows -ne $null)
            {
                $CustomerShortCode = ($DataTable[0].Rows).dbshortCode
            }
            Else
            {
                Write-Output "The specified customer details were not found"
                exit
            }

            $sqlConnection.Close()

            # Importing the Database to master DB Server
            $DatabaseFileFullPath = $FileSharePath+"\"+$DataBaseFileName
            $DatabaseName = $CustomerShortCode
            $Datasource = "localhost"
            $Sqlquery2 = “restore database $DatabaseName from Disk = '"+$DatabaseFileFullPath+"'”
            $SqlConnactionString1 = "Server=$DataSource;uid=$UserName;pwd=$Password;Integrated Security=False"
            $sqlConnection1 = New-Object System.Data.SqlClient.SqlConnection
            $sqlConnection1.ConnectionString = $SqlConnactionString
            $sqlConnection1.Open()
            $SqlCommand1 = New-Object System.Data.SqlClient.SqlCommand
            $SqlCommand1.Connection = $sqlConnection
            $SqlCommand1.CommandText = $Sqlquery2
            $result = $SqlCommand1.ExecuteNonQuery()
            $sqlConnection1.Close()

            return $true
        }
        Catch
        {
            $ObjOut = "Error while Exporting the Database. $($Error[0].Exception.Message).'r'n"
            Write-LogFile -FilePath $LogFilePath -LogText $ObjOut
            $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
            Write-Output $output
            return $false         
        }
    }
}
Process
{
    # Mapping the Fileshare
    # Fetching the available drive letter
    ($ExistingDrives = (Get-WmiObject -Class Win32_LogicalDisk).DeviceID) | Out-Null
    $DriveLetters = @('E:','F:','G:','H:','I:','J:','K:','L:','M:','N:','O:','P:','R:','S:','T:','U:','V:','W:','X:','Y:','Z:')
    $DriveToUse = ""
    foreach($AvailableDrive in $DriveLetters)
    {
        if($AvailableDrive -in $ExistingDrives)
        {
            continue
        }
        Else
        {
            $DriveToUse = $AvailableDrive
            break
        }
    }

    # Mapping the Network share to the availabel drive
    $CommandTORun = "cmd.exe /c 'net use "+$DriveToUse+" \\rtechstr.file.core.windows.net\mapfileshare /u:rtechstr OOvkCTdH/brKRY2ikWIGcQuQt4x8owNEFr6KI0Iif5b72QlCf3FsYRjY220kAcYbhEiTLjyHSYeRMy+R5IfCRw=='"
    $State = Invoke-Expression -Command $CommandTORun -ErrorAction Stop -WarningAction SilentlyContinue
    if($? -eq $false)
    {
        Write-LogFile -FilePath $LogFilePath -LogText "Driving the network share failed.$($Error[0].Exception.Message)`r`n"
        $ObjOut = "Driving the network share failed.$($Error[0].Exception.Message)"
        $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
        Write-Output $output
        exit        
    }

    $DestinationFilePath = "$DriveToUse\Assesments\CustomerBackups"
    $DataBaseFileName = (Get-Content -Path "$DestinationFilePath\DBFiles.txt" -Tail 1).Trim()
    try
    {
        if(Test-Path "$DestinationFilePath\DBFiles.txt")
        {
            $FoutPut = Import-Database -FileSharePath $DestinationFilePath -DataBaseFileName $DataBaseFileName
            if($FoutPut -eq $true)
            {
                Write-LogFile -FilePath $LogFilePath -LogText "Database Backup file has been imported successfully.`r`n"
                $ObjOut = "Database Backup file has been imported successfully."
                $output = (@{"Response" = [Array]$ObjOut; Status = "Success"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
                Write-Output $output
            }
            Else
            {
                Write-LogFile -FilePath $LogFilePath -LogText "Unable to import the database.`r`n"
                $ObjOut = "Unable to import the database."
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
