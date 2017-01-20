
    param
    (
        [parameter(Mandatory=$true)]
        [string]$Subscription,
        [parameter(Mandatory=$false)]
        [string]$ImportFilePath,
        [parameter(Mandatory=$true)]
        [ValidateSet("Windows","Linux")]
        [string]$OSType,
        [parameter(Mandatory=$true)]
        [string]$ImageFamily,
        [parameter(Mandatory=$true)]
        [string[]]$VMNames,
        [parameter(Mandatory=$true)]
        [ValidateSet("ExtraSmall","Small","Medium","Large","ExtraLarge","A5","A6","A7","A8","A9","Basic_A0","Basic_A1","Basic_A2","Basic_A3","Basic_A4","Standard_D1","Standard_D2","Standard_D3","Standard_D4",
                         "Standard_D11","Standard_D12","Standard_D13","Standard_D14")]
        [string]$Size,
        [parameter(Mandatory=$true)]
        [string]$Username,
        [parameter(Mandatory=$false)]
        [string]$Password,
        #[parameter(Mandatory=$false)]
        #[string]$Key,
        [parameter(Mandatory=$true)]
        [string]$Service,
        [parameter(Mandatory=$true)]
        [string]$VNetName,
        [parameter(Mandatory=$true)]
        [string]$Subnet,
        [parameter(Mandatory=$true)]
        [string[]]$IPAddress
        [parameter(Mandatory=$true)]
        [string]$Storagename,
        [parameter(Mandatory=$true)]
        [string]$Location,
        [parameter(Mandatory=$false)] # Added for the reserved Ip functionality
        [string]$ReservedIP = $null,          # Added for the reserved Ip functionality
        [parameter(Mandatory=$false)]
        [ValidateSet("RODC","ChefMaster","ChefSlave","ChefRole","ADandDC","Test","DFS","Splunk","SQLServer")]
        [string]$Role
    )

    #Check for the Elevated Mode
    if((Is-Admin) -eq $false)
    {
        Write-Error "Must run PowerShell in elevated mode. Please run the PowerShell as Run As Administrator"
        exit
    }

    $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
    # Importing required modules for the script
    Import-Module $PSScriptRoot\MasterExceptionHandling.psm1
    Import-Module $PSScriptRoot\StorageAccountModule.psm1
    Import-Module $PSScriptRoot\CloudServiceModule.psm1

    if($OSType -eq "Windows")
    {
        if($PSBoundParameters.Count -lt 14)
        {
            Write-Host -ForegroundColor Red "The Minimum parameters for Windows are 'Subscription','OSType','ImageFamily','NumberOfVMs','VMName1','Size','UserName','Password','Service','VNetName','SubnetName','IPAddress1','StorageName','Affinty/Location'"
            Write-Host -ForegroundColor Red "Password Parameter should be provided."
            exit
        }
    }
    else
    {
        if($PSBoundParameters.Count -lt 13)
        {
            Write-Host -ForegroundColor Red "The Minimum parameters for Linux are 'Subscription','OSType','ImageFamily','NumberOfVMs','VMName1','Size','UserName','Service','VNetName','SubnetName','IPAddress1','StorageName','Affinty/Location'"
            exit
        } 
    }
    #preparing the Azure connection
    $Connection = ConnectTo-Azure -Subscription $subscription -ImportFilePath $ImportFilePath
    if($connection -ieq $true)
    {    
        try
        {
            if($OSType -eq "Windows")
            {
                if(!$Password)
                {
                    Write-Host -ForegroundColor Red "Missing Password parameter"
                    exit
                }
            }
            if($Role -in ("DFS","RODC"))
            {
                try
                {
                    $data = Set-AzureVNetConfig -ConfigurationPath $PSScriptRoot\OriginalVnet.xml
                    if($data.OperationStatus -eq "Succeeded")
                    {
                        sleep(30)
                    }
                    else
                    {
                        Write-Host -ForegroundColor Red "Unable to set the DNS entry"
                        exit 1
                    }
                }
                catch
                {
                    $Error[0].Exception.Message
                }
            }
            if (!($VMNames.length -eq $IPAddress.length)) 
            {
                write-host "The number of IPAddress should be equal to number of VMNames"
                exit
            }
            # Fucntion call to validate the Virtual Machine names
            foreach($vmsingle in $VMNames)
            {
                $VmValid = Validate-VirtualMachineName -Name $vmsingle
                if($VmValid -eq $false)
                {
                    exit
                }
            }
            # Fucntion call to validate the IP Addresses
            foreach($ip in $IPAddress)
            {
                $IPvalid = Validate-IPAddress -IPAddress $ip
                if($IPvalid -eq $false)
                {
                    exit
                }
            }
            # Function call to username pattern is valid
            $UnameValid = Validate-UserName -User $Username
            if($UnameValid -eq $false)
            {
                exit
            }
            # function call to check the password is valid
            if($Password)
            {
                $PwdValid = Validate-PassWord -Passwrd $Password
                if($PwdValid -eq $false)
                {
                    exit
                }
            }
            # Fucntion call to validate the Vnet and Subnet names
            $VnetParams = @($VNetName,$SubnetName)
            foreach($VnetParam in $VnetParams)
            {
                $VnetValid = Validate-VNetParameterNames -Name $VnetParam
                if($VnetValid -eq $false)
                {
                    exit
                }
            }
            # fucntion call to validate the Storage names
            $StoreNameValid = Validate-StorageName -StorageName $StorageName
            if($StoreNameValid -ne $true)
            {
                exit
            }
            # fucntion call to validate the Cloud Service name
            $ValidateCSname = Validate-CloudServiceName -ServiceName $Service
            if($ValidateCSname -ieq $false)
            {
                exit
            }
            # Validating the Location
            $locValid = ValidateLocation -Location $Location # fucntion call to validate the location
            if($locValid -eq $null)
            {
                exit
            }
            <#if($ReservedIP)
            {
                $Reserv = ReservedIP -Name $ReservedIP -Location $Location -ServiceName $Service
            }
            else
            {
                $Reserv = $null
            }#>   
            #Verifiying The Vnet,Subnet And IPAddress Provided
            # Loading the file
            . $PSScriptRoot\VMVNetEndPoint.ps1
            foreach($IPAdd in $IPAddress)
            { 
                $VnetSubnetIPValid = ValidateVNetSubnetIPForVM -GivenSubNet $SubnetName -GivenIPAddress $IPAdd -GivenVnet $VNetName -Location $Location
            }

            switch -CaseSensitive ($VnetSubnetIPValid)
            {
                $false {Write-Host -ForegroundColor Red "Please check the Vnet, Subnet and IPAddress and Retry";exit 11}
                "error" {Write-Host -ForegroundColor Red "Netwrok error";exit 1}
            }
            # Calling the function to get Latest Image for Selected OS      
            $VMImage = VMImage -ImageName $ImageFamily -Location $Location -OSType $OSType
            switch -CaseSensitive ($VMImage)
            {
                #"error" {Write-Host -ForegroundColor Red "Net work error";exit 1}
                "image" {Write-Host -ForegroundColor Red "Image is not available for selected $ImageFamily Version";exit 104}
                "region" {Write-Host -ForegroundColor Red "Image is not available in the region";exit 104}
                default {Write-Host -ForegroundColor Green "Selected OS Images is: $VMImage";break}
            }        
            # Storage Account Checking
            #Checking for the Storage Existence
            Write-Host -ForegroundColor Green "Checking for the storage....."
            $storageExist = Test-AzureName -Storage $storagename
            if(!$storageExist)
            {
                # creating storage based on Location
                $Cstor = Create-StorageAccount -StorageName $storagename -ContainerName vhds -Location $Location -GeoReplicaStore $false
                if($Cstor -eq $true)
                {
                   Write-Host -ForegroundColor Green "The Storage account $StorageAccount has been created successfully in this $Location ." 
                }
                else
                {
                    exit
                }
            }
            else
            {   # Fucntion call to check the storage existence in subscription
                $StoreInSub = Is-Storage -Storage $Storagename
                if($StoreInSub -ne $null)
                {   # Checking for the Storage existence in the cloud service, if exist then does it associated with location or affinity group
                    if(($StoreInSub.Location -ieq $Location) -or ($StoreInSub.AffinityGroup -ieq $AffinityGroup))
                    {
                        # Setting the storage account
                        $success = Set-AzureSubscription -SubscriptionName $Subscription -CurrentStorageAccountName $storagename
                        if((Get-AzureSubscription -Current -ExtendedDetails).CurrentStorageAccountName -ieq $storagename)
                        {
                            Write-Host -ForegroundColor Green "The Storage has been set successfully"
                        }
                        else
                        {
                            Write-Host -ForegroundColor Red "Error occured while setting the storage account"
                            exit
                        }
                    }
                    else
                    {
                        Write-Host -ForegroundColor Red "The Storage $storagename account is not associated with your affinity group or Location"
                        exit
                    }
                }
                else
                {
                    Write-Host -ForegroundColor Red "The Storage account is not exit in your subscription"
                    exit
                }
            }
            # Cloud Service Checking
            #Checking for Cloud Service existence
            Write-Host -ForegroundColor Green "Checking for the Cloud Service..."
            $ServiceExist = Test-AzureName -Service $Service
            if(!$ServiceExist)
            {   
                # Calling the fucntion to create cloud service if Location been provided
                $CSer = Create-CloudService -Name $Service -Loc $Location
                if($CSer -ieq $true)
                {
                    Write-Host -ForegroundColor Green "The Cloud Service has been successfully created in this $Location Location"
                }
                else
                {
                    exit
                }
                for($i = 0;$i -lt $VMNames.length;$i++)
                {
                    # Fucntion call to create the Virtual Machine
                    $Msg = CreateVirtualMachine -OSType $OSType -VMImage $VMImage -VMName $vms[$i] -Size $Size -Service $Service -Username $Username -Password $Password -VNetName $VNetName -SubnetName $SubnetName -IPAddress $ips[$i] -Role $Role # -ReservedIP $Reserv
                    Switch -CaseSensitive ($Msg)
                    {
                        #"error" {Write-Host -ForegroundColor Red "Network error";exit 1}
                        $false {Write-Host -ForegroundColor Red "Error occured while creating the Virtual Machine";exit 107}
                        $true {
                                    #Write-Host -ForegroundColor Green "The Virtual Machine has been provisioned successfully and is in ReadyRole";break}
                                    if($OSType -ieq "Windows")
                                    {
                                            $vmStat = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                            #$vms[$i]
                                            while(!($vmStat.ResourceExtensionStatusList))
                                            {
                                                sleep(30)
                                                $vmStat = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                            }
                                            while($vmStat.ResourceExtensionStatusList[1].ExtensionSettingStatus.Status -in ("Installing","Transitioning"))
                                            {
                                                sleep(30)
                                                $vmStat = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                            }
                                            $rslist = ($vmStat.ResourceExtensionStatusList)[1].ExtensionSettingStatus.SubStatusList | Select Name, @{"Label"="Message";Expression = {$_.FormattedMessage.Message }}
                                            if(!$rslist -or !($rslist[1].Message))
                                            {                        
                                                sleep(300)
                                                $vmRdy = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                                while($vmRdy.InstanceStatus -ne "ReadyRole")
                                                {
                                                    sleep(20)
                                                    $vmRdy = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                                }
                                                . $PSScriptRoot\InstallWinRMCertAzureVM.ps1 -SubscriptionName $subscription -ServiceName $Service -Name $vms[$i]
                                                $uri = Get-AzureWinRMUri -ServiceName $Service -Name $vms[$i]
                                                $secPassword = ConvertTo-SecureString $Password -AsPlainText -Force
                                                $credential = New-Object System.Management.Automation.PSCredential($Username, $secPassword)
                                                if($Role -eq "ADandDC")
                                                {
                                                    Write-Host -ForegroundColor Green "The AD server has been provisioned successfully"
                                                    Write-Host -ForegroundColor Green "Checking for the AD and DS configuration...."
                                                    Invoke-command -ConnectionUri $uri -Credential $credential -ScriptBlock{
                                                        try
                                                        {
                                                            Import-Module ActiveDirectory
                                                            $data = Get-ADDomain
                                                            if($data)
                                                            {
                                                                $data
                                                                write-host -ForegroundColor Green "AD Server has been provisioned successfully"
                                                            } 
                                                            else
                                                            {
                                                                Write-Host -ForegroundColor Red "AD and DNS was not configured properly"
                                                            }           
                                                        }
                                                        catch
                                                        {
                                                            write-host "Error while running command"
                                                            exit
                                                        }
                                                    }
                                                    <#$data = Set-AzureVNetConfig -ConfigurationPath $PSScriptRoot\OriginalVnet.xml
                                                    if($data.OperationStatus -eq "Succeeded")
                                                    {
                                                        sleep(30)
                                                        #Write-Host -ForegroundColor Green "Virtual Network is updated with DNS Entry"
                                                    }
                                                    else
                                                    {
                                                        Write-Host -ForegroundColor Red "Unable to set the DNS entry"
                                                        exit 1
                                                    }#>
                                                }
                                                elseif($Role -eq "DFS")
                                                {
                                                    Write-Host -ForegroundColor Green "The DFS server has been provisioned successfully"
                                                    #Write-Host -ForegroundColor Green "Checking for the AD and DS configuration...."
                                                    Invoke-command -ConnectionUri $uri -Credential $credential -ScriptBlock{
                                                        try
                                                        {
                                                            Import-Module ServerManager
                                                            $NameSpace = (Get-WindowsFeature -Name "FS-DFS-Namespace").Installed
                                                            $Replication = (Get-WindowsFeature -Name "FS-DFS-Replication").Installed

                                                            if(($NameSpace -eq $true) -and ($Replication -eq $true))
                                                            {
                                                                Write-Host -ForegroundColor Green "DFS Roles have been Configured successfully"
                                                                $Domain = [System.Net.DNS]::GetHostByName('').HostName
                                                                Write-Host -ForegroundColor Green "Serever's Domain is: " $Domain
                                                                $x=hostname
                                                                mkdir C:\DFSRoot3
                                                                mkdir C:\DFSRoot3\SHARE1
                                                                net share SHARE1=C:\DFSRoot3\SHARE1
                                                                #dfsutil root addDom \\$x\SHARE1 "demo"
                                                                write-host -ForegroundColor Green "DFS Server has been provisioned successfully"
                                                            } 
                                                            else
                                                            {
                                                                Write-Host -ForegroundColor Red "DFS was not configured successfully"
                                                                exit
                                                            }           
                                                        }
                                                        catch
                                                        {
                                                            write-host "Error while running command"
                                                            exit
                                                        }
                                                    }
                                                }
                                                elseif($Role -eq "RODC")
                                                {
                                                    Write-Host -ForegroundColor Green "The RODC server has been provisioned successfully"
                                                    Write-Host -ForegroundColor Green "Checking for the RODC configuration...."
                                                    Invoke-command -ConnectionUri $uri -Credential $credential -ScriptBlock{
                                                        try
                                                        {
                                                            Import-Module ActiveDirectory
                                                            $data = Get-ADDomainController -filter {isreadonly -eq $true}
                                                            if($data)
                                                            {
                                                                $data
                                                                write-host -ForegroundColor Green "RODC Server has been provisioned successfully"
                                                            } 
                                                            else
                                                            {
                                                                Write-Host -ForegroundColor Red "AD and DNS was not configured properly"
                                                            }           
                                                        }
                                                        catch
                                                        {
                                                            write-host "Error while running command"
                                                            exit
                                                        }
                                                    }
                                                }
                                                elseif($Role -eq "Splunk")
                                                {
                                                    Write-Host -ForegroundColor Green "The Splunk server has been provisioned successfully"
                                                    Write-Host -ForegroundColor Green "Checking for the Splunk configuration...."
                                                    Invoke-command -ConnectionUri $uri -Credential $credential -ScriptBlock{
                                                        try
                                                        {
                                                                sleep(10)
                                                                while(1)
                                                                {
                                                                    $splunkdemon = Get-Service | Where-Object {$_.Name -eq "splunkd"} | select Status
                                                                    if(($splunkdemon.Status -eq $null) -or ($splunkdemon.Status -ne "Running") )
                                                                    {
                                                                        sleep(25)
                                                                    }
                                                                    else
                                                                    {
                                                                        Get-Service | Where-Object {$_.Name -eq "splunkd"}
                                                                        break
                                                                    }
                                                                }
                                                        }
                                                        catch
                                                        {
                                                                        write-host "Error while running command"
                                                                        exit
                                                        }
                                                    }
                                                    $endData = $vmRdy | Add-AzureEndpoint -Name 'Splunk' -Protocol tcp -LocalPort 8000 -PublicPort 8000 | Update-AzureVM
                                                    if($endData.OperationStatus -eq "Succeeded")
                                                    {
                                                        #
                                                    }
                                                    else
                                                    {
                                                        Write-Host -ForegroundColor Red "error while adding the end point for Splunk"
                                                        exit
                                                    }
                                                }
                                                elseif($Role -eq "SQLServer")
                                                {
                                                    Write-Host -ForegroundColor Green "Instance has been provisioned and the SQL Server configuration is in progress...."
                                                    Write-Host -ForegroundColor Green "Checking for the SQL configuration...."
                                                    Invoke-command -ConnectionUri $uri -Credential $credential -ScriptBlock{
                                                        try
                                                        {
                                                                sleep(10)
                                                                while(1)
                                                                {
                                                                    $sqlserver = Get-Service | Where-Object {$_.Name -eq "MSSQLSERVER"} | select Status
                                                                    if(($sqlserver.Status -eq $null) -or ($sqlserver.Status -ne "Running") )
                                                                    {
                                                                        sleep(25)
                                                                    }
                                                                    else
                                                                    {
                                                                        Get-Service | Where-Object {$_.Name -eq "MSSQLSERVER"}
                                                                        break
                                                                    }
                                                                }
                                                        }
                                                        catch
                                                        {
                                                                        write-host "Error while running command"
                                                                        exit
                                                        }
                                                    }
                                                    
                                                }
                                                else
                                                {
                                                    write-host -ForegroundColor Red "Instance has been provisioned successfully"
                                                }
                                            }
                                            else
                                            {
                                                Write-Host -ForegroundColor Red "There was an error while configuring executing the commands"
                                                exit
                                            }
                                        }
                                        else
                                        {
                                            Write-Host -ForegroundColor Green "The Virtual Machine has been provisioned successfully and is in ReadyRole"
                                        }
                                        break
                                }
                        "name" {Write-Host -ForegroundColor Red "Name conflict for the VM. VM already exist with this name";exit 108}
                        "OS" {Write-Host -ForegroundColor Red "The OS type is supported as of now";exit 109}
                    }
                    #### Adding End Points ###############################################################
                    <#$EndMsg = CreateEndPoints -ServiceName $Service -VMName $vms[$i]
                    Switch -CaseSensitive ($EndMsg)
                    {
                        #"error" {Write-Host -ForegroundColor Red "Network error";exit 1}
                        $false {Write-Host -ForegroundColor Red "Error occured while creating the end points to Virtual Machine";exit 110}
                        $true {Write-Host -ForegroundColor Green "End points have been added successfully";break}
                    }#>
               }
            }
            else
            {   # Checking for the cloud service in subscription. Calling the fucntion
                $ServicesInSub = IsCloudServiceName -ServiceName $Service          
                if($ServicesInSub -ne $null)
                {    # if cloud service exists, then check does it associated with location or affinity  provided
                     if(($ServicesInSub.AffinityGroup -ieq $affinitygroup) -or ($ServicesInSub.Location -ieq $Location))
                     {
                         Write-Host -ForegroundColor Red "The Cloud Service $Service is already exist in Your Subscription"
                         if((Read-Host "Do you want use this Cloud Service:y/n") -imatch "y")
                         {  # Function call to create the virtual machine
                            for($i = 0;$i -lt $NumberofVMs;$i++)
                            {
                                # loading the script file
                                . $PSScriptRoot\VMVNetEndPoint.ps1
                                # Fucntion call to create the Virtual Machine
                                $Msg = CreateVirtualMachine -OSType $OSType -VMImage $VMImage -VMName $vms[$i] -Size $Size -Service $Service -Username $Username -Password $Password -VNetName $VNetName -SubnetName $SubnetName -IPAddress $ips[$i] -Role $Role # -ReservedIP $Reserv
                                Switch -CaseSensitive ($Msg)
                                {
                                    #"error" {Write-Host -ForegroundColor Red "Network error";exit 1}
                                    $false {Write-Host -ForegroundColor Red "Error occured while creating the Virtual Machine";exit 107}
                                    $true {
                                            if($OSType -ieq "Windows")
                                            {
                                                sleep(90)
                                                $vmStat = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                                while($vmStat.ResourceExtensionStatusList[1].ExtensionSettingStatus.Status -in ("Installing","Transitioning"))
                                                {
                                                    sleep(30)
                                                    $vmStat = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                                }
                                                $rslist = ($vmStat.ResourceExtensionStatusList)[1].ExtensionSettingStatus.SubStatusList | Select Name, @{"Label"="Message";Expression = {$_.FormattedMessage.Message }}
                                                if(!$rslist -or !($rslist[1].Message))
                                                {                        
                                                    sleep(300)
                                                    $vmRdy = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                                    while($vmRdy.InstanceStatus -ne "ReadyRole")
                                                    {
                                                        sleep(20)
                                                        $vmRdy = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                                    }
                                                    . $PSScriptRoot\InstallWinRMCertAzureVM.ps1 -SubscriptionName $subscription -ServiceName $Service -Name $vms[$i]
                                                    $uri = Get-AzureWinRMUri -ServiceName $Service -Name $vms[$i]
                                                    $secPassword = ConvertTo-SecureString $Password -AsPlainText -Force
                                                    $credential = New-Object System.Management.Automation.PSCredential($Username, $secPassword)
                                                    if($Role -eq "ADandDC")
                                                    {
                                                        Write-Host -ForegroundColor Green "The AD server has been provisioned successfully"
                                                        Write-Host -ForegroundColor Green "Checking for the AD and DS configuration...."
                                                        Invoke-command -ConnectionUri $uri -Credential $credential -ScriptBlock{
                                                            try
                                                            {
                                                                Import-Module ActiveDirectory
                                                                $data = Get-ADDomain
                                                                if($data)
                                                                {
                                                                    $data
                                                                    write-host -ForegroundColor Green "AD Server has been provisioned successfully"
                                                                } 
                                                                else
                                                                {
                                                                    Write-Host -ForegroundColor Red "AD and DNS was not configured properly"
                                                                    exit
                                                                }           
                                                            }
                                                            catch
                                                            {
                                                                write-host "Error while running command"
                                                            }
                                                        }
                                                        <#$data = Set-AzureVNetConfig -ConfigurationPath $PSScriptRoot\OriginalVnet.xml
                                                        if($data.OperationStatus -eq "Succeeded")
                                                        {
                                                            sleep(30)
                                                            #Write-Host -ForegroundColor Green "Virtual Network is updated with DNS Entry"
                                                        }
                                                        else
                                                        {
                                                            Write-Host -ForegroundColor Red "Unable to set the DNS entry"
                                                            exit 1
                                                        }#>
                                                    }
                                                    elseif($Role -eq "DFS")
                                                    {
                                                        Write-Host -ForegroundColor Green "The DFS server has been provisioned successfully"
                                                        Write-Host -ForegroundColor Green "Checking for the AD and DS configuration...."
                                                        Invoke-command -ConnectionUri $uri -Credential $credential -ScriptBlock{
                                                            try
                                                            {
                                                                Import-Module ServerManager
                                                                $NameSpace = (Get-WindowsFeature -Name "FS-DFS-Namespace").Installed
                                                                $Replication = (Get-WindowsFeature -Name "FS-DFS-Replication").Installed

                                                                if(($NameSpace -eq $true) -and ($Replication -eq $true))
                                                                {
                                                                    Write-Host -ForegroundColor Green "DFS Roles have been Configured successfully"
                                                                    $Domain = [System.Net.DNS]::GetHostByName('').HostName
                                                                    Write-Host -ForegroundColor Green "Serever's Domain is: " $Domain
                                                                    $x=hostname
                                                                    mkdir C:\DFSRoot3
                                                                    mkdir C:\DFSRoot3\SHARE1
                                                                    net share SHARE1=C:\DFSRoot3\SHARE1
                                                                    #dfsutil root addDom \\$x\SHARE1 "demo"
                                                                    write-host -ForegroundColor Green "DFS Server has been provisioned successfully"
                                                                } 
                                                                else
                                                                {
                                                                    Write-Host -ForegroundColor Red "DFS was not configured successfully"
                                                                    exit
                                                                }           
                                                            }
                                                            catch
                                                            {
                                                                write-host "Error while running command"
                                                            }
                                                        }
                                                    }
                                                    elseif($Role -eq "RODC")
                                                    {
                                                    Write-Host -ForegroundColor Green "The RODC server has been provisioned successfully"
                                                    Write-Host -ForegroundColor Green "Checking for the RODC configuration...."
                                                    Invoke-command -ConnectionUri $uri -Credential $credential -ScriptBlock{
                                                    try
                                                                {
                                                                    Import-Module ActiveDirectory
                                                                    $data = Get-ADDomainController -filter {isreadonly -eq $true}
                                                                    if($data)
                                                                    {
                                                                        $data
                                                                        write-host -ForegroundColor Green "RODC Server has been provisioned successfully"
                                                                    } 
                                                                    else
                                                                    {
                                                                        Write-Host -ForegroundColor Red "RODC was not configured properly"
                                                                    }           
                                                                }
                                                                catch
                                                                {
                                                                    write-host "Error while running command"
                                                                    exit
                                                                }
                                                        }
                                                    }
                                                    elseif($Role -eq "Splunk")
                                                    {
                                                        Write-Host -ForegroundColor Green "The Splunk server has been provisioned successfully"
                                                        Write-Host -ForegroundColor Green "Checking for the Splunk configuration...."
                                                        Invoke-command -ConnectionUri $uri -Credential $credential -ScriptBlock{
                                                            try
                                                            {
                                                                    sleep(10)
                                                                    while(1)
                                                                    {
                                                                        $splunkdemon = Get-Service | Where-Object {$_.Name -eq "splunkd"} | select Status
                                                                        if(($splunkdemon.Status -eq $null) -or ($splunkdemon.Status -ne "Running") )
                                                                        {
                                                                            sleep(25)
                                                                        }
                                                                        else
                                                                        {
                                                                            Get-Service | Where-Object {$_.Name -eq "splunkd"}
                                                                            break
                                                                        }
                                                                    }
                                                            }
                                                            catch
                                                            {
                                                                write-host "Error while running command"
                                                                exit
                                                            }
                                                        }
                                                    }
                                                    elseif($Role -eq "SQLServer")
                                                    {
                                                        Write-Host -ForegroundColor Green "Instance has been provisioned and the SQL Server configuration is in progress....."
                                                        Write-Host -ForegroundColor Green "Checking for the SQL configuration...."
                                                        Invoke-command -ConnectionUri $uri -Credential $credential -ScriptBlock{
                                                            try
                                                            {
                                                                    sleep(10)
                                                                    while(1)
                                                                    {
                                                                        $sqlserver = Get-Service | Where-Object {$_.Name -eq "MSSQLSERVER"} | select Status
                                                                        if(($sqlserver.Status -eq $null) -or ($sqlserver.Status -ne "Running") )
                                                                        {
                                                                            sleep(25)
                                                                        }
                                                                        else
                                                                        {
                                                                            Get-Service | Where-Object {$_.Name -eq "MSSQLSERVER"}
                                                                            break
                                                                        }
                                                                    }
                                                            }
                                                            catch
                                                            {
                                                                            write-host "Error while running command"
                                                                            exit
                                                            }
                                                        }
                                                        
                                                    }
                                                    else
                                                    {
                                                        #
                                                    }
                                                }
                                                else
                                                {
                                                    Write-Host -ForegroundColor Red "There was an error while configuring executing the commands"
                                                    exit
                                                }
                                            }
                                            else
                                            {
                                                Write-Host -ForegroundColor Green "The Virtual Machine has been provisioned successfully and is in ReadyRole"
                                            }
                                            break
                                          }
                                    "name" {Write-Host -ForegroundColor Red "Name conflict for the VM. VM already exist with this name";exit 108}
                                    "OS" {Write-Host -ForegroundColor Red "The OS type is supported as of now";exit 109}
                                }
                                #### Adding End Points #################################################################
                                <# The following code disables and same functionality available with EndPointsOps.ps1
                                $EndMsg = CreateEndPoints -ServiceName $Service -VMName $vms[$i] -num $i
                                Switch -CaseSensitive ($EndMsg)
                                {
                                    #"error" {Write-Host -ForegroundColor Red "Network error";exit 1}
                                    $false {Write-Host -ForegroundColor Red "Error occured while creating the end points to Virtual Machine";exit 110}
                                    $true {Write-Host -ForegroundColor Green "End points have been added successfully";break}
                                }#>
                             }
                         }
                         else
                         {
                            exit
                         }
                     }
                     else
                     {
                        Write-Host -ForegroundColor Red "The Cloud Service exist, but not associated with the Affinity Group or the Location provided"
                        exit 76
                     }
                }
                else
                {
                     Write-Host -ForegroundColor Red "The cloud service is not exit in your subscription"
                     exit 74 
                }     
            }
        }
        catch [System.Net.Http.HttpRequestException]
        {
            Write-Host -ForegroundColor Red "Exception occured while executing the commands. It is due to the connectivity to internet"
            #exit 1
            Throw $_
        }    
    }
    else
    {
        Write-Host -ForegroundColor Red "The Subscription does not exist"
        exit 10
    }