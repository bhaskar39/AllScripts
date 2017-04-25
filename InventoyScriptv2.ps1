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

    $ExceptionCodes = @()

    # hold the current Computername
    $hostname = $env:COMPUTERNAME

    # Disabling the progress status popups temprarily
    $ProgressPreference = "SilentlyContinue"
    
    #################################### Function to create and update log file ###########################################
    Function Write-LogFile
    {
        Param
        (
            [String]$LogText, 
            [Switch]$Overwrite = $false
        )

        $FilePath = $LogFilePath
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

    ####################################### Function to get the file share details #########################################
    function Get-FileShareSizes
    {
        Param
        (
            [string]$ServerInfo,
            [pscredential]$Creds
        )
        try
        {   
            Write-LogFile -LogText "Fetching the File shares information"        
            if($ServerInfo -eq $hostname)
            {
                # if the given server is same as local server, credentials are not required
                $shares = Get-WmiObject -Class Win32_Share -ComputerName $ServerInfo -filter "type=0"
            }
            else
            {
                # Credential are required for the remote host
                $shares = Get-WmiObject -Class Win32_Share -ComputerName $ServerInfo -Credential $Creds -filter "type=0"
            }

            # Script block for getting the file share on the remote host
            $sb = {
                Param 
                (
                    $ShareCollection
                ) 

                # Create a collection for Objects
                $ArrayObjects = New-Object System.Collections.ArrayList

                # Iterating through the Shares
                foreach($Sha in $ShareCollection)
                {
                    $pth = $($Sha.Path)
                    # get shares which are netsed folders
                    $Folder = Get-ChildItem $pth | Where-Object {$_.PSIsContainer}
                    # get shares which are non netsed folders
                    $NonFolder = Get-ChildItem $pth | Where-Object {!($_.PSIsContainer)}

                    # Process each folder to get the size of the folder size
                    if($Folder)
                    {
                        foreach($f in $Folder)
                        {
                            $stats=Get-ChildItem $f.FullName -recurse -errorAction "SilentlyContinue" | Where-Object {-NOT $_.PSIscontainer} | Measure-object -Property Length -sum

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
                    # Processing the non-nested folder and get the size
                    if($NonFolder)
                    {
                        $stats=Get-ChildItem $pth | Measure-object -Property Length -sum

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

            Write-LogFile -LogText "Fetching the File Share size information remotely for $ServerInfo"
            try
            {
                # try with default logged domain credentials to fetch the file share size remotely
                $results=Invoke-Command -ScriptBlock $sb -ComputerName $ServerInfo -ArgumentList (,$shares) -HideComputerName 
            }
            catch
            {
                # Try with provided domain credentials
                $results=Invoke-Command -ScriptBlock $sb -ComputerName $ServerInfo -ArgumentList (,$shares) -HideComputerName -Credential $Creds
            }   
            return $results
        }
        catch
        {
            Write-LogFile -LogText "Exception while fecthed file share size information on $ServerInfo : $($error[0].Exception.Message)"
            $ExceptionCodes += $($error[0].Exception.Message)
            return $null
        }
    } 

    #################################### Function to get the installed applications #######################################
    Function Get-InstalledApplications
    {
        Param
        (
            [String]$Server,
            [pscredential]$Creds
        )

        try
        {   
            Write-LogFile -LogText "Fetching the Installed Applications on $Server"   		
		    # Feteching the installed applications
            if($Server -eq $hostname)
            {
                # Fetching the installed applications using the WMI Provider, credentials are not required if the target host is same as localhost
                $InstalledApplications = Get-WmiObject -Namespace "root/cimv2" -Class Win32_Product | Select-Object -Property Name, Version,Vendor
            }
            else
            {
                # credentials are required for remote hosts
                $InstalledApplications = Get-WmiObject -Namespace "root/cimv2" -Class Win32_Product -ComputerName $Server -Credential $Creds | Select-Object -Property Name, Version,Vendor
            }
				        
            # Making individual JSON inner Object for applications
            $AppCollection = @{}

            # Checking if the application are found on the server
            if($InstalledApplications)
            {
                Write-LogFile -LogText "Application are found the server $Server, preparing the JSON Data"
                foreach($app in $InstalledApplications)
                {
                    $EachApp = @{}
                    $EachApp.version = $app.Version
                    $EachApp.manufacturer = $app.Vendor
                    $AppCollection[$app.Name] = $EachApp
                }
            }
            else
            {
                # If application are not found
                $AppCollection = "No"
            }            
            return $AppCollection 
        }
        catch
        {
            Write-LogFile -LogText "Exception while fetching installed applications on $Server : $($error[0].exception.message)"
            $ExceptionCodes += $($error[0].Exception.Message)
            return $null
        }    
    }

    ############################ Function to get the installed RDS roles and features ####################################
    Function Get-InstalledRDSRoles
    {
        Param
        (
            [String]$Server,
            [pscredential]$Creds
        )

        try
        {
            Write-LogFile -LogText "Fetching the All Remote Desktop Features on $server"
		    # Fetching all features RDS roles installed on server
            if($Server -eq $hostname)
            {
                # No credentials are required if the target saerver same as localhost
                $RDSFeatures = Get-WindowsFeature -Name 'RDS-*' # -ErrorAction SilentleyContinue
            }
            else
            {
                # Fecthing roles and features of remote host with credentials
                $RDSFeatures = Get-WindowsFeature -Name 'RDS-*' -ComputerName $server -Credential $Creds #-ErrorAction SilentleyContinue
            }

            # Hash Object to hold the key-value pairs
            $RolesObj = @{}

            # If the RDS roles and features are found
            if($RDSFeatures)
            {
                Write-LogFile -LogText "RDS roles are available"
                $RDSCon = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Connection-Broker'}
                if($RDSCon.InstallState -eq "Installed")
                {
                    Write-LogFile -LogText "RDS Connection Broker role is installed"
                    $RolesObj['RDS-Connection-Broker'] = 'Yes'
                }
                else
                {
                    Write-LogFile -LogText "RDS Connection Broker feature is not installed"
                    $RolesObj['RDS-Connection-Broker'] = 'No'
                }
                               
                $RDSGW = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Gateway'}
                if($RDSGW.InstallState -eq "Installed")
                {
                    Write-LogFile -LogText "RDS Gateway role is installed"
                    $RolesObj['RDS-Gateway'] = 'Yes'
                }
                else
                {
                    Write-LogFile -LogText "RDS Gateway role is not installed"
                    $RolesObj['RDS-Gateway'] = 'No'
                }

                $RDSLic = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Licensing'}
                if($RDSLic.InstallState -eq "Installed")
                {
                    Write-LogFile -LogText "RDS Licensing role is installed"
                    $RolesObj['RDS-Licensing'] = 'Yes'                    
                }
                else
                {
                    Write-LogFile -LogText "RDS Licensing role is not installed"
                    $RolesObj['RDS-Licensing'] = 'No'                    
                }

                $RDSSSH = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-RD-Server'}
                if($RDSSSH.InstallState -eq "Installed")
                {
                    Write-LogFile -LogText "RDS Session Host role is installed"
                    $RolesObj['RDS-RD-Server'] = 'Yes'                    
                }
                else
                {
                    Write-LogFile -LogText "RDS Session Host role is not installed"
                    $RolesObj['RDS-RD-Server'] = 'No'                    
                }

                $RDSWeb = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Web-Access'}
                if($RDSWeb.InstallState -eq "Installed")
                {
                    Write-LogFile -LogText "RDS Web Access role is installed"
                    $RolesObj['RDS-Web-Access'] = 'Yes'                    
                }
                else
                {
                    Write-LogFile -LogText "RDS Web Access role is not installed"
                    $RolesObj['RDS-Web-Access'] = 'No'                    
                }
            }
            else
            {
                # Empty roles will added when No reuqired roles were found or when there is an exception while fetching the windows features
                Write-LogFile -LogText "RDS roles are not available"
                $RolesObj['RDS-Connection-Broker'] = 'No'
                $RolesObj['RDS-Gateway'] = 'No'
                $RolesObj['RDS-Licensing'] = 'No'
                $RolesObj['RDS-RD-Server'] = 'No'
                $RolesObj['RDS-Connection-Broker'] = 'No'
            }
            return $RolesObj
        }
        catch
        {
            Write-LogFile -LogText "Exception while fetching RDS Roles on $Server : $($error[0].exception.message)"
            $ExceptionCodes += $($error[0].Exception.Message)
            return $null
        }                        
    }

    #################################### function to get the installed Print Server roles #####################################
    Function Get-InstalledPrintServerRole
    {
        Param
        (
            [String]$Server,
            [pscredential]$Creds
        )

        try
        {
            Write-LogFile -LogText "Fetching Print Server roles on $server"
		    # Fetching all features Print server roles installed on server
            if($server -eq $hostname)
            {
                $PrintServices = Get-WindowsFeature -Name 'Print-Services' #-ErrorAction SilentleyContinue
            }
            else
            {
                $PrintServices = Get-WindowsFeature -Name 'Print-Services' -ComputerName $server -Credential $Creds #-ErrorAction SilentleyContinue            
            }

            # Hash Object to hold the key-value pairs
            $RolesObj = @{}

            # Checking if the Print server roles are available
            if($PrintServices)
            {
                # Checking if the Print server roles are Installed
                if($PrintServices.InstallState -eq 'Installed')
                {
                    Write-LogFile -LogText "Print Services feature is installed"
                    $RolesObj['Print-Services'] = 'Yes'              
                }
                else
                {
                    Write-LogFile -LogText "Print Services feature is not installed"                    
                    $RolesObj['Print-Services'] = 'No'
                }
            }
            else
            {
                Write-LogFile -LogText "File Server roles are not available"
                $RolesObj['Print-Services'] = 'No'
            }

            return $RolesObj
        }
        catch
        {
            Write-LogFile -FilePath $LogFilePath -LogText "There was an exception while fetching print server information on $Server.$($error[0].exception.message)"
            $ExceptionCodes += $($error[0].Exception.Message)
            return $null
        }
    }

    #################################### function to get the installed File Server roles #####################################
    Function Get-InstalledFileServerRole
    {
        Param
        (
            [String]$Server,
            [pscredential]$Creds
        )

        try
        {
            Write-LogFile -LogText "Fetching File Server roles on $server"
		    # Fetching all features roles installed on server
            if($server -eq $hostname)
            {
                $FileServices = Get-WindowsFeature -Name 'FS-FileServer' #-ErrorAction SilentleyContinue
            }
            else
            {
                $FileServices = Get-WindowsFeature -Name 'FS-FileServer' -ComputerName $server -Credential $Creds #-ErrorAction SilentleyContinue
            }

            # Hash object to hold the key-value pairs
            $RolesObj = @{}

            # Checking if the File Server roles are available
            if($FileServices)
            {
                # Checking if the File Server roles are installed
                if($FileServices.InstallState -eq 'Installed')
                {
                    Write-LogFile -LogText "File Server roles are installed"
                    $RolesObj['FS-FileServer'] = 'Yes'
                    #Write-LogFile -FilePath $LogFilePath -LogText "Fetching the File Shares information on $($server.ServerNames)"
                    #$FileSharesInfo = Get-FileShareSizes -ServerInfo $server -UName $USerName -Pwd $Password
                    #$Strings = $null

                    #if($FileSharesInfo)
                    #{
                    #    foreach($Ob in $FileSharesInfo)
                    #    {
                    #        $Strings += "$($Ob.Name);" 
                    #    }
                    #}
                    #else
                    #{
                    #    Write-LogFile -FilePath $LogFilePath -LogText "Did not fetch the Fileshare information or exception occured while tetching the details for $($server.ServerNames)"
                    #}           
                }
                else
                {
                    Write-LogFile -FilePath $LogFilePath -LogText "File Server role is not installed"
                    $RolesObj['FS-FileServer'] = 'No'
                }
                #$AllCollections += $o
            }
            else
            {
                Write-LogFile -LogText "File Server Roles are not available"
                $RolesObj['FS-FileServer'] = 'No'
            }
            return $RolesObj
        }
        catch
        {
            Write-LogFile -LogText "Exception while fetching file server information on $Server : $($error[0].exception.message)"
            $ExceptionCodes += $($error[0].Exception.Message)
            return $null
        }
    }

    ###################################### Function to Validate the provided parameters ######################################
    Function Validate-Param
    {
        try 
        {
            Write-LogFile -LogText "Validating Parameters: CSVFilePath."
            If([String]::IsNullOrEmpty($CSVFilePath))
            {
                Write-LogFile -LogText "Validation failed.CSVFilePath parameter value is empty."
                exit
            }

            Write-LogFile -LogText "Validating Parameters: UserName."
            If([String]::IsNullOrEmpty($UserName))
            {
                Write-LogFile -LogText "Validation failed.UserName parameter value is empty."
                exit
            }
            elseif($UserName -notlike "*\*")
            {
                Write-LogFile -LogText "The provided User Name is not a Valid format. It must be a Domain user"
                exit
            }else{}

            Write-LogFile -LogText "Validating Parameters: Password."
            If([String]::IsNullOrEmpty($Password))
            {
                Write-LogFile -LogText "Validation failed.Password parameter value is empty."
                exit
            }            
        }
        catch 
        {
            Write-LogFile -LogText "Exception while Validating the parameters : $($error[0].Exception.Message)"
            write-host "Exception while Validating the parameters : $($error[0].Exception.Message). Please retry with correct parameters"
            exit    
        }
    }
}
Process
{
    try
    {
        Write-LogFile -LogText "Validating the provided parameters"
        # Calling function to Validate Parameters
        Validate-Param
   
        Write-LogFile -LogText "Checking for the provided Servers list file path"
	    # Checking for the existence of the provided file
        if(Test-Path -Path $CSVFilePath)
        {
            Write-LogFile -LogText "Provided Serverslist file path available"
            # Reading the CSV Data
            $CSVdata = Import-Csv -Path $CSVFilePath

            Write-LogFile -LogText "Checking for the servers list file content"
            if($CSVdata)
            {
		        # Importing the servermanager modules to fetch the roles and features 
                Import-Module ServerManager

                # Creating JSON Object Array
                $JSONObjArray = New-Object System.Collections.ArrayList

                # Creating the Credential Object for connecting to Servers
                $Credentials = New-Object System.Management.Automation.PSCredential ($UserName, (ConvertTo-SecureString -AsPlainText -String $Password -Force))

                foreach($server in $CSVdata)
                {
                    # Creating JSON Object for each server
                    $JSONObj = New-Object psobject
                    $JSONObj | Add-Member -MemberType NoteProperty -Name computername -Value $($server.ServerNames)

                    Write-LogFile -LogText "#****** Processing the server $($server.ServerNames)*****#"
                    Write-LogFile -LogText "Checking for the connectivity for the server $($server.ServerNames)"

			        # Checking the rechability of the server
                    $ServerStatus = Get-WmiObject -Class Win32_PingStatus -Filter "Address=`'$($server.ServerNames)`'"
                    if($ServerStatus.StatusCode -eq 0)
                    {
                        Write-LogFile -LogText "$($server.ServerNames) is reachable"
                        $JSONObj | Add-Member -MemberType NoteProperty -Name Reachable -Value "YES"
                            
                        # Calling the function to get the Installed Applications Data
                        $InstalledApps = Get-InstalledApplications -Server $server.ServerNames -Creds $Credentials                                              
                        # Appending the Application data to Server's JSON Object
                        $JSONObj | Add-Member -MemberType NoteProperty -Name applications -Value $InstalledApps
                           
                        # Dictionary Object to hold the rols information for the server in loop
                        $AllRoles = @{}
                        # Function call to fetch RDS Roles information
                        $RDSRoles = Get-InstalledRDSRoles -Server $server.ServerNames -Creds $Credentials
                        $AllRoles += $RDSRoles

                        # Calling the Function to get print server roles information 
                        $PrintRoles = Get-InstalledPrintServerRole -Server $server.ServerNames -Creds $Credentials
                        $AllRoles += $PrintRoles

                        # Function call to fetch File server Roles information
                        $FileServerRoles = Get-InstalledFileServerRole -Server $server.ServerNames -Creds $Credentials
                        $AllRoles += $FileServerRoles

                        $JSONObj | Add-Member -MemberType NoteProperty -Name roles -Value $AllRoles
                        #$JSONObjArray += $JSONObj
                    }
                    else # if the Server is not reachable, mention it as Not reachable
                    {
                        Write-LogFile -LogText "$($server.ServerNames) was not reachable"
                        $JSONObj | Add-Member -MemberType NoteProperty -Name Reachable -Value "No"
                        # Empty JSON Properties incase the server is not reachabel
                        $NonReach = @{}
                        $NonReach1 = @{}
                        $JSONObj | Add-Member -MemberType NoteProperty -Name applications -Value $NonReach
                        $JSONObj | Add-Member -MemberType NoteProperty -Name roles -Value $NonReach1

                        #$JSONObjArray += $JSONObj
                    }
                    # Final JSON object for the processed server
                    $JSONObjArray += $JSONObj
                }
                # Final JSON object to hold the complete data for all servers
                $JSONObjFinal = @{}
                $JSONObjFinal["assessment_custom_result"] = $JSONObjArray
                $raw2 = $JSONObjFinal | ConvertTo-Json -Depth 5 | Out-File -FilePath "$PSScriptRoot\ServerInventory.json" -Force
            }
            Else
            {
                Write-LogFile -LogText "Server Names are not available in the provided file or did not get the CSV data"
                Write-Host "Server Names are not available in the provided file or did not get the CSV data"
                exit
            }
        }
        else
        {
            Write-Host "The Provided path for CSV does not exist. Please check the file and retry"
            Write-LogFile -LogText "The Provided path for CSV does not exist. Please check the file and retry"
            exit
        }
    }
    catch
    { 
        Write-Output "There was an exception. $($error[0].Exception.Message)"
        Write-Host "There was an exception. $($error[0].Exception.Message)"
        exit
    }
}
End
{
    $ProgressPreference = "Continue"
    if($ExceptionCodes)
    {
        Write-Host "Script executiong is completed, however few exceptions found. Please check the log file and JSON File and retry the script."
        Write-LogFile -LogText "Script executiong is completed,however few exceptions found. Please check the log file and JSON File and retry the script."
    }
    else 
    {
        Write-Host "Script executiong is completed successfully"
        Write-LogFile -LogText "Script executiong is completed successfully"        
    }
    exit
}
