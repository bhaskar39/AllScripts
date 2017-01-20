<#
    .SYNOPSIS
    It is a standaole script for installing the MAP Tool.

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
    Write-LogFile -FilePath $LogFilePath -LogText "Driving the network share...r`n"
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
    # Getting the mapped logical drives
    <#$DeviceID = ""
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
    $PathString = "$DriveToUse\MapTool.exe"
    $SourceFile=$PathString
    $FolderStatus = New-Item -Path C:\ -Name MapTool -ItemType Directory -Force
    $DestinationFile = "C:\MapTool\MapTool.exe"

    try
    {
        if(Test-Path $SourceFile)                                                                                                                                                                              
        {
            Write-LogFile -FilePath $LogFilePath -LogText "Copying the file from share to local server...`r`n"
            ($Status = Copy-Item -Path $SourceFile -Destination $DestinationFile -Force) | Out-Null
            if($?)
            {
                Write-LogFile -FilePath $LogFilePath -LogText "Copying the file from share to local server was success..."
                if(Test-Path $DestinationFile)
                {
                    Write-LogFile -FilePath $LogFilePath -LogText "Starting the installation.`r`n"

                    ($InstallationProcess = Start-Process -FilePath $DestinationFile -ArgumentList '/Silent' -PassThru) | Out-Null
                    Do
                    {
                        Start-Sleep -Seconds 5
                    } While(-not($InstallationProcess.HasExited)) 

                    Write-Output "Verifying the Installation status..."
                    Write-LogFile -FilePath $LogFilePath -LogText "Verifying the installation.`r`n"
                    $InstallationStatus = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -eq 'Microsoft Assessment and Planning Toolkit'}
                    if($InstallationProcess -ne $null)
                    {
                        Write-LogFile -FilePath $LogFilePath -LogText "MapTool has been installed successfully.`r`n"
                        $ObjOut = "MapTool has been installed successfully."
                        $output = (@{"Response" = [Array]$ObjOut; Status = "Success"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
                        Write-Output $output
                    }
                    Else
                    {
                        Write-LogFile -FilePath $LogFilePath -LogText "Unable to verify the installation. Please check manually.`r`n"
                        $ObjOut = "Unable to verify the installation. Please check manually."
                        $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
                        Write-Output $output
                        Exit
                    }
                }
                Else
                {
                    Write-LogFile -FilePath $LogFilePath -LogText "Installation file was not found.`r`n"
                    $ObjOut = "Installation file was not found."
                    $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
                    Write-Output $output
                    Exit
                }        
            }
            Else
            {
                Write-LogFile -FilePath $LogFilePath -LogText "Copying the file from source was not successfull.$($Error[0].Exception.Message)`r`n"
                $ObjOut = "Copying the file from source was not successfull.$($Error[0].Exception.Message)"
                $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
                Write-Output $output
                Exit
            }
        }
        Else
        {
            Write-LogFile -FilePath $LogFilePath -LogText "Source File was not found.`r`n"
            $ObjOut = "Source File was not found."
            $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
            Write-Output $output
            Exit
        }
    }
    catch
    {
        $ObjOut = "Error while installing the MAP Tool. $($Error[0].Exception.Message).'r'n"
        Write-LogFile -FilePath $LogFilePath -LogText $ObjOut
        $output = (@{"Response" = [Array]$ObjOut; Status = "Failed"} | ConvertTo-Json).ToString().Replace('\u0027',"'")
        Write-Output $output
    }
}
End
{
    #
}
