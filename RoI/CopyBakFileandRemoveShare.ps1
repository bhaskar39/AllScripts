<#
#>

Begin
{
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
}
Process
{
    try
    {
        # FilePath for SQL .bak file
        $BackUpFilePath = "C:\sample.bak"
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
            Write-LogFile -FilePath $LogFilePath -LogText "Driving the network share failed.$($Error[0].Exception.Message)`r`n"
            $ObjOut = "Driving the network share failed.$($Error[0].Exception.Message)"
            $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
            Write-Output $output
            exit
        }

        # Copying the .bak file to mapped fileshare
        $DestinationFilePath = "$DeviceID\sample.bak"
        if(Test-Path $BackUpFilePath)
        {
            ($State = Copy-Item -Path $BackUpFilePath -Destination $DestinationFilePath -Force -ErrorAction Stop -WarningAction SilentlyContinue ) | Out-Null
            if($?)
            {
                Write-LogFile -FilePath $LogFilePath -LogText "Backup file has been copies to fileshare.`r`n"
            }
            Else
            {
                Write-LogFile -FilePath $LogFilePath -LogText "There was an error in copying the backup file to fileshare.$($Error[0].Exception.Message)`r`n"
                $ObjOut = "There was an error in copying the backup file to fileshare.$($Error[0].Exception.Message)"
                $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
                Write-Output $output
                exit
            }
        }

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
        Write-LogFile -FilePath $LogFilePath -LogText "Exception while performing file copy and removing the fileshare.$($Error[0].Exception.Message)`r`n"
        $ObjOut = "Exception while performing file copy and removing the fileshare..$($Error[0].Exception.Message)"
        $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
        Write-Output $output
        exit
    }
}
End
{
    #
}