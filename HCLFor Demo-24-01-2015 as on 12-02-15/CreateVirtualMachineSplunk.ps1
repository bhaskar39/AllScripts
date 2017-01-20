<#######################################################################################################################################
#    .VERSION
#        Script File Name  :VMVNetEndPoint.ps1
#        Date of Updation  :10-07-2014
#
#    .AUTHOR
#
#        Bhaskar Desharaju
#
#    .SYNOPSIS
#    
#        This script creates the Virtual Machine in Virtual Network
#
#    .DESCRIPTION
#    
#        This script is to create the Virtual Machines in the VirtuaL network in a given subnet with a static IP from the Virtual Network address Space range.
#        It will call the master exception handling script fucntions to validate the input parameters. It can also creates the multiple virtual machines based on the 
#        numofVMs value and also expects the role for the virtual machine but it is optional.

        It creates the cloud service and storage account if they are existed,otherwise uses the existing services.

        Once the VM got provisoned successfully, it calls a function to add the end points to the virtual machine.

    .EXAMPLE
        
       It Includes the following scripts.

       MasterExceptionHandling.ps1 to handle the exceptions

       StorageAccountManagement.ps1 to create the storage account if not existed

       CloudService to create the cloud service if not existed

       VMVNetEndPoint.ps1 to create,validate vnet,Subnet Ip Address and finally to create the end points

        
####################################################################################################################################################>

    #region InputParameters
    param(
        # Azure Subscription Name
        [parameter(Mandatory=$true)]
        [string]$subscription,
        # Path to .publishSettingsFile
        [parameter(Mandatory=$false)]
        [string]$ImportFilePath,
        # Operting System type i.e Windows or Linux
        [parameter(Mandatory=$true)]
        [ValidateSet("Windows","Linux")]
        [string]$OSType,
        #[parameter(Mandatory=$true)]
        # Image family, Server OS full name
        [parameter(Mandatory=$true)]
        [string]$ImageFamily,
        # Virtual Machine name
        [Parameter(Mandatory=$true)]
        [ValidateSet(1,2,3)]
        [int]$NumberofVMs,
        [parameter(Mandatory=$true)]
        [string]$VMName1,
        [parameter(Mandatory=$false)]
        [string]$VMName2,
        [parameter(Mandatory=$false)]
        [string]$VMName3,
        # Virtual Machine Size
        [parameter(Mandatory=$true)]
        [ValidateSet("ExtraSmall","Small","Medium","Large","ExtraLarge","A5","A6","A7","A8","A9","Basic_A0","Basic_A1","Basic_A2","Basic_A3","Basic_A4","Standard_D1","Standard_D2","Standard_D3","Standard_D4",
                         "Standard_D11","Standard_D12","Standard_D13","Standard_D14")]
        [string]$Size,
        # Username for VM Instance
        [parameter(Mandatory=$true)]
        [string]$Username,
        # Passoword for VM Instance
        [parameter(Mandatory=$false)]
        [string]$Password,
        # Hosted Service name
        [parameter(Mandatory=$true)]
        [string]$Service,
        # Virtual Network Name
        [parameter(Mandatory=$true)]
        [string]$VNetName,
        # Subnet name in the virtual Network
        [parameter(Mandatory=$true)]
        [string]$SubnetName,
        # IP address from Virtual Network
        [parameter(Mandatory=$true)]
        [string]$IPAddress1,
        [parameter(Mandatory=$false)]
        [string]$IPAddress2,
        [parameter(Mandatory=$false)]
        [string]$IPAddress3,
        # Storage name for the Virtual Machine
        [parameter(Mandatory=$true)]
        [string]$storagename,
        # Affinity group name
        [parameter(Mandatory=$true,ParameterSetName="Set1")]
        [string]$affinitygroup,
        # Azure Provided regions
        [parameter(Mandatory=$true,ParameterSetName="Set2")]
        [string]$Location,
        [parameter(Mandatory=$false,ParameterSetName="Set2")] # Added for the reserved Ip functionality
        [string]$ReservedIP = $null,          # Added for the reserved Ip functionality
        [parameter(Mandatory=$false)]
        [ValidateSet("RODC","ChefMaster","ChefSlave","ChefRole","ADandDC","Test","DFS")]
        [string]$Role

    )
    #endregion
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
    $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
    # Loading Master file for exceptions handling
    . $PSScriptRoot\MasterExceptionHandling.ps1
    #Checking for the Azure Module Installation
    $ModulePath = CheckModule
    if($ModulePath -match "[\\]")
    {
        Write-Host "Importing the required Module..."
        Import-Module $ModulePath
    }
    elseif($ModulePath -eq $null)
    {
        Write-Host "Modules are not available.."
        exit 4
    }else{}
    Write-Host -ForegroundColor Green "Checking for Subscription existence..."
    #Checking for the Subscription exist
    $SubExist = Subscription $subscription $ImportFilePath
#************************************************* Fcuntion to check the storage exists **************************************************
    function IsStorage
    {
        Param(
            [string]$Storage
            )
        try
        {
            $Stores = Get-AzureStorageAccount | Where-Object {$_.StorageAccountName -ieq $Storage}            
            return $Stores           
        }
        catch [System.Net.Http.HttpRequestException]
        {
           Throw $_
        }
    }
#*********************************************** function to check the cloud service exists **********************************************
    function IsCloudServiceName
    {
        param(
            [Parameter(Mandatory=$true)] 
            [string]$ServiceName
             )
       try
       {
            $NameAvailableInSub = Get-AzureService | Where-Object {$_.ServiceName -ieq $ServiceName}
            return $NameAvailableInSub           
        }
        catch [System.Net.Http.HttpRequestException]
        {
           Throw $_
        }
    }
    if($SubExist -match $true)
    {    
        try
        {
            #Check for the Elevated Mode
            if((IsAdmin) -eq $false)
	        {
		        Write-Error "Must run PowerShell in elevated mode."
		        exit 3
	        }
            # Selecting the Subscription    
            $sub = Select-AzureSubscription -SubscriptionName $subscription
            # function call to check the vm names
            if($OSType -eq "Windows")
            {
                if(!$Password)
                {
                    Write-Host -ForegroundColor Red "Missing Password parameter"
                    exit 103
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
                        #Write-Host -ForegroundColor Green "Virtual Network is updated with DNS Entry"
                    }
                    else
                    {
                        Write-Host -ForegroundColor Red "Unable to set the DNS entry"
                        exit 1
                    }
                }
                catch
                {
                    $_
                }
            }
            if($NumberofVMs -eq 1)
            {
                if(($VMName1) -and (!$VMName2) -and (!$VMName3))
                {
                    $vms = @($VMName1)
                }
                else
                {
                    Write-Host -ForegroundColor Red "You must have to provide only one VMName when the Number of VMs mentioned is 1"
                    exit 105
                }
            }
            elseif($NumberofVMs -eq 2)
            {
                if(($VMName1) -and ($VMName2) -and (!$VMName3))
                {
                    $vms = @($VMName1,$VMName2)
                }
                else
                {
                    Write-Host -ForegroundColor Red "You must have to provide two VMNames when the Number of VMs mentioned is 2"
                    exit 105
                }
            }
            else
            {
                if(($VMName1) -and ($VMName2) -and ($VMName3))
                {
                    $vms = @($VMName1,$VMName2,$VMName3)
                }
                else
                {
                    Write-Host -ForegroundColor Red "You must have to provide only three VMNames when the Number of VMs mentioned is 3"
                    exit 105
                }
            }
            # Fucntion call to validate the Virtual Machine names
            foreach($vmsingle in $vms)
            {
                $VmValid = VMName -Name $vmsingle
                if($VmValid -eq $false)
                {
                    Write-Host -ForegroundColor Red "The VM name must contain between 3 and 15 characters.`n The VM name can contain only letters, numbers, and hyphens.`n The name must start with a letter and must end with a letter or a number"
                    exit 101
                }
            }
            # Validating the Virtual Machine IP Addresses
            if($NumberofVMs -eq 1)
            {
                if(($IPAddress1) -and (!$IPAddress2) -and (!$IPAddress3))
                {
                    $ips = @($IPAddress1)
                }
                else
                {
                    Write-Host -ForegroundColor Red "You must have to provide only one IPAddress when the Number of VMs mentioned is 1"
                    exit 106
                }
            }
            elseif($NumberofVMs -eq 2)
            {
                if(($IPAddress1) -and ($IPAddress2) -and (!$IPAddress3))
                {
                    $ips = @($IPAddress1,$IPAddress2)
                }
                else
                {
                    Write-Host -ForegroundColor Red "You must have to provide two IP Addresses when the Number of VMs mentioned is 2"
                    exit 106
                }
            }
            else
            {
                if(($IPAddress1) -and ($IPAddress2) -and ($IPAddress3))
                {
                    $ips = @($IPAddress1,$IPAddress2,$IPAddress3)
                }
                else
                {
                    Write-Host -ForegroundColor Red "You must have to provide three IP Addresses when the Number of VMs mentioned is 3"
                    exit 106
                }
            }
            # Fucntion call to validate the IP Addresses
            foreach($ip in $ips)
            {
                $IPvalid = ValidateIPAddress -IPAddress $ip
                if($IPvalid -eq $false)
                {
                    Write-Host -ForegroundColor Red "The provided IP address not valid or not in a valid format. It should be in ddd.ddd.ddd.ddd format ex: 192.168.0.5"
                    exit 7
                }
            }
            # Function call to username pattern is valid
            $UnameValid = UserName -User $Username
            if($UnameValid -eq $false)
            {
                Write-Host -ForegroundColor Red "The username not allowed.The names Admin,Administrator can not be used as Username for the VM. You can use these in comibination with other strings"
                exit 102
            }
            
            # function call to check the password is valid
            if($Password)
            {
                $PwdValid = PassWord -Passwrd $Password
                if($PwdValid -eq $false)
                {
                    Write-Host -ForegroundColor Red "The passowrd must be atleat 8 characters and it must contain a lowercase char,a uppercase char,a number and a special char"
                    exit 103
                }
            }
            # Fucntion call to validate the Vnet and Subnet names
            $VnetParams = @($VNetName,$SubnetName)
            foreach($VnetParam in $VnetParams)
            {
                $VnetValid = ValidateVNetParameterNames -Name $VnetParam
                if($VnetValid -eq $false)
                {
                    Write-Host -ForegroundColor Red "The Vnet, Subnet name can contain chars,numbers and hyphen.It should not start with space and number and can be length of 2 to 63 chars"
                    exit 5
                }
            }
            # fucntion call to validate the Storage names
            $StoreNameValid = ValidateStorageName -StorageName $StorageName
            if($StoreNameValid -ne $true)
            {
                Write-Host -ForegroundColor Red "The Storage Name must be in lowercase,start with a letter and can contain numbers,hyphens. It should be length between 3 to 24."
                exit 50
            }
            # fucntion call to validate the Cloud Service name
            $ValidateCSname = ValidateCloudServiceName -ServiceName $Service
            if($ValidateCSname -ieq $false)
            {
                Write-Host -ForegroundColor Red "This field can contain only letters, numbers, and hyphens.`nThe first and last character in the field must be a letter or number.`nTrademarks, reserved words, and offensive words are not allowed"
                exit 70
            }
            #Checking for Affinity Group
            if($affinitygroup)
            {
                $AffinityGroupsDetails = Get-AzureAffinityGroup
                $AffinityGroups = $AffinityGroupsDetails | %{$_.Name}
            
                if(($AffinityGroups.Contains($affinitygroup)) -eq $false)
                {
                    Write-Host -ForegroundColor Red "The Provided Affinity Group does not exist in your Subscription"
                    exit 91
                }
                else
                {
                    $Location = ($AffinityGroupsDetails | Where-Object {$_.Name -ieq $affinitygroup}).Location
                }
            }
            # Validating the Location
            if($Location)
            {
                $code = ValidateLocation -Location $Location # fucntion call to validate the location
                if($code -eq $false)
                {
                    Write-Host -ForegroundColor Red "The Parameter location $Location is not valid. The Location can contain only letters, numbers, and hyphens. The name must start with a letter or number.
                    `nThe name can contain only letters, numbers, and hyphens. The name must start with a letter and must end with a letter or a number.
                    `nThe location should be any one of the azure regions 'East Asia','Southeast Asia','North Europe','West Europe','East US','West US','Japan East','Japan West','Brazil South','North Central US','South Central US','Central US','East US 2'"
                    exit 2
                    #"error" {Write-Host -ForegroundColor Red "Network error";exit 1}
                }
                else
                {
                    $SupportedSizeFrLoc = $code.VirtualMachineRoleSizes
                    if(!($SupportedSizeFrLoc.Contains($Size)))
                    {
                        Write-Host -ForegroundColor Red "The Location does not support the VM size that you have given."
                        exit
                    }
                }
                if($ReservedIP)
                {
                    # Importing Reserved IP module
                    . $PSScriptRoot\ReservedIPModule.ps1
                    $Reserv = ReservedIP -Name $ReservedIP -Location $Location -ServiceName $Service
                }
                else
                {
                    $Reserv = $null
                }

            }    
            #Verifiying The Vnet,Subnet And IPAddress Provided
            # Loading the file
            . $PSScriptRoot\VMVNetEndPoint.ps1
            if($affinitygroup)
            {
                # If affinity group been provided
                foreach($IPAdd in $ips)
                {
                    #. $PSScriptRoot\VMVNetEndPoint.ps1
                    $VnetSubnetIPValid = ValidateVNetSubnetIPForVM -GivenSubNet $SubnetName -GivenIPAddress $IPAdd -GivenVnet $VNetName -AffinityGrp $affinitygroup 
                }
            }
            else
            {
                # if Location been provided
                foreach($IPAdd in $ips)
                { 
                    . $PSScriptRoot\VMVNetEndPoint.ps1
                    $VnetSubnetIPValid = ValidateVNetSubnetIPForVM -GivenSubNet $SubnetName -GivenIPAddress $IPAdd -GivenVnet $VNetName -Location $Location
                }
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
            . $PSScriptRoot\StorageAccountModule.ps1
            if(!$storageExist)
            {
                #Script calling for Storage existence
                if($affinitygroup)
                {
                    # Creating the storage based on affinity
                    $Cstor = CreateStorageAccount -StorageName $storagename -ContainerName vhds -Affinity $affinitygroup -GeoReplicaStore $false
                    if($Cstor -eq $true)
                    {
                       Write-Host -ForegroundColor Green "The Storage account $StorageAccount has been created successfully in this $affinitygroup ." 
                    }
                    else
                    {
                        exit
                    }                      
                }
                else
                {   # creating storage based on Location
                    $Cstor = CreateStorageAccount -StorageName $storagename -ContainerName vhds -Location $Location -GeoReplicaStore $false
                    if($Cstor -eq $true)
                    {
                       Write-Host -ForegroundColor Green "The Storage account $StorageAccount has been created successfully in this $Location ." 
                    }
                    else
                    {
                        exit
                    }
                }
            }
            else
            {   # Fucntion call to check the storage existence in subscription
                $StoreInSub = IsStorage -Storage $Storagename
                if($StoreInSub -ne $null)
                {   # Checking for the Storage existence in the cloud service, if exist then does it associated with location or affinity group
                    if(($StoreInSub.Location -ieq $Location) -or ($StoreInSub.AffinityGroup -ieq $AffinityGroup))
                    {
                        Write-Host -ForegroundColor Green "The Storage $storagename is already exist in this $Location $AffinityGroup for your Subscription"
                        #if((Read-Host "Do you want to use this storage account with:y/n") -imatch "y")
                        #{   # Setting the storage account
                            $success = Set-AzureSubscription -SubscriptionName $Subscription -CurrentStorageAccountName $storagename
                            if((Get-AzureSubscription -Current -ExtendedDetails).CurrentStorageAccountName -ieq $storagename)
                            {
                                Write-Host -ForegroundColor Green "The Storage has been set successfully"
                            }
                            else
                            {
                                Write-Host -ForegroundColor Red "Error occured while setting the storage account"
                                exit 58
                            }
                        #}
                        #else
                        #{
                           #exit
                        #}
                    }
                    else
                    {
                        Write-Host -ForegroundColor Red "The Storage $storagename account is not associated with your affinity group or Location"
                        exit 59
                    }
                }
                else
                {
                    Write-Host -ForegroundColor Red "The Storage account is not exit in your subscription"
                    exit 57
                }
            }
            # Cloud Service Checking
            #Checking for Cloud Service existence
            Write-Host -ForegroundColor Green "Checking for the Cloud Service..."
            $ServiceExist = Test-AzureName -Service $Service
            . $PSScriptRoot\CloudServiceModule.ps1
            if(!$ServiceExist)
            {   
                if($affinitygroup) 
                {  
                     # Calling the fucntion to create cloud service if affinity group been provided
                    $CSer = CreateCloudService -Name $Service -affi $affinitygroup
                    if($CSer -eq $true)
                    {
                        Write-Host -ForegroundColor Green "The Cloud Service has been created successfully in this $affinitygroup for your subscription."
                    }
                    else
                    {
                        exit 73
                    }
                }
                else
                {   # Calling the fucntion to create cloud service if Location been provided
                    #. $PSScriptRoot\CloudService.ps1 -CloudServiceName $Service -Subscription $subscription -Location $Location -Operation "Create"
                    $CSer = CreateCloudService -Name $Service -Loc $Location
                    if($CSer -ieq $true)
                    {
                        Write-Host -ForegroundColor Green "The Cloud Service has been successfully created in this $Location Location"
                    }
                    else
                    {
                        exit 73
                    }
                }
                # loading the script file
                . $PSScriptRoot\VMVNetEndPoint.ps1
                for($i = 0;$i -lt $NumberofVMs;$i++)
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
                                            #$vmStat = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                            #$vms[$i]
                                            #while(!($vmStat.ResourceExtensionStatusList))
                                            #{
                                            #    sleep(30)
                                            #    $vmStat = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                            #}
                                            #while($vmStat.ResourceExtensionStatusList[1].ExtensionSettingStatus.Status -in ("Installing","Transitioning"))
                                            #{
                                            #    sleep(30)
                                            #    $vmStat = Get-AzureVM -Name $vms[$i] -ServiceName $Service
                                            #}
                                            #$rslist = ($vmStat.ResourceExtensionStatusList)[1].ExtensionSettingStatus.SubStatusList | Select Name, @{"Label"="Message";Expression = {$_.FormattedMessage.Message }}
                                            #if(!($rslist[1].Message))
                                            #{                        
                                            #    sleep(300)
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
                                                                dfsutil root addDom \\$x\SHARE1 "ms demo share"
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
                                                else
                                                {
                                                    Write-Host -ForegroundColor Green "The Splunk server has been provisioned successfully"
                                                    #Write-Host -ForegroundColor Green "Checking for the AD and DS configuration...."
                                                    Invoke-command -ConnectionUri $uri -Credential $credential -ScriptBlock{
                                                    try
                                                                {
                                                                    Set-ExecutionPolicy Unrestricted
                                                                    netsh advfirewall set allprofiles state off
                                                                    cd C:\
                                                                    .\splunk.bat 
         
                                                                }
                                                                catch
                                                                {
                                                                    write-host "Error while running command"
                                                                    exit
                                                                }
                                                        }
                                                }
                                            #}
                                            #else
                                            #{
                                            #    Write-Host -ForegroundColor Red "There was an error while configuring executing the commands"
                                            #    exit
                                            #}
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
                                                if(!($rslist[1].Message))
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
                                                                    $Domain = $env:USERDNSDOMAIN
                                                                    Write-Host -ForegroundColor Green "Serever's Domain is: " $Domain
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