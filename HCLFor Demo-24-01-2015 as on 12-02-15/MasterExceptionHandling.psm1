<#
.SYNOPSIS
    The script to check the availability of the Azure module
.DESCRIPTION
    This is to check the availability of the Azure module in local system
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    NO
.EXAMPLE
    Import the module into PowerShell, then use as below
    use CheckModule and returns path or false
#>
function Check-Module
{
    Write-Host "Checking for Required modules..."
    if((Get-Module | Where-Object {($_.Name -eq "Azure")}) -eq $null)
    {
        $path = Get-Module -ListAvailable 'Azure'
        $MPath = $path.Path.Substring(0,$path.Path.LastIndexOf('\'))
        if($path)
        {
            Import-Module $MPath
            return $true    
        }
        else 
        {
            Write-Host "Azure PowerShell has not been installed. Please install the Azure PowerShell, then import"    
            return $false
        }
    }
    else
    {
        Write-Host "Azure Module has already been imported"
        return $false
    }
}
<#
.SYNOPSIS
    The script to check the subscriptions
.DESCRIPTION
    This is to check the availability of the subscription and gives the option to import the 
    publish settings file, if is not imported.
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Subscription    : Name of the sunscription that the user has been given from Azure
    -ImportFilePath  : PublishSettingsFile of the Azure Subscription
.EXAMPLE
    Import the module into PowerShell, then use as below
    Subscription -Subscription <Name> -ImportFilePath <path>
#>
function ConnectTo-Azure
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$Subscription,
        [Parameter(Mandatory=$false)]
        [string]$ImportFilePath
    )
    try
    {
        # Calling the Check-Module fucntion to check for the Azure PowerShell module
        $IsModule = Check-Module
        if($IsModule -ieq $true)
        {
            if($ImportFilePath) # Modified for Security purpose. Please refer below
            {
                if((test-path $ImportFilePath) -ieq $true)
                {
                    Import-AzurePublishSettingsFile $ImportFilePath   
                }
                else 
                {
                    Write-Host "File not found in the provided location"
                    return $false   
                }            
            }
            # Getting the user's azure subscription
            Write-Host "Checking for the subscription...."
            $Subscriptions = Get-AzureSubscription -SubscriptionName $Subscription
            if($Subscriptions)
            {
                $data = Select-AzureSubscription -SunscriptionName $Subscription
                return $true
            }
            else
            {
                Write-Host "Provided azure subscription is not available"
                return $false
            }    
        }
        else
        {
            return $false    
        }
    }
    catch
    {
        $Error[0].Exception.Message
        return $false
    }
}
<#
.SYNOPSIS
    The script to check the Admin rights
.DESCRIPTION
    This is to check the elevation mode of the PowerShell
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    NO
.EXAMPLE
    Import the module into PowerShell, then use as below
    call IsAdmin and returns true/false
#>
Function Is-Admin
{
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()` 
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 

    return $IsAdmin
}
<#
.SYNOPSIS
    The script to get the Azure configuration file
.DESCRIPTION
    This is to get the Azure network configurations file from the given subscription
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    NO
.EXAMPLE
    Import the module into PowerShell, then use as below
    use as GetConfigFile and the file will be downloaded into current working directory
#>
function Get-VnetConfigFile
{
    try
    {
        # GETTING THE VIRTUAL NETWORK CONFIGURATION FILE INTO CURRENT DIRCTORY
        $config = Get-AzureVNetConfig -ExportToFile $PSScriptRoot\VirtualNetWorkConfiguration.xml
        return $true
    }
    catch
    {
        $Error[0].Exception.Message
        return $false
    }
}
<#
.SYNOPSIS
    The script to check the vnet parameters validity
.DESCRIPTION
    This is to check validity of vnet parameters and their max limit
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Virtual_Network_Name       : Name of the Virtual Network in Azure
    -Local_Network_Name         : Name of the Local Network in Azure
    -DNS_Server_Name1           : Name of DNS Server-1
    -DNS_Server_Name2           : Name of DNS Server-2
    -DNS_Server_Ref             : Name of DNS Server Reference to primary DNS Server
    -LocalNetWorkRef            : Reference to LocalNetwork
.EXAMPLE
    Import the module into PowerShell, then use as below
    Is-VNetParamExist -Virtual_Network_Name  <name> -Local_Network_Name <name> -DNS_Server_Name1 <name> -DNS_Server_Name2 <name> -DNS_Server_Ref <name>  -LocalNetWorkRef <name>
#>
function Is-VNetParamExist
{
    Param
    (
        [Parameter(Mandatory=$true)] 
        [string]$Virtual_Network_Name,
        [Parameter(Mandatory=$true)] 
        [string]$Local_Network_Name,
        [Parameter(Mandatory=$true)] 
        [string]$DNS_Server_Name1,
        [Parameter(Mandatory=$true)] 
        [string]$DNS_Server_Name2,
        [Parameter(Mandatory=$true)] 
        [string]$DNS_Server_Ref,
        [Parameter(Mandatory=$true)] 
        [string]$LocalNetWorkRef                    
     )    
    ## SOFT LIMITS FOR THE VIRTUAL NETWORKS, LOCAL NETWORKS AND DNS SERVERS AS PER THE SUBSCRIPTION AT THIS TIME
    [int]$VMAX = 50 
    [int]$LMAX = 10
    [int]$DMAX = 9 
    try
    {
        #Write-Host -ForegroundColor Green "Obtaining the Virtual Network Configuration File"
        # GETTING THE VIRTUAL NETWORK CONFIGURATION FILE INTO CURRENT DIRCTORY
        #$configfile = Get-AzureVNetConfig -ExportToFile $PSScriptRoot\VirtualNetWorkConfiguration.xml                        
        $filecontents = (Get-Content $PSScriptRoot\VirtualNetWorkConfiguration.xml)
        [xml]$xml = $filecontents
        # GETTING AVAILABLE VIRTUAL NETWORKS IN YOUR SUBSCRIPTION
        $Vsites = $xml.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite
        $VNetCount = $Vsites.Count
        #### CHECKING FOR MAXIMUM ALLOWED VNETS FOR THIS SUBSCRIPTION
        if($VNetCount -eq $VMAX)   
        {
            Write-Host -ForegroundColor Red "The Maximum Virtual Networks supported  for your subscription as of now is $VMAX. You can raise a request at Management portal for more Virtual Networks, Max upto 100"
            return $false
        }
        ### CHECKING FOR THE EXISTENCE OF VIRTUAL NETWORK
        $site = $Vsites | Where-Object { $_.name -imatch $Virtual_Network_Name}
        if($site -ne $null)
        {
            Write-Host -ForegroundColor Red "The Virtual Network Name already exist in your Subscription"
            return $false
        }
        # GETTING THE AVAILABLE LOCAL NETWORKS IN YOUR SUBSCRIPTION
        $Lsites = $xml.NetworkConfiguration.VirtualNetworkConfiguration.LocalNetworkSites.LocalNetworkSite
        $LocalCount = $Lsites.Count
        #### CHECKING FOR MAXIMUM ALLOWED LNETS FOR YOUR SUBSCRIPTION
        if($LocalCount -eq $LMAX)   
        {
            Write-Host -ForegroundColor Red "The Maximum Local Networks supported  for your subscription as of now is $LMAX. You can raise a request at Management portal for more Local Networks, Max upto 100"
            return $false
        }
        # CHECKING FOR THE EXISTENCE OF LOCAL NETWORK IN YOUR SUBSCRIPTION
        $Lsite = $Lsites | Where-Object { $_.name -imatch $Local_Network_Name}
        if($Lsite -ne $null)
        {
            Write-Host -ForegroundColor Red "The name of Local Network already exist"
            return $false
        }
        # GETTING THE AVAILABLE DNS SERVERS IN YOUR SUBSCRIPTION
        $DnsServerNodes = $xml.NetworkConfiguration.VirtualNetworkConfiguration.Dns.DnsServers.DnsServer
        $DnsNds = @($DNS_Server_Name1,$DNS_Server_Name2)
        $DnsCount = $DnsServerNodes.Count
        #### CHECKING FOR MAXIMUM ALLOWED DNS FOR THIS SUBSCRIPTION
        if(($DnsCount -eq $DMAX) -or ($DnsCount -gt ($DMAX - 2)))   
        {
            Write-Host -ForegroundColor Red "The Maximum DNS servers supported  for your subscription as of now is $DMAX. You can raise a request at Management portal for more Dns Servers, Max upto 100"
            return $false
        }            
        # CHECKING FOR THE EXISTENCE OF DNS SERVERS IN YOUR SUBSCRIPTION
        foreach($a in $DnsNds)
        {
            if($DnsServerNodes | Where-Object {$_.name -ieq "$a"})
            {
                Write-Host -ForegroundColor Red "The DNS Name $a already exist.Please choose different one"
                return $false
            } 
        }                        
        return $true
    }
    catch
    {
        $Error[0].Exception.Message
        return $false            
    }
}
<#
.SYNOPSIS
    The script to check the exixtence of DNS and Local network reference
.DESCRIPTION
    This is to check whether DNS and LocalNetwork is exist or not
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -DNSName1                   : Name of first DNS Server
    -DNSName2                   : Name of secondary DNS Server
    -LocalNetName               : Local Network Name
    -DNSNameRef                 : DNS reference primary or secondary
    -LocalNetRef                : Local network name
.EXAMPLE
    Import the module into PowerShell, then use as below
    Is-DNSandLocalNetRefExist -DNSName1 <Name> -DNSName2 <Name> -LocalNetName <Name> -DNSNameRef <Name> -LocalNetRef <Name>
#>
function Is-DNSandLocalNetRefExist
{
    Param(
    [Parameter(Mandatory=$true)]
    [string]$DNSName1,
    [Parameter(Mandatory=$true)]
    [string]$DNSName2,
    [Parameter(Mandatory=$true)]
    [string]$LocalNetName,
    [Parameter(Mandatory=$true)]
    [string]$DNSNameRef,
    [Parameter(Mandatory=$true)]
    [string]$LocalNetRef
        )
    # Checking for the DNS Names duplication
    if($DNSName1 -ieq $DNSName2)
    {
        Write-Host -ForegroundColor Red "The DNS Server Names should be distinct"
        return $false
    }
    # Checking for the DNS Server Ref,that should refer any one DNS Servers mentioned
    if($DNSNameRef -notin ($DNSName1,$DNSName2))
    {
        Write-Host -ForegroundColor Red "The DNS Server reference $DNSNameRef should be any one of your DNS servers $DNSName1,$DNSName2 defined"
        return $false
    }
    # Checking whether LocalNetRef is reffering Local Network mentioned
    if($LocalNetRef -ine $LocalNetName)
    {
        Write-Host -ForegroundColor Red "The $LocalNetRef should refer the Local network defined $LocalNetName"
        return $false
    }
    return $true
}
<#
.SYNOPSIS
    The script to validate the Vnet parameters
.DESCRIPTION
    This is to validate the VNet parameters for pattern
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Name                       : Name of either Vnet name or subnet or dns names   
.EXAMPLE
    Import the module into PowerShell, then use as below
    Validate-VNetParameterNames -Name <name>
#>
function Validate-VNetParameterNames
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    # Checking the Pattern and length of the parameters provided
    if($Name -imatch "^[A-Za-z][A-Za-z0-9-]{1,64}$")
    {
        return $true
    }
    else
    {
        return $false
    } 
}
<#
.SYNOPSIS
    The script to validate the AddressSpace
.DESCRIPTION
    This is to validate the pattern of the address spaces of Vnet and Subnets
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Prefix                     : Address Prefix
.EXAMPLE
    Import the module into PowerShell, then use as below
    Validate-AddressSpace -Prefix <AddressSpace>
#>
function Validate-AddressSpace
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$Prefix
    )        
    # Validating the Address Spaces format for Vnets,Subnets and Local Net
    if($Prefix -imatch "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-4])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}\/\d{1,2}$")
    {
        return $true
    }
    else
    {
        return $false
    }
}
<#
.SYNOPSIS
    The script to validate the IP Address for VM
.DESCRIPTION
    This is to validate the IP address pattern of a Virtual Machine
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -IPAddress                  : IP Address    
.EXAMPLE
    Import the module into PowerShell, then use as below
    Validate-IPAddress -IPAddress <IP Address>
#>
function Validate-IPAddress
{
    param
    (
        [Parameter(Mandatory=$true)] 
        [string]$IPAddress
    )                
    # Validating the IP Address format
    if($IPAddress -imatch "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-4])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){2}(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]))$")
    {
        return $true
    }
    else
    {
        Write-Host "$IPAddress is not Valid"
        return $false
    }
}
<#
.SYNOPSIS
    The script to validate the location
.DESCRIPTION
    This is to validate the azure location provided by user
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Location                   : Valid Azure Location   
.EXAMPLE
    Import the module into PowerShell, then use as below
    Validate-Location -Location <Azure region>
#>
function Validate-Location
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Location
    )
    try
    {
        $AzureLocs = Get-AzureLocation
        $Locs = $AzureLocs | %{$_.Name}
        # Validating the Location
        if($Locs.Contains($Location))
        {
            $LocObj = $AzureLocs | Where-Object {$_.Name -eq $Location}
            return $LocObj
        }
        else
        {
            return $false
        }
    }
    catch
    {
        $Error[0].Exception.Message
        return $false
    }
}
<#
.SYNOPSIS
    The script to validate the affinity group
.DESCRIPTION
    This is to validate the affinity group provided by user
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Affinity                   : Name of the affinity group   
.EXAMPLE
    Import the module into PowerShell, then use as below
    Validate-AffinityGroup -Affinity <affinity name>
#>
function Validate-AffinityGroup
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Affinity
         )
    try
    {
        if($affinity -imatch "^[A-Za-z0-9]+[A-Za-z0-9-]{2,63}$")
        {
            return $true
        }
        else
        {
            return $false
        }            
    }
    catch
    {
        $Error[0].Exception.Message
        return $false
    }
}
<#
.SYNOPSIS
    The script to check whether Affinity group exist or not
.DESCRIPTION
    This is to check whether the affinity group exist or not for the given subscription
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Affinity                   : Affinity group name   
.EXAMPLE
    Import the module into PowerShell, then use as below
    Is-AffinityExist -Affinity <affinity name>
#>
function Is-AffinityExist
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Affinity
    )        
    try
    {
        $affs = Get-AzureAffinityGroup | Where-Object {$_.Name -ieq $affinity}
        if($affs)
        {
            return $true
        }
        else 
        {
            Write-Host "Affinity group is not available"
            return $false
        }            
    }
    catch
    {
        $Error[0].Exception.Message
        return $false
    }       
}
<#
.SYNOPSIS
    The script to get the azure Virtual Machine image
.DESCRIPTION
    This is to get the azure virtual machine image for instance creation 
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -ImageName                  : Name of the image for instance creation
    -Location                   : name of Azure region
    -OSType                     : Type of OS either windows or Linux
.EXAMPLE
    Import the module into PowerShell, then use as below
    Get-VirtualMachineImage -ImageName <name> -Location <azure region> -OSType <windows/linux>
#>
function Get-VirtualMachineImage
{
    Param
    (
        [string]$ImageName,
        [string]$Location,
        [string]$OSType
    )
    try
    {
        if($OSType -ieq "Linux")
        {
            $VMImages = Get-AzureVMImage | where-Object { $_.Label -ieq $ImageFamily } | Sort-Object -Descending -Property PublishedDate
        }
        else
        {
            $VMImages = Get-AzureVMImage | where-Object { $_.Label -match $ImageFamily } | Sort-Object -Descending -Property PublishedDate
        }
        if($VMImages -eq $null)
        {
            Write-Host -ForegroundColor Red "Image is not available for selected $ImageFamily Version"
            return
        }
        else
        {
            $LocationList = $VMImages[0].Location
            $LocationList = $LocationList.Split(";")
            if($LocationList.Contains($Location))
            {
                $VMImage = $VMImages[0].ImageName
                return $VMImage
            }
            else
            {
                Write-Host "Virtual Machine image is not available in the provided location"
                return
            }
        }
    }
    catch
    {
        $Error[0].Exception.Message
        return $false
    }        
}
<#
.SYNOPSIS
    The script to validate the virtual machine name
.DESCRIPTION
    This is to validate the name of the virtual machine like length
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Virtual_Network_Name   
.EXAMPLE
    Import the module into PowerShell, then use as below
    Validate-VirtualMachineName -Name <vm name>
#>
function Validate-VirtualMachineName
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    if($Name -match "^[A-Za-z][A-Za-z0-9]{2,16}$")
    {
        return $true
    }
    else
    {
        Write-Host "Virtual machine name should not be more than 15 characters"
        return $false
    }
}
<#
.SYNOPSIS
    The script to validate the user name
.DESCRIPTION
    This is to validate the user name. User should not use the restricted user names for Azure VM
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -User                       : UserName   
.EXAMPLE
    Import the module into PowerShell, then use as below
    Validate-UserName -User 'username'
#>
function Validate-UserName
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$User
    )
    if(($User -imatch "^[A-Za-z0-9_-]{0,}$")-and ($User -inotin ("A","a","admin1","admin2","1","123","Administrator","administrator","Admin1","Admin2","Admin","admin")))
    {
        return $true
    }
    else
    {
        Write-Host "User name should not be Admin, but you can admin in combination with other names"
        return $false
    }
}
<#
.SYNOPSIS
    The script to validate the password for the instance
.DESCRIPTION
    This is to validate the password for the virtual machine like patter and length.
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Passwrd                    : Password   
.EXAMPLE
    Import the module into PowerShell, then use as below
    Validate-Password -Passwrd <password>
#>
function Validate-PassWord
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Passwrd
        )
    if($Passwrd -imatch "^(((?=.*\d)(?=.*[a-z])(?=.*[A-Z])|(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%])).{8,123})$")
    {
        return $true
    }
    else
    {
        Write-Host "The Password msut follow the following"
        Write-Host "should be length of alleast 8 characters"
        Write-Host "Should have Uppercase letters"
        Write-Host "Should have lowercase letters"
        Write-Host "Should have special characters"
        return $false
    }
}
<#
.SYNOPSIS
    The script to validate the Cloud service name
.DESCRIPTION
    This is to validate the cloud service name like length and pattern
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -ServiceName                : cloud service name   
.EXAMPLE
    Import the module into PowerShell, then use as below
    Validate-CloudServiceName -ServiceName <cloud service name>
#>
function Validate-CloudServiceName
{
    param
    (
        [Parameter(Mandatory=$true)] 
        [string]$ServiceName
    )

    if($ServiceName -imatch "^[A-Za-z0-9][A-Za-z0-9-]{0,}$")
    {
        return $true
    }
    else
    {
        return $false
    }
}

<#function IsCloudServiceNameAvailableInSub
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
       return "error"
    }

}#>
<#
.SYNOPSIS
    The script to validate storage name
.DESCRIPTION
    This is to validate the storage name for length and pattern
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -StorageName                : Name of the storage account   
.EXAMPLE
    Import the module into PowerShell, then use as below
    Validate-StorageName -StorageName <storagename>
#>
function Validate-StorageName
{
    Param
    (
        [Parameter(Mandatory=$true)] 
        [string]$StorageName
    )

    if($StorageName -cmatch "^[a-z][a-z0-9]{2,25}$")
    {
        return $true
    }
    else
    {
        Write-Host "The storage name should be in lowercase letters and of length 3-24 characters"
        return $false
    }
}
<#
.SYNOPSIS
    The script to validate the storage account container
.DESCRIPTION
    This is to validate the storage container name and length
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -ContainerName              : Container name   
.EXAMPLE
    Import the module into PowerShell, then use as below
    Validate-ContainerName -ContainerName <containerName>
#>
function Validate-ContainerName
{
    Param
    (
        [Parameter(Mandatory=$true)] 
        [string]$ContainerName
    )

    if($ContainerName -cmatch "^[a-z][a-z0-9]{2,64}$")
    {
        return $true
    }
    else
    {
        Write-Host "The container name should be in lowercase letters and of length 3-24 characters"
        return $false
    }
}
################################################# Fcuntion to check the storage exists ############################################
<#function IsStorageExist
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
        return "error"
    }
}#>

########### Exporting all functions as power shell cmdlet ####################

Export-ModuleMember -Function * -Alias *

####################### End of the Script ##################################