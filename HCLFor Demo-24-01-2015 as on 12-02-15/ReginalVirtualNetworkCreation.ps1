<#

    .VERSION
        Script File Name  :ReginalVirtualNetworkCreation.ps1
        Version           :1.1
        Date of Updation  :02-07-2014

    .AUTHOR
        
        Bhaskar Desharaju

    .SYNOPSIS
    
        Creating the Regional Virtual Network in Site-to-Site scenario

    .DESCRIPTION
    
        This script would create a Regional Virtual Network with 
        two DNS Server,Virtual Network,four Subnets,Local Network along with address spaces in Site-to-Site scenario.
        
        This script will create the Virtual network in two scenarios
        Scenario:1
            If the subscription has the exsting virtaul networks, then it gets the network config file and adds
            the user defined new network configuration to the network config file and uploads to azure.
            If the configuration is valid then on the azure portal you will be seeing new virtual network.
        Scenario:2
            If the Subscription does not have the any exsting virtual networks or it is fresh account from azure.
            In this case there won't be any network configuration file. In this case user will be provided a default 
            network confgi file and the script will modify this default config file with user defined network configuration.
            If the configuration is valid then on the azure portal you will be seeing new virtual network.


    .EXAMPLE
            
            Open the file from the current directory, where this script is located and Open in elevated mode.
     Case:1
            If the .PublishSettings not Imported, then Get it from azure using 'Get-AzurePublishSettingsFile

     .\ReginalVirtualNetworkCreation.ps1 -Subscription <SubscriptionName> -ImportFilePath <Pathtopublishsettingsfile> -DNS_Server_Name1 <DNSName> `
         -DNS_Server_IP_1 <IPAddress> -DNS_Server_Name2 <DNSName2> -DNS_Server_IP_2 <IPAddress> -Local_Network_Name <LocalNetName> -LocalNetwork_Address <AddressPrefix> `
         -VPNGateWayAddress <GatewayAddress> -Virtual_Network_Name <VnetName> -VirtualNetwork_AddressPrefix <AddressPrefix> -SubnetName_1 <subnet1name> `
         -SubnetAddPrefix_1 <AddressPrefix> -SubnetName_2 <SubName> -SubnetAddPrefix_2 <AddressPrefix> -SubnetName_3 <SubnetName> -SubnetAddPrefix_3 <AddressPrefix> `
          -SubnetName_4 GatewaySubnet -SubnetAddPrefix_4 <AddressPrefix> -DNS_Server_Ref <DNSName1 or 2> -LocalNetWorkRef <LocalNet> -Location <regionName>

     Case:2
            If you have already Imported the .PublishSettingsFile, then ignore the -ImportFilePath parameter

     .\ReginalVirtualNetworkCreation.ps1 -Subscription <SubscriptionName> -DNS_Server_Name1 <DNSName> -DNS_Server_IP_1 <IPAddress> -DNS_Server_Name2 <DNSName2> `
         -DNS_Server_IP_2 <IPAddress> -Local_Network_Name <LocalNetName> -LocalNetwork_Address <AddressPrefix> -VPNGateWayAddress <GatewayAddress> 
         -Virtual_Network_Name <VnetName> -VirtualNetwork_AddressPrefix <AddressPrefix> -SubnetName_1 <subnet1name> -SubnetAddPrefix_1 <AddressPrefix> `
         -SubnetName_2 <SubName> -SubnetAddPrefix_2 <AddressPrefix> -SubnetName_3 <SubnetName> -SubnetAddPrefix_3 <AddressPrefix> -SubnetName_4 GatewaySubnet `
         -SubnetAddPrefix_4 <AddressPrefix> -DNS_Server_Ref <DNSName1 or 2> -LocalNetWorkRef <LocalNet> -Location <regionName>
#> 
      Param(
            # Subscription Name with which the user registered with Microsoft Azure
            [Parameter(Mandatory=$true,Position=1)]
            [ValidateNotNullOrEmpty()]
            [string]$Subscription,
            # Import file is path to the .publishSettingsFile. If you don't have, it can be downloaded from azure
            [Parameter(Mandatory=$false,Position=2)]
            [ValidateNotNullOrEmpty()]
            [string]$ImportFilePath,
            # Name for your own First DNS Server
            [Parameter(Mandatory=$true,Position=3)]
            [ValidateNotNullOrEmpty()]
            [string]$DNS_Server_Name1,
            # IP Address for your First DNS Server
            [Parameter(Mandatory=$true,Position=4)]
            [ValidateNotNullOrEmpty()]
            [string]$DNS_Server_IP_1,
            # Name for your Second DNS Server
            [Parameter(Mandatory=$true,Position=5)]
            [ValidateNotNullOrEmpty()]
            [string]$DNS_Server_Name2,
            # IP Address for your Second DNS Server
            [Parameter(Mandatory=$true,Position=6)]
            [ValidateNotNullOrEmpty()]
            [string]$DNS_Server_IP_2,
            # Name for Local on-premises network name
            [Parameter(Mandatory=$true,Position=7)]
            [ValidateNotNullOrEmpty()]
            [string]$Local_Network_Name,
            # Address Space of your local Network. Provide it CIDR Notation
            [Parameter(Mandatory=$true,Position=8)]
            [ValidateNotNullOrEmpty()]
            [string]$LocalNetwork_Address,
            # IP Address of your VPN Gateway
            [Parameter(Mandatory=$true,Position=9)]
            [ValidateNotNullOrEmpty()]
            [string]$VPNGateWayAddress,
            # Name for your Virtual Network
            [Parameter(Mandatory=$true,Position=10)]
            [ValidateNotNullOrEmpty()]
            [string]$Virtual_Network_Name,
            # Address Space for your Virtual Network
            [Parameter(Mandatory=$true,Position=11)]
            [ValidateNotNullOrEmpty()]
            [string]$VirtualNetwork_AddressPrefix,
            # First Subnet name in your Virtual Network
            [Parameter(Mandatory=$true,Position=12)]
            [ValidateNotNullOrEmpty()]
            [string]$SubnetName_1,
            # Address Space for your First Subnet
            [Parameter(Mandatory=$true,Position=13)]
            [ValidateNotNullOrEmpty()]
            [string]$SubnetAddPrefix_1,
            # Second Subnet name in your Virtual Network
            [Parameter(Mandatory=$true,Position=14)]
            [ValidateNotNullOrEmpty()]
            [string]$SubnetName_2,
            # Address Space for your Second Subnet
            [Parameter(Mandatory=$true,Position=15)]
            [ValidateNotNullOrEmpty()]
            [string]$SubnetAddPrefix_2,
            # Third Subnet name in your Virtual Network
            [Parameter(Mandatory=$true,Position=16)]
            [ValidateNotNullOrEmpty()]
            [string]$SubnetName_3,
            # Address Space for your Third Subnet
            [Parameter(Mandatory=$true,Position=17)]
            [ValidateNotNullOrEmpty()]
            [string]$SubnetAddPrefix_3,
            # Fourth Subnet name in your Virtual Network
            [Parameter(Mandatory=$true,Position=18)]
            [ValidateNotNullOrEmpty()]
            [string]$SubnetName_4,
            # Address Space for your Fourth Subnet
            [Parameter(Mandatory=$true,Position=19)]
            [ValidateNotNullOrEmpty()]
            [string]$SubnetAddPrefix_4,
            # Referencing one of your DNS Servers
            [Parameter(Mandatory=$true,Position=20)]
            [ValidateNotNullOrEmpty()]
            [string]$DNS_Server_Ref,
            # Referencing Local Network
            [Parameter(Mandatory=$true,Position=21)]
            [ValidateNotNullOrEmpty()]
            [string]$LocalNetWorkRef,
            # Location, to which your Virtual Network has to be bind
            [Parameter(Mandatory=$true,Position=22)]
            [ValidateNotNullOrEmpty()]
            [string]$Location
            )

    $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    # Calling the MasterExcetionHandling script to Validate the Input parameters
    . $PSScriptRoot\MasterExceptionHandling.ps1

    if((IsAdmin) -eq $false)
	{
		Write-Error "Must run PowerShell in elevated mode."
		exit 3
	}
    # Getting the Module Path
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
    # Getting the Subscription Information
    Write-Host -ForegroundColor Green "Checking for the Subscription....."
    $SubExist = Subscription $Subscription $ImportFilePath
    if($SubExist -match $true)
    {
        # Selecting Subscription from Multiple subs
        $raw = Select-AzureSubscription -SubscriptionName $Subscription
        # Fucntion call to check the DNS Server ref and Local Net ref
        $Duplicate = DNSandLocalNetRef -DNSName1 $DNS_Server_Name1 -DNSName2 $DNS_Server_Name2 -LocalNetName $Local_Network_Name -DNSNameRef $DNS_Server_Ref -LocalNetRef $LocalNetWorkRef
        if($Duplicate -ieq $false)
        {
            exit 9
        }
        $ParamNames = @($DNS_Server_Name1,$DNS_Server_Name2,$Local_Network_Name,$Virtual_Network_Name,$SubnetName_1,$SubnetName_2,$SubnetName_3,$SubnetName_4,$DNS_Server_Ref,$LocalNetWorkRef)
        foreach($Param in $ParamNames)
        {
            # Function call to Validate the Virtual Network input names
            $Paramcode = ValidateVNetParameterNames -Name $Param
            if($Paramcode -ieq $false)
            {
                Write-Host -ForegroundColor Red "The Parameter $Name is not valid. It must be between 2 and 63 characters.`nThe name can contain only letters, numbers, and hyphens. The name must start with a letter and must end with a letter or a number"
                exit 5  
            }
        }
        $AddressSpaces = @($LocalNetwork_Address,$VirtualNetwork_AddressPrefix,$SubnetAddPrefix_1,$SubnetAddPrefix_2,$SubnetAddPrefix_3,$SubnetAddPrefix_4)
        foreach($addresSpace in $AddressSpaces)
        {
            # Function call to Validate the Address Spaces in Virtual Network
            $addrescode = ValidateAddressSpace -Prefix $addresSpace
            if($addrescode -ieq $false)
            {
                Write-Host -ForegroundColor Red "The Parameter for Address Prefix $Prefix is not Valid. The Address Prefix should be in ddd.ddd.ddd.ddd/dd format ex:192.168.238.136/16"
                exit 6  
            }
        }
        $IPAddresses = @($DNS_Server_IP_1,$DNS_Server_IP_2,$VPNGateWayAddress)
        foreach($IPAddress in $IPAddresses)
        {
            # Function call to Validate the IP Address provided by the user
            $IPCode = ValidateIPAddress -IPAddress $IPAddress
            if($IPCode -ieq $false)
            {
                Write-Host -ForegroundColor Red "The Parameter IPAddress $IPAddress is not Valid. The IP Address should be in ddd.ddd.ddd.ddd format ex:192.168.238.136"
                exit 7
            }
        }
        # Function call to validate the Location provided by the user
        $LocCode = ValidateLocation -Location $Location
            switch -CaseSensitive ($LocCode)
            {
                $false {Write-Host -ForegroundColor Red "The Parameter location $Location is not valid. The Location can contain only letters, numbers, and hyphens. The name must start with a letter or number.
                `nThe name can contain only letters, numbers, and hyphens. The name must start with a letter and must end with a letter or a number.
                `nThe location should be any one of the azure regions 'East Asia','Southeast Asia','North Europe','West Europe','East US','West US','Japan East','Japan West','Brazil South','North Central US','South Central US'";exit 2}
                "error" {Write-Host -ForegroundColor Red "Network error";exit 1}
            }        
        try
        {
            #$configfile = Get-AzureVNetConfig -ExportToFile $PSScriptRoot\VirtualNetWorkConfiguration.xml
            Write-Host -ForegroundColor Green "Obtaining the Virtual Network Configuration file"            
            if((GetConfigFile) -ieq $false)
            {
                Write-Host -ForegroundColor Red "Network error or error in network configuration file"
                exit 1
            }
            #$fileExist = Test-Path -Path $PSScriptRoot\VirtualNetWorkConfiguration.xml
            $Vnetworks = Get-AzureVNetSite
            #if(($fileExist -eq $true) -and ($Vnetworks))
            if($Vnetworks)
            {
                $fileExist = Test-Path -Path $PSScriptRoot\VirtualNetWorkConfiguration.xml
                if(!($fileExist -eq $true))
                {
                    Write-Host -ForegroundColor Red "Network Config file was not downloaded"
                    exit
                }
                #$data = Get-Content $PSScriptRoot\VirtualNetWorkConfiguration.xml | Set-Content $PSScriptRoot\UploadOrinal.xml
                $filecontents = (Get-Content $PSScriptRoot\VirtualNetWorkConfiguration.xml)

                if($filecontents)
                {
                    [xml]$xml = $filecontents
                    $ExistCode = VNetParamExist -Virtual_Network_Name $Virtual_Network_Name -Local_Network_Name $Local_Network_Name -DNS_Server_Name1 $DNS_Server_Name1 -DNS_Server_Name2 $DNS_Server_Name2 -DNS_Server_Ref $DNS_Server_Ref -LocalNetWorkRef $LocalNetWorkRef
                    if($ExistCode -ieq $false)
                    {
                        exit 8
                    }
                    #---------------------------Checking for the Subnets Validation-------------------------------------------------------------
                    #.\SubnetValidation.ps1 -AddPre $VirtualNetwork_AddressPrefix -sub1 $SubnetAddPrefix_1 -sub2 $SubnetAddPrefix_2 -sub3 $SubnetAddPrefix_3 -sub4 $SubnetAddPrefix_4
                    # ADDING DNS SERVERS TO CONFIGURATION FILE
                    if($xml.GetElementsByTagName("DnsServer").Count -eq 0)
                    {
                        $filecontents = (echo $filecontents | ForEach-Object { $_ -replace "<Dns />", "<Dns><DnsServers><DnsServer name= `"$DNS_Server_Name1`" IPAddress=`"$DNS_Server_IP_1`" /> `r`n`t</DnsServers></Dns>" } )
                    }
                    else
                    {
                        $filecontents = (echo $filecontents | ForEach-Object { $_ -replace "</DnsServers>", "<DnsServer name= `"$DNS_Server_Name1`" IPAddress=`"$DNS_Server_IP_1`" /> `r`n`t</DnsServers>" } )
                    }
                    $filecontents = (echo $filecontents | ForEach-Object { $_ -replace "</DnsServers>", "<DnsServer name= `"$DNS_Server_Name2`" IPAddress=`"$DNS_Server_IP_2`" /> `r`n`t</DnsServers>" } )
                    # ADDING LOCAL NETWORK TO THE CONFIGURATION FILE
                    if($xml.GetElementsByTagName("LocalNetworkSite").Count -eq 0)
                    {
                        $filecontents = (echo $filecontents | ForEach-Object { $_ -replace "</Dns>", "</Dns><LocalNetworkSites><LocalNetworkSite name=`"$Local_Network_Name`">`r`n`t<AddressSpace> 
                                  `r`n`t`t<AddressPrefix>$LocalNetwork_Address</AddressPrefix> 
                                `r`n`t`t</AddressSpace> 
                                `r`n`t`t<VPNGatewayAddress>$VPNGateWayAddress</VPNGatewayAddress> 
                              `r`n`t`t</LocalNetworkSite> 
                            `r`n`t`t</LocalNetworkSites>" } )
                    }
                    else
                    {
                        $filecontents = (echo $filecontents | ForEach-Object { $_ -replace "</LocalNetworkSites>", "<LocalNetworkSite name=`"$Local_Network_Name`">`r`n`t<AddressSpace> 
                                  `r`n`t`t<AddressPrefix>$LocalNetwork_Address</AddressPrefix> 
                                `r`n`t`t</AddressSpace> 
                                `r`n`t`t<VPNGatewayAddress>$VPNGateWayAddress</VPNGatewayAddress> 
                              `r`n`t`t</LocalNetworkSite> 
                            `r`n`t`t</LocalNetworkSites>" } )
                    }
                    # ADDING VIRTUAL NETWORK WITH SUBNETS TO THE CONFIGURATION FILE 
                    $filecontents = (echo $filecontents | ForEach-Object { $_ -replace "</VirtualNetworkSites>", "<VirtualNetworkSite name=`"$Virtual_Network_Name`" Location=`"$Location`"> 
                            `r`n`t<AddressSpace> 
                              `r`n`t<AddressPrefix>$VirtualNetwork_AddressPrefix</AddressPrefix> 
                            `r`n`t</AddressSpace> 
                            `r`n`t<Subnets> 
                              `r`n`t<Subnet name=`"$SubnetName_1`"> 
                                `r`n`t<AddressPrefix>$SubnetAddPrefix_1</AddressPrefix> 
                              `r`n`t</Subnet> 
                              `r`n`t<Subnet name=`"$SubnetName_2`"> 
                                `r`n`t<AddressPrefix>$SubnetAddPrefix_2</AddressPrefix> 
                              `r`n`t</Subnet> 
                              `r`n`t<Subnet name=`"$SubnetName_3`"> 
                                `r`n`t<AddressPrefix>$SubnetAddPrefix_3</AddressPrefix> 
                              `r`n`t</Subnet> 
                              `r`n`t<Subnet name=`"$SubnetName_4`"> 
                                `r`n`t<AddressPrefix>$SubnetAddPrefix_4</AddressPrefix> 
                              `r`n`t</Subnet> 
                            `r`n`t</Subnets> 
                            `r`n`t<DnsServersRef> 
                            `r`n`t<DnsServerRef name=`"$DNS_Server_Ref`"/>
                            `r`n`t</DnsServersRef> 
                            `r`n`t<Gateway> 
                              `r`n`t<ConnectionsToLocalNetwork> 
                               `r`n`t <LocalNetworkSiteRef name=`"$LocalNetWorkRef`">
			                      `r`n`t<Connection type=`"IPsec`" />
			                    `r`n`t</LocalNetworkSiteRef>
                              `r`n`t</ConnectionsToLocalNetwork>  	  
                            `r`n`t</Gateway> 
                          `r`n`t</VirtualNetworkSite> 
                        `r`n`t</VirtualNetworkSites>" } )
                    # SETTING NEW CONTENT TO THE CONFIGUARTION FILE
                    (echo $filecontents | Set-Content $PSScriptRoot\VirtualNetworknew.xml)
                    Write-Host -ForegroundColor Green "The Vitual Network is being created...."
                    # UPLOADING THE NETWORK CONFIGURATION FILE TO AZURE
                    $success = Set-AzureVNetConfig -ConfigurationPath $PSScriptRoot\VirtualNetworknew.xml
                    if($success.OperationStatus -ieq "Succeeded")
                    {
                        #Write-Host -ForegroundColor Green "The Vitual Network has been created successfully"
                    }
                    else
                    {
                        Write-Error "Error occured while creating the Virtual Network"
                        exit 1
                    }

                    $data = Get-AzureVNetConfig -ExportToFile $PSScriptRoot\vnetwithoutDNs.xml
                    $data = Get-Content $PSScriptRoot\vnetwithoutDNs.xml | Set-Content $PSScriptRoot\OriginalVnet.xml
                    [xml]$read = Get-Content $PSScriptRoot\vnetwithoutDNs.xml
                    $obj = $read.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite | Where-Object {$_.name -eq $Virtual_Network_Name}
                    $obj.DnsServersRef.DnsServerRef.ParentNode.RemoveAll()
                    $read.Save("$PSScriptRoot\vnetwithoutDNs.xml")

                    $res = Set-AzureVNetConfig -ConfigurationPath $PSScriptRoot\vnetwithoutDNs.xml
                    if($res.OperationStatus -eq "Succeeded")
                    {
                        Write-Host -ForegroundColor Green "The Vitual Network has been created successfully"
                        Remove-Item -Path $PSScriptRoot\vnetwithoutDNs.xml -Force
                        Remove-Item -Path $PSScriptRoot\VirtualNetworknew.xml -Force
                        Remove-Item -Path $PSScriptRoot\VirtualNetWorkConfiguration.xml -Force
                    }
                    else
                    {
                        Write-Error "Error occured while creating the Virtual Network"
                        exit 1
                    }
                }
                else
                {
                    Write-Host -ForegroundColor Red "The Network configuration file is empty"
                    exit 1
                }   
            }
            else
            {               
                # This case is for Fresh azure subscriptiono or for the subscription that does not any existing virtual networks
                # Getting the content from default configuration file from the current directory
                $temp = Get-Content "$PSScriptRoot\SampleTemplateRegionalVnet.xml" | Set-Content "$PSScriptRoot\SampleTemplateRegionalVnetnew.xml"
                [xml]$xml = Get-Content "$PSScriptRoot\SampleTemplateRegionalVnetnew.xml"
                # Preparing DNS servers   
                $DnsName = @($DNS_Server_Name1,$DNS_Server_Name2)
                $DnsIP = $DNS_Server_IP_1,$DNS_Server_IP_2
                $subnetnames = @($SubnetName_1,$SubnetName_2,$SubnetName_3,$SubnetName_4)
                $subnetips = $SubnetAddPrefix_1,$SubnetAddPrefix_2,$SubnetAddPrefix_3,$SubnetAddPrefix_4                
                $DnsServerNodes = $xml.NetworkConfiguration.VirtualNetworkConfiguration.Dns.DnsServers.DnsServer
                $count = $DnsServerNodes.Count               
                # Adding the DNS Servers to the configuration file
                For( $a =0;$a -lt $count;$a++)
                { 
                   $temp = $DnsServerNodes[$a] | Where-Object {($_.name = $DnsName[$a]) -and ($_.IPAddress = [string]$DnsIP[$a])}
                }
                $xml.Save("$PSScriptRoot\SampleTemplateRegionalVnetnew.xml")
                # Adding the Net work configuration
                $xml.NetworkConfiguration.VirtualNetworkConfiguration.LocalNetworkSites.LocalNetworkSite.name = $Local_Network_Name
                $xml.NetworkConfiguration.VirtualNetworkConfiguration.LocalNetworkSites.LocalNetworkSite.VPNGatewayAddress = $VPNGateWayAddress
                $xml.NetworkConfiguration.VirtualNetworkConfiguration.LocalNetworkSites.LocalNetworkSite.AddressSpace.AddressPrefix = $LocalNetwork_Address
                $xml.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite.name = $Virtual_Network_Name
                $xml.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite.Location = $Location
                $xml.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite.AddressSpace.AddressPrefix = $VirtualNetwork_AddressPrefix
                $subnets = $xml.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite.Subnets               
                # Adding the Subnets
                for($b = 0;$b -lt 4;$b++)
                {
                    $temp = $subnets.Subnet[$b] | Where-Object {($_.name = $subnetnames["$b"]) -and ( $_.AddressPrefix = $subnetips["$b"])} 
                }
                # Adding the DNS Server References
                $xml.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite.DnsServersRef.DnsServerRef.name = $DNS_Server_Ref
                $xml.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite.Gateway.ConnectionsToLocalNetwork.LocalNetworkSiteRef.name = $LocalNetWorkRef
                $xml.Save("$PSScriptRoot\SampleTemplateRegionalVnetnew.xml")
                Write-Host -ForegroundColor Green "The Vitual Network is being created...."
                $success = Set-AzureVNetConfig -ConfigurationPath "$PSScriptRoot\SampleTemplateRegionalVnetnew.xml"
                if($success.OperationStatus -ieq "Succeeded")
                {
                    Write-Host -ForegroundColor Green "The Vitual Network has been created successfully"
                }
                else
                {
                    Write-Host -ForegroundColor Red "Error occured while creating the Network"
                    exit 1
                }
				$data = Get-AzureVNetConfig -ExportToFile $PSScriptRoot\vnetwithoutDNs.xml
				$data = Get-Content $PSScriptRoot\vnetwithoutDNs.xml | Set-Content $PSScriptRoot\OriginalVnet.xml
				[xml]$read = Get-Content $PSScriptRoot\vnetwithoutDNs.xml
				$obj = $read.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite | Where-Object {$_.name -eq $Virtual_Network_Name}
				$obj.DnsServersRef.DnsServerRef.ParentNode.RemoveAll()
				$read.Save("$PSScriptRoot\vnetwithoutDNs.xml")

				$res = Set-AzureVNetConfig -ConfigurationPath $PSScriptRoot\vnetwithoutDNs.xml
				if($res.OperationStatus -eq "Succeeded")
				{
					Write-Host -ForegroundColor Green "The Vitual Network has been created successfully"
				}
				else
				{
					Write-Error "Error occured while creating the Virtual Network"
					exit 1
				}
            }
        }
        catch [System.Net.Http.HttpRequestException]
        {
            Throw $_
        }    
    }
    else
    {
        Write-Host -ForegroundColor Red "The Subscription Name $Subscription does not exist or error in getting the Subscriptions"
        exit 10
    }