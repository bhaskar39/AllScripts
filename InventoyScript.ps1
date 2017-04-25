<#
    .SYNOPSIS
    Script to get the server information i.e Roles, features and applicaitions and creating json and inventory information files as output

    .DESCRIPTION
    Script to get the server information i.e Roles, features and applicaitions and creating json and inventory information files as output

    .PARAMETER CSVFilePath
    Servers list in csv format with credentials

    .PARAMETER USerName
    Common User Name to login to the server

    .PARAMETER Password
    Common Password to login to the server
	
	.AUTHOR
	Bhaskar Desharaju - bhaskar.desharaju@netenrich.com
	
	.EXAMPLE
	C:\InventoyScript.ps1 -CSVFilePath C:\ServerList.csv -UserName mydomain\admin -password adminpassword	
#>
Param
(
	[Parameter(Mandatory=$true)]
	[string]$CSVFilePath,
	[Parameter(Mandatory=$true)]
    [string]$UserName,
    [Parameter(Mandatory=$true)]
    [string]$Password
)

Begin
{
    [DateTime]$LogFileTime = Get-Date
    $FileTimeStamp = $LogFileTime.ToString("dd-MMM-yyyy_HHmmss")
    $LogFileName = "$($MyInvocation.MyCommand.Name.Replace('.ps1',''))-$FileTimeStamp.log"
    $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
    $LogFilePath = "$PSScriptRoot\$LogFileName"

    # Disabling the progress status popups
    $ProgressPreference = "SilentlyContinue"
    
    # Function to create a log file
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

    # Function to get the file share details
    function Get-FileShareSizes()
    {
        Param
        (
            $ServerInfo,
            $UName,
            $Pwd
        )
        try
        {           
            # Get All Shares
            $Creds1 = New-Object System.Management.Automation.PSCredential ($UName, (ConvertTo-SecureString -AsPlainText -String $Pwd -Force))
            if($ServerInfo.ServerNames -eq $env:COMPUTERNAME)
            {
                Write-LogFile -FilePath $LogFilePath -LogText "Fetching the File shares information"
                $shares = Get-WmiObject -Class Win32_Share -ComputerName $ServerInfo.ServerNames -filter "type=0"
            }
            else
            {
                Write-LogFile -FilePath $LogFilePath -LogText "Fetching the File shares information"
                $shares = Get-WmiObject -Class Win32_Share -ComputerName $ServerInfo.ServerNames -Credential $Creds1 -filter "type=0"
            }

            $sb = {
                Param 
                (
                    $ShareCollection
                ) 

                # Create a collection for Objects
                $ArrayObjects = New-Object System.Collections.ArrayList

                #$path = $($sha)
                # for each given path 
                #foreach($pth in $path)
                foreach($Sha in $ShareCollection)
                {
                    $pth = $($Sha.Path)
                    $Folder = dir $pth | where {$_.PSIsContainer}
                    $NonFolder = dir $pth | where {!($_.PSIsContainer)}
                    if($Folder)
                    {
                        foreach($f in $Folder)
                        {
                            $stats=dir $f.FullName -recurse -errorAction "SilentlyContinue" | where {-NOT $_.PSIscontainer} | Measure-object -Property Length -sum

                            $obj = New-Object -TypeName PSObject -Property @{
                                Computername=$env:Computername
                                Name = $Sha.Name
                                Path=Split-Path -Path $pth -Leaf
                                Fullname=$f.Fullname
                                SizeMB=[math]::Round(($stats.sum/1KB),2)
                                NumberFiles=$stats.count
                                } 
                            $ArrayObjects += $obj
                        }
                    }

                    if($NonFolder)
                    {
                        $stats=dir $pth | Measure-object -Property Length -sum

                        $obj1 = New-Object -TypeName PSObject -Property @{
                            Computername=$env:Computername
                            Name = $Sha.Name
                            Path=Split-Path -Path $pth -Leaf
                            Fullname=$pth
                            SizeMB=[math]::Round(($stats.sum/1024KB),2)
                            NumberFiles=$stats.count
                        } 
                        $ArrayObjects += $obj1
                    }
                }
                $ArrayObjects
            } 

            try
            {
                #$results=Invoke-Command -ScriptBlock $sb -ComputerName $($ServerInfo.ServerNames) -ArgumentList (,$($shares.Path)) -HideComputerName
                $results=Invoke-Command -ScriptBlock $sb -ComputerName $($ServerInfo.ServerNames) -ArgumentList (,$shares) -HideComputerName 
            }
            catch
            {
                #$results=Invoke-Command -ScriptBlock $sb -ComputerName $($ServerInfo.ServerNames) -ArgumentList (,$($shares.Path)) -HideComputerName -Credential $Creds1
                $results=Invoke-Command -ScriptBlock $sb -ComputerName $($ServerInfo.ServerNames) -ArgumentList (,$shares) -HideComputerName -Credential $Creds1
            }
            #$results | Format-Table computername,Fullname,SizeMB
            if($results -ne $null)
            {
                return $results
            }
            else
            {
                return $null
            }
        }
        catch
        {
            Write-LogFile -LogText "$($error[0].Exception.Message)" -FilePath $LogFilePath
            return $null
        }
    } 

    Function Validate()
    {
        Write-LogFile -FilePath $LogFilePath -LogText "Validating Parameters: UserName."
        If([String]::IsNullOrEmpty($UserName))
        {
            Write-LogFile -FilePath $LogFilePath -LogText "Validation failed.UserName parameter value is empty."
            exit 1
        }
        elseif($UserName -notlike "*\*")
        {
            Write-LogFile -LogText "The provided User Name is not a Valid format. It must be a Domain user"
            exit 1
        }else{}

        Write-LogFile -FilePath $LogFilePath -LogText "Validating Parameters: Password."
        If([String]::IsNullOrEmpty($Password))
        {
            Write-LogFile -FilePath $LogFilePath -LogText "Validation failed.Password parameter value is empty."
            exit 1
        }
    }
}
Process
{
    try
    {
        # Function to Validate Parameters
        Validate
   
        Write-LogFile -FilePath $LogFilePath -LogText "Checking for the provided Serverslist file path" -Overwrite
	    # Checking for the existence of the provided file
        if(Test-Path -Path $CSVFilePath)
        {
            Write-LogFile -FilePath $LogFilePath -LogText "Provided Serverslist file path available"

            # Reading the CSV Data
            $CSVdata = Import-Csv -Path $CSVFilePath

            Write-LogFile -FilePath $LogFilePath -LogText "Checking for the servers list file content"
            if($CSVdata)
            {
		        # Importing the servermanager modules to fetch the roles and features
                Import-Module ServerManager
                $AllCollections = New-Object System.Collections.ArrayList

                # Creating JSON Object Array
                $JSONObjArray = New-Object System.Collections.ArrayList

                foreach($server in $CSVdata)
                {
                    # Creating JSON Object for each server
                    $JSONObj = New-Object psobject
                    $JSONObj | Add-Member -MemberType NoteProperty -Name computername -Value $($server.ServerNames)

                    Write-LogFile -FilePath $LogFilePath -LogText "#****** Processing the server $($server.ServerNames)*****#"
                    Write-LogFile -FilePath $LogFilePath -LogText "Checking for the connectivity for the server $($server.ServerNames)"
                    try
                    {
			            # Checking the rechability of the server
                        Write-LogFile -FilePath $LogFilePath -LogText "$($server.ServerNames) is reachable"
                        $ServerStatus = Get-WmiObject -Class Win32_PingStatus -Filter "Address=`'$($server.ServerNames)`'"
                        if($ServerStatus.StatusCode -eq 0)
                        {
                            $JSONObj | Add-Member -MemberType NoteProperty -Name Reachable -Value "YES"

                            $o = New-Object psobject
                            $hostname = $env:COMPUTERNAME
				
				            # If the given server is the current server from where the script is being executed. Credentials are not required, else required
				            # Feteching the installed applications
                            if($server.ServerNames -eq $hostname)
                            {
                                Write-LogFile -FilePath $LogFilePath -LogText "Fetching the Installed Applications on $($server.ServerNames)"
                                #$InstalledApplications = Get-WmiObject -Namespace "root/cimv2" -Class Win32_Product -ErrorAction SilentlyContinue | Select Name, Version,Vendor
                                $InstalledApplications = Get-WmiObject -Namespace "root/cimv2" -Class Win32_Product | Select Name, Version,Vendor
                            }
                            else
                            {
                                Write-LogFile -FilePath $LogFilePath -LogText "Fetching the Installed Applications on $($server.ServerNames)"
                                $Creds = New-Object System.Management.Automation.PSCredential ($USerName, (ConvertTo-SecureString -AsPlainText -String $Password -Force))
                                $InstalledApplications = Get-WmiObject -Namespace "root/cimv2" -Class Win32_Product -ComputerName $server.ServerNames -Credential $Creds -ErrorAction SilentlyContinue | Select Name, Version,Vendor
                                $InstalledApplications = Get-WmiObject -Namespace "root/cimv2" -Class Win32_Product -ComputerName $server.ServerNames -Credential $Creds | Select Name, Version,Vendor
                            }
				        
                            # Making individual JSON inner Object for applications
                            $hash1 = @{}
                            foreach($app in $InstalledApplications)
                            {
                                $hash2 = @{}
                                $hash2.version = $app.Version
                                $hash2.manufacturer = $app.Vendor
                                $hash1[$app.Name] = $hash2
                            }                       
                            $JSONObj | Add-Member -MemberType NoteProperty -Name applications -Value $hash1

				            # Generating the CSV file with server name for each server provided in list
                            Write-LogFile -FilePath $LogFilePath -LogText "Generating the file $($server.ServerNames).csv for list of Applications on $($server.ServerNames)"
                            #$raw = $InstalledApplications | Export-Csv -Path "$PSScriptRoot\$($server.ServerNames).csv" -NoTypeInformation -Force
                            $o | Add-Member -MemberType NoteProperty -Name ServerName -Value $server.ServerNames
				
                            # Hash table to hold roles information for JSON output
                            $Roles = @{}
                            try
                            {
				                # Fetching all features roles installed on server
                                if($server.ServerNames -eq $hostname)
                                {
                                    Write-LogFile -FilePath $LogFilePath -LogText "Fetching the All Remote Desktop Features on $($server.ServerNames)"
                                    $RDSFeatures = Get-WindowsFeature -Name 'RDS-*' # -ErrorAction SilentleyContinue
                                    $PrintServices = Get-WindowsFeature -Name 'Print-Services' #-ErrorAction SilentleyContinue
                                    $FileServices = Get-WindowsFeature -Name 'FS-FileServer' #-ErrorAction SilentleyContinue
                                }
                                else
                                {
                                    Write-LogFile -FilePath $LogFilePath -LogText "Fetching the All Remote Desktop Features on $($server.ServerNames)"
                                    $RDSFeatures = Get-WindowsFeature -Name 'RDS-*' -ComputerName $server.ServerNames -Credential $Creds #-ErrorAction SilentleyContinue
                                    $PrintServices = Get-WindowsFeature -Name 'Print-Services' -ComputerName $server.ServerNames -Credential $Creds #-ErrorAction SilentleyContinue
                                    $FileServices = Get-WindowsFeature -Name 'FS-FileServer' -ComputerName $server.ServerNames -Credential $Creds #-ErrorAction SilentleyContinue
                                }
                            }
                            catch
                            {
                                Write-LogFile -FilePath $LogFilePath -LogText "Unable to fetch windows roles and features: $($error[0].Exception.Message)"
                            }

                            Write-LogFile -FilePath $LogFilePath -LogText "Checking the RDS Connection Broker Installation information on $($server.ServerNames)"
                            if($RDSFeatures)
                            {
                                $RDSCon = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Connection-Broker'}
                                if($RDSCon.InstallState -eq "Installed")
                                {
                                    $Roles['RDS-Connection-Broker'] = 'Yes'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Connection Broker feature is available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Connection Broker' -Value "Yes"
                                }
                                else
                                {
                                    $Roles['RDS-Connection-Broker'] = 'No'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Connection Broker feature is not available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Connection Broker' -Value "No"
                                }

                                Write-LogFile -FilePath $LogFilePath -LogText "Checking the RDS Gateway Installation information on $($server.ServerNames)"
                                $RDSGW = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Gateway'}
                                if($RDSGW.InstallState -eq "Installed")
                                {
                                    $Roles['RDS-Gateway'] = 'Yes'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Gateway feature is available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Gateway' -Value "Yes"
                                }
                                else
                                {
                                    $Roles['RDS-Gateway'] = 'No'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Gateway feature is not available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Gateway' -Value "No"
                                }

                                Write-LogFile -FilePath $LogFilePath -LogText "checking the RDS Licensing Installation information on $($server.ServerNames)"
                                $RDSLic = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Licensing'}
                                if($RDSLic.InstallState -eq "Installed")
                                {
                                    $Roles['RDS-Licensing'] = 'Yes'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Licensing feature is available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Licensing' -Value "Yes"
                                }
                                else
                                {
                                    $Roles['RDS-Licensing'] = 'No'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Licensing feature is not available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Licensing' -Value "No"
                                }

                                Write-LogFile -FilePath $LogFilePath -LogText "Fetching the RDS Session Host Broker Installation information on $($server.ServerNames)"
                                $RDSSSH = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-RD-Server'}
                                if($RDSSSH.InstallState -eq "Installed")
                                {
                                    $Roles['RDS-RD-Server'] = 'Yes'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Session Host feature is available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Session Host' -Value "Yes"
                                }
                                else
                                {
                                    $Roles['RDS-RD-Server'] = 'No'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Session Host feature is not available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Session Host' -Value "No"
                                }

                                Write-LogFile -FilePath $LogFilePath -LogText "Fetching the RDS Web Access Installation information on $($server.ServerNames)"
                                $RDSWeb = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Web-Access'}
                                if($RDSWeb.InstallState -eq "Installed")
                                {
                                    $Roles['RDS-Web-Access'] = 'Yes'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Web Access feature is available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Web Access' -Value "Yes"
                                }
                                else
                                {
                                    $Roles['RDS-Web-Access'] = 'No'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Web Access feature is not available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Web Access' -Value "No"
                                }
                            }
                            else
                            {
                                # Empty roles will added when No reuqired roles were found or when there is an exception while fetching the windows features
                                $Roles['RDS-Connection-Broker'] = 'No'
                                $Roles['RDS-Gateway'] = 'No'
                                $Roles['RDS-Licensing'] = 'No'
                                $Roles['RDS-RD-Server'] = 'No'
                                $Roles['RDS-Connection-Broker'] = 'No'
                                Write-LogFile -FilePath $LogFilePath -LogText "Did not get the RDS Features information"
                            }

                            if($PrintServices)
                            {
                                if($PrintServices.InstallState -eq 'Installed')
                                {
                                    $Roles['Print-Services'] = 'Yes'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Print Services feature is available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'Print Services' -Value "Yes"                
                                }
                                else
                                {
                                    $Roles['Print-Services'] = 'No'
                                    Write-LogFile -FilePath $LogFilePath -LogText "RDS Print Services feature is not available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'Print Services' -Value "No"
                                }
                            }
                            else
                            {
                                $Roles['Print-Services'] = 'No'
                                Write-LogFile -FilePath $LogFilePath -LogText "Did not get the Print Server role and Features information"
                            }

                            if($FileServices)
                            {
                                if($FileServices.InstallState -eq 'Installed')
                                {
                                    $Roles['FS-FileServer'] = 'Yes'
                                    Write-LogFile -FilePath $LogFilePath -LogText "File Server role is available"
                                    Write-LogFile -FilePath $LogFilePath -LogText "Fetching the File Shares information on $($server.ServerNames)"
                                    $FileSharesInfo = Get-FileShareSizes -ServerInfo $server -UName $USerName -Pwd $Password
                                    $Strings = $null

                                    if($FileSharesInfo)
                                    {
                                        foreach($Ob in $FileSharesInfo)
                                        {
                                            $Strings += "$($Ob.Name);" 
                                        }
                                        $o | Add-Member -MemberType NoteProperty -Name 'File Server' -Value "Yes"
                                        $o | Add-Member -MemberType NoteProperty -Name 'Shares' -Value $Strings
                                    }
                                    else
                                    {
                                        Write-LogFile -FilePath $LogFilePath -LogText "Did not fetch the Fileshare information or exception occured while tetching the details for $($server.ServerNames)"
                                    }           
                                }
                                else
                                {
                                    $Roles['FS-FileServer'] = 'No'
                                    Write-LogFile -FilePath $LogFilePath -LogText "File Server role is not available"
                                    $o | Add-Member -MemberType NoteProperty -Name 'File Server' -Value "No"
                                    $o | Add-Member -MemberType NoteProperty -Name 'Shares' -Value  'NA'
                                }
                                Write-LogFile -FilePath $LogFilePath -LogText "Successfully fecthed all the features and roles information for the server $($server.ServerNames)"
                                #$AllCollections += $o
                            }
                            else
                            {
                                $Roles['FS-FileServer'] = 'No'
                                Write-LogFile -FilePath $LogFilePath -LogText "Did not get the File Server role and Features information"
                            }

                            $JSONObj | Add-Member -MemberType NoteProperty -Name roles -Value $Roles
                            $JSONObjArray += $JSONObj
                        }
			            # if the Server is not reachable, mention it as Not reachable
                        else
                        {
                            $JSONObj | Add-Member -MemberType NoteProperty -Name Reachable -Value "No"
                            $o = New-Object psobject
                            $o | Add-Member -MemberType NoteProperty -Name ServerName -Value $server.ServerNames
                            $o | Add-Member -MemberType NoteProperty -Name 'RDS Connection Broker' -Value "Not Reachable"
                            $o | Add-Member -MemberType NoteProperty -Name 'RDS Gateway' -Value "Not Reachable"
                            $o | Add-Member -MemberType NoteProperty -Name 'RDS Licensing' -Value "Not Reachable"
                            $o | Add-Member -MemberType NoteProperty -Name 'RDS Session Host' -Value "Not Reachable"
                            $o | Add-Member -MemberType NoteProperty -Name 'RDS Web Access' -Value "Not Reachable"
                            $o | Add-Member -MemberType NoteProperty -Name 'Print Services' -Value "Not Reachable"
                            $o | Add-Member -MemberType NoteProperty -Name 'File Services' -Value "Not Reachable"

                            $hash3 = @{}
                            $hash4 = @{}
                            $JSONObj | Add-Member -MemberType NoteProperty -Name applications -Value $hash3
                            $JSONObj | Add-Member -MemberType NoteProperty -Name roles -Value $hash4
                            Write-LogFile -FilePath $LogFilePath -LogText "Failed to fetch roles and features information on $($server.ServerNames) since server is not reachable"
                            $JSONObjArray += $JSONObj
                        }
                        #$raw2 = $JSONObjArray | ConvertTo-Json -Depth 5 | Out-File C:\JSONFile.json
                        $AllCollections += $o
                    }
                    catch
                    {
                        Write-LogFile -FilePath $LogFilePath -LogText "Exception occured while fetching information for the server $($server.ServerNames): $($error[0].Exception.Message)"
                    }
                }

                $JSONObjFinal = @{}
                $JSONObjFinal["assessment_custom_result"] = $JSONObjArray
                $raw2 = $JSONObjFinal | ConvertTo-Json -Depth 5 | Out-File "$PSScriptRoot\ServerInventory.json" -Force
		        # Creating the final report with all details
                #$raw = $AllCollections | Export-Csv -Path "$PSScriptRoot\ServerInventory.csv" -NoTypeInformation -Force
            }
            Else
            {
                Write-LogFile -FilePath $LogFilePath -LogText "Server Names are available in the provided file."
                exit 1
            }
        }
        else
        {
            Write-Output "The Provided path for CSV does not exist"
            Write-LogFile -FilePath $LogFilePath -LogText "The Provided path for CSV does not exist"
            exit 1
        }
    }
    catch
    { 
        Write-Output "There was an exception. $($error[0].Exception.Message)"
        exit 1
    }
}
End
{
    $ProgressPreference = "Continue"
    Write-Host "Script executiong is completed successfully"
    Write-LogFile -LogText "Script executiong is completed successfully" -FilePath $LogFilePath
    exit 0
}
