<#
    .VERSION
        Script File Name  :VMVNetEndPoint.ps1
        Version           :1.1
        Date of Updation  :08-07-2014

    .AUTHOR

        Bhaskar Desharaju

    .SYNOPSIS
    
        The script is to provide the fucntions for creating the Virtual Machine and Network config validation and adding end points

    .DESCRIPTION
    
        This scripts have the functions to create the Virtual Machine based on the user input, a function to Validate the Network configuration such as Virtual Network,
        Subnet within the given virtula network and the IPAddress. It also has the function to create the end points to the virtual machine.

        The user has to include this script in the script from where the virtual Machine ctreation will be started. Add these functions to the script from where virtual machine or end points configuration
        starts.

    .EXAMPLE
        
        Include this script full path in the scripts and call the required functions with parameters
         
        . $pathtoscript\VMVNetEndPoint.ps1

        CreateVirtualMachine -OSType Linux or Windows -VMImage <imagename> -VMName <name> -Size <azure provided sizes> -Service <servicename> -Username <username for vm> -Password <Passwrd for vm> -VNetName <name> -SubnetName <subnetname> -IPAddress <IP> -Role <RODC,DFS etc>

        function ValidateVNetSubnetIPForVM -GivenSubNet <subnetname> -GivenIPAddress <IP Address for vm> -GivenVnet <vnetname> -AffinityGrp <affinityname> -Location <azure location>

        CreateEndPoints -ServiceName <service name> -VMName <name of vm> -num <number>
#>

function CreateVirtualMachine
{

        Param(
            [Parameter(Mandatory=$true)]
            [string]$OSType,
            [Parameter(Mandatory=$true)]
            [string]$VMImage,
            [Parameter(Mandatory=$true)]
            [string]$VMName,
            [Parameter(Mandatory=$true)]
            [string]$Size,
            [Parameter(Mandatory=$true)]
            [string]$Service,
            [Parameter(Mandatory=$true)]
            [string]$Username,
            [Parameter(Mandatory=$false)]
            [string]$Password,
            [Parameter(Mandatory=$true)]
            [string]$VNetName,
            [Parameter(Mandatory=$true)]
            [string]$SubnetName,
            [Parameter(Mandatory=$true)]
            [string]$IPAddress,
            [Parameter(Mandatory=$false)]
            [string]$Role
            )
            
            try
            {
                if($OSType -ieq "Windows")
                {
                    # converting the password to secure string
                    $secPassword = ConvertTo-SecureString $Password -AsPlainText -Force
                    $credential = New-Object System.Management.Automation.PSCredential($Username, $secPassword)
            
                    # checking whether the vm name is already exist in the hosted service
                    $Deployments = Get-AzureVM -ServiceName $Service -Name $VMName
                    if($Deployments)
                    {
                        Write-Host -ForegroundColor Red "The Vm with this Name already exist in this Service"
                        return "name"
                    }
                    else
                    {
                        # Getting the current time
                        $Start = Get-Date
                        # Adding time to expire
                        $endTime = $Start.AddMinutes(30)
                        # Getting the primary key for the storage account
                        $StorageKey  = Get-AzureStorageKey -StorageAccountName nukpublicfiles | %{$_.Primary}
                        # Getting the context for the storage
                        $context = New-AzureStorageContext -StorageAccountName nukpublicfiles -StorageAccountKey $StorageKey

                        if($Role)
                        {
                        # Based on the role set the custome script file url along with the SAS token
                            switch -CaseSensitive ($Role)
                            {
                                "RODC" {
                                        #$sName = "RODC"
                                            $Token = New-AzureStorageBlobSASToken -Container customscriptprivate -Blob CustomScriptRodc.ps1 -Permission rw -Context $context -StartTime $Start -ExpiryTime $endTime
                                            $customscriptfile = "https://nukpublicfiles.blob.core.windows.net/customscriptprivate/CustomScriptRodc.ps1"
                                            $Script = $customscriptfile.Split("/")[-1]
                                            $customscriptfile = $customscriptfile + $Token
                                            break
                                        }
                                "DFS" {
                                        #$sName = "DFS"
                                            $Token = New-AzureStorageBlobSASToken -Container customscriptprivate -Blob CustomScritpDFS.ps1 -Permission rw -Context $context -StartTime $Start -ExpiryTime $endTime
                                            $customscriptfile = "https://nukpublicfiles.blob.core.windows.net/customscriptprivate/CustomScritpDFS.ps1"
                                            $Script = $customscriptfile.Split("/")[-1]
                                            $customscriptfile = $customscriptfile + $Token
                                            break
                                        }
                            "ADandDC" {
                                        #$sName = "AD Server"
                                            $Token = New-AzureStorageBlobSASToken -Container customscriptprivate -Blob ADandDSCustomScript.ps1 -Permission rw -Context $context -StartTime $Start -ExpiryTime $endTime
                                            $customscriptfile = "https://nukpublicfiles.blob.core.windows.net/customscriptprivate/ADandDSCustomScript.ps1"
                                            $Script = $customscriptfile.Split("/")[-1]
                                            $customscriptfile = $customscriptfile + $Token
                                            break
                                        }
							"Splunk"   {
                                            $Token = New-AzureStorageBlobSASToken -Container customscriptprivate -Blob SplunkCustomScript.ps1 -Permission rw -Context $context -StartTime $Start -ExpiryTime $endTime
                                            $customscriptfile = "https://nukpublicfiles.blob.core.windows.net/customscriptprivate/SplunkCustomScript.ps1"
                                            $Script = $customscriptfile.Split("/")[-1]
                                            $customscriptfile = $customscriptfile + $Token
                                            break

                                        }
                            "SQLServer" {
                                            $Token = New-AzureStorageBlobSASToken -Container customscriptprivate -Blob SqlInstall.ps1 -Permission rw -Context $context -StartTime $Start -ExpiryTime $endTime
                                            $customscriptfile = "https://nukpublicfiles.blob.core.windows.net/customscriptprivate/SqlInstall.ps1"
                                            $Script = $customscriptfile.Split("/")[-1]
                                            $customscriptfile = $customscriptfile + $Token
                                            break
                                        }
                            }

                            if($Role -eq "SQLServer")
                            {
                                $SecKey = New-AzureStorageContainerSASToken -Name sqlserverfiles -Permission rw -StartTime $Start -ExpiryTime $endTime -Context $context
                                $sasToken = $SecKey.Split("&")
                            }
                            else
                            {
                                $SecKey = New-AzureStorageBlobSASToken -Container certificate -Blob chef-validator.pem -Permission rw -StartTime $Start -ExpiryTime $endTime -Context $context
                                $sasToken = $SecKey.Split("&")
                            }

                            try
                            {
                                $success = New-AzureVMConfig -Name $VMName -InstanceSize $Size -ImageName $VMImage |
                                            Add-AzureProvisioningConfig -Windows -AdminUsername $Username -Password $Password |
                                            Set-AzureSubnet -SubnetNames $SubnetName | 
                                            Set-AzureStaticVNetIP -IPAddress $IPAddress | 
                                            Set-AzureVMCustomScriptExtension -FileUri $customscriptfile -Run $Script -Argument "$($sasToken[0]) $($sasToken[1]) $($sasToken[2]) $($sasToken[3]) $($sasToken[4]) $($sasToken[5])" |
                                            New-AzureVM -ServiceName $Service -VNetName $VNetName -WaitForBoot
                            }
                            catch
                            {
                                throw $_
                            }
                        }
                        else
                        {
                            try
                            {
                                # Provisioning the Virtual Machine 
                                $success = New-AzureVMConfig -Name $VMName -InstanceSize $Size -ImageName $VMImage |
                                                Add-AzureProvisioningConfig -Windows -AdminUsername $Username -Password $Password |
                                                Set-AzureSubnet -SubnetNames $SubnetName | 
                                                Set-AzureStaticVNetIP -IPAddress $IPAddress |
												#Add-AzureEndpoint -Name 'Splunk' -Protocol tcp -LocalPort 8000 -PublicPort 8000 |
                                                New-AzureVM -ServiceName $Service -VNetName $VNetName -WaitForBoot
                            }
                            catch
                            {
                                throw $_
                            }


                        }
                        # Getting the Instance details
                        $vm = Get-AzureVM -ServiceName $Service -Name $VMName
                        # cheking for the execution status
                        if($success.OperationStatus -ieq "Succeeded")
                        {   
                            Write-Host -ForegroundColor Green "The Virtual Machine is being provisioned...."
                            while($vm.InstanceStatus -ne "ReadyRole")
                            {   # waiting to get the VM Ready
                                start-sleep -Seconds 30
                                $vm = Get-AzureVM -ServiceName $Service -Name $VMName
                            }
                            #$list = ($vm.ResourceExtensionStatusList)[1]
                            #$status = $list.ExtensionSettingStatus.SubStatusList | Select Name, @{"Label"="Message";Expression = {$_.FormattedMessage.Message }}
                            #$Vm.ResourceExtensionStatusList.ExtensionSettingStatus.SubStatusList | Select Name, @{"Label"="Message";Expression = {$_.FormattedMessage.Message }}
                            #Write-Host "$status"
                            #Write-Host -ForegroundColor Green "The VM has been provisioned successfully and is running now"
                            return $true
                        }
                        else
                        {
                            #Write-Host -ForegroundColor Red "The was error while provisioning the VM"
                            return $false  
                        }          
                    }               
                }
                elseif($OSType -ieq "Linux")
                {
                    # checking whether the vm name is already exist in the hosted service
                    $Deployments = Get-AzureVM -ServiceName $Service -Name $VMName
                    if($Deployments)
                    {
                        Write-Host -ForegroundColor Red "The Vm with this Name already exist in this Service"
                         return "name"
                    }
                    else
                    {   # Uploading the .pem certificate to the cloud service
                    
                    try
                    {   
                        $data = Add-AzureCertificate -ServiceName $Service -CertToDeploy "$PSScriptRoot\myCerttwo.pem"
                        # Creating the certificate object
                        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                        $cert.Import("$PSScriptRoot\myCerttwo.pem")
                        # Getting the ThumbPrint for the certificate
                        $ThumbPrint = $cert.Thumbprint
                        # Public key
                        $sshkey = New-AzureSSHKey -PublicKey -Fingerprint $ThumbPrint -Path "/home/$Username/.ssh/authorized_keys"
                         # Provisioning the Virtual Machine 
                        $success = New-AzureVMConfig -Name $VMName -InstanceSize $Size -ImageName $VMImage |
                                        Add-AzureProvisioningConfig -Linux -LinuxUser $Username -NoSSHPassword -SSHPublicKeys $sshkey |
                                        Set-AzureSubnet -SubnetNames $SubnetName |
                                        Set-AzureStaticVNetIP -IPAddress $IPAddress | 
                                        Add-AzureEndpoint -Name 'HTTPS' -Protocol tcp -LocalPort 443 -PublicPort 443 |
                                        New-AzureVM -ServiceName $Service -VNetName $VNetName -WaitForBoot
                        
                        # Getting the Instance details
                        $vm = Get-AzureVM -ServiceName $Service -Name $VMName
                        # cheking for the execution status
                        if($success.OperationStatus -ieq "Succeeded")
                        {
                            Write-Host -ForegroundColor Green "The Virtual Machine $VMName is being provisioned...."
                            while($vm.InstanceStatus -ne "ReadyRole")
                            {   # waiting to get the VM Ready
                                start-sleep -Seconds 30
                                $vm = Get-AzureVM -ServiceName $Service -Name $VMName
                            }
                            #Write-Host -ForegroundColor Green "The VM has been provisioned successfully and is running now"
                            
    ############################################## Executing the Custome Script on the remote Linux Virtual Machine ######################################

                            $ports = Get-AzureEndpoint -Name SSH -VM $vm.VM
                            $portnumber = $ports.Port
                            $StorageKey  = Get-AzureStorageKey -StorageAccountName nukpublicfiles | %{$_.Primary}
                            # Getting the context for the storage
                            $context = New-AzureStorageContext -StorageAccountName nukpublicfiles -StorageAccountKey $StorageKey
                            $DNSName = $Service +".cloudapp.net"

                            $fileName = "client1.rb"
                            $NewFile = "updatedfile"
                            $rbData = Get-AzureStorageBlobContent -Blob $fileName -Container certificate -Destination $PSScriptRoot\$fileName -Context $context -Force
                            $filecontent = Get-Content $PSScriptRoot\$fileName
                            $New = @() 

                            foreach($line in $filecontent)
                            {
                                if($line -match ".cloudapp.net")
                                {
                                    $var = "chef_server_url" + " " + '"' + "https://$Service.cloudapp.net" +'"'
                                    #$line = "chef_server_url https://$Service.cloudapp.net"
                                    $line = $var
                                }
                                $New += $line 
                            }
                            $New = Set-Content -Value $New $PSScriptRoot\$NewFile -Encoding Ascii
                            $setData = Set-AzureStorageBlobContent -Blob $fileName -Container certificate -File $PSScriptRoot\$NewFile -Context $context -Force
                            sleep(30)
                            # Getting the Remote session to execute the commands on remote linux vm
                            New-SshSession -ComputerName "$Service.cloudapp.net" -Username $Username -KeyFile "$PSScriptRoot\myPrivateKeytwo.key" -Port $portnumber # -Password $Password
                                if($Role)
                                {
                                    Switch -CaseSensitive ($Role)
                                    {
                                    "ChefMaster" {  # Chef Server Installation                                                 
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo apt-get update"
                                                    #Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo wget https://www.opscode.com/chef/install.sh;sudo chmod 755 install.sh;sudo sh install.sh"
													Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo wget http://nukpublicfiles.blob.core.windows.net/chefclient/chef_11.16.4-1_amd64.deb;sudo dpkg -i chef_11.16.4-1_amd64.deb"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo mkdir cookbooks"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "cd cookbooks/;sudo wget https://nukpublicfiles.blob.core.windows.net/customscriptfiles/chef-master.tar;sudo tar -xvf chef-master.tar"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "echo $DNSName > dnsname"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo chef-client -z -o recipe['chef-master']"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo chef-client -z -o recipe['chef-master::chef-workstation']"
                                                    #Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "cd /etc/chef-server/chef-repo/cookbooks;sudo wget http://nukpublicfiles.blob.core.windows.net/customscriptfiles/windows_ad.tar;sudo tar -xvf windows_ad.tar"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo azure storage blob upload -f /etc/chef-server/chef-validator.pem -b chef-validator.pem -t Block -a nukpublicfiles -k $StorageKey --container certificate -q"
                                                    #Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "echo $DNSName > dnsname"

                                                    #echo "$($vm.ServiceName),$($vm.InstanceName),$($vm.IpAddress)," > C:\master
                                                    #$data = Set-AzureStorageBlobContent -File C:\master -Container "customscriptfiles" -Blob "master" -Context $context -Force
                                                    #Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo chef-client"
                                                    break
                                                }
                                    "ChefSlave" {  # Chef Server Installation
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command 'sudo apt-get update'
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo wget https://www.opscode.com/chef/install.sh;sudo chmod 755 install.sh;sudo sh install.sh"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo mkdir cookbooks"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "cd cookbooks/;sudo wget https://nukpublicfiles.blob.core.windows.net/customscriptfiles/chef-slave.tar;sudo tar -xvf chef-slave.tar"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo chef-client -z -o recipe['chef-slave']"

                                                    #Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo wget http://nukpublicfiles.blob.core.windows.net/customscriptfiles/chef-slave-install-script.sh;sudo chmod 755 chef-slave-install-script.sh;sudo sh ./chef-slave-install-script.sh"
                                                    echo "$($vm.ServiceName),$($vm.InstanceName),$($vm.IpAddress)," > C:\slave.txt
                                                    $data = Set-AzureStorageBlobContent -File C:\slave.txt -Container "customscriptfiles" -Blob "slave.txt" -Context $context -Force
                                                    break
                                                }
                                    "ChefRole" {  # Chef Server Installation
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command 'sudo apt-get update'
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo wget https://www.opscode.com/chef/install.sh;sudo chmod 755 install.sh;sudo sh install.sh"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo mkdir cookbooks"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "cd cookbooks/;sudo wget https://nukpublicfiles.blob.core.windows.net/customscriptfiles/chef-slave-failover.tar;sudo tar -xvf chef-slave-failover.tar"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo chef-client -z -o recipe['chef-slave-failover']"
                                                    Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo mkdir temp;cd temp/;sudo wget https://nukpublicfiles.blob.core.windows.net/customscriptfiles/chef-slave.tar;sudo tar -xvf chef-slave.tar;sudo mkdir /root/cookbooks;sudo mv chef-slave /root/cookbooks/"


                                                    #Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo wget http://nukpublicfiles.blob.core.windows.net/customscriptfiles/chef-slave-install-script.sh;sudo chmod 755 chef-slave-install-script.sh;sudo sh ./chef-slave-install-script.sh"
                                                    #echo "$($vm.ServiceName),$($vm.InstanceName),$($vm.IpAddress)," > C:\slave.txt
                                                    #$data = Set-AzureStorageBlobContent -File C:\slave.txt -Container "customscriptfiles" -Blob "slave.txt" -Context $context -Force
                                                    break
                                                }
                                    "LDAP" {    # for LDAP
                                                Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo mkdir /etc/chef"
                                                Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "cd /etc/chef;sudo wget http://nukpublicfiles.blob.core.windows.net/certificate/admin.pem;sudo wget http://nukpublicfiles.blob.core.windows.net/certificate/chef-validator.pem;sudo wget http://nukpublicfiles.blob.core.windows.net/certificate/client.rb"
                                                Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo wget https://www.opscode.com/chef/install.sh"
                                                Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo sh ./install.sh"
                                                Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo chef-client"
                                                break
                                            }
                                    "Zabbix" {  # for zabbix
                                                Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo mkdir /etc/chef"
                                                Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "cd /etc/chef;sudo wget http://nukpublicfiles.blob.core.windows.net/certificate/admin.pem;sudo wget http://nukpublicfiles.blob.core.windows.net/certificate/chef-validator.pem;sudo wget http://nukpublicfiles.blob.core.windows.net/certificate/client.rb"
                                                Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo wget https://www.opscode.com/chef/install.sh"
                                                Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo sh ./install.sh"
                                                Invoke-SshCommand -ComputerName "$Service.cloudapp.net" -Command "sudo chef-client"
                                                break
                                            }
                    
                                    }
                                }
                            # Remvoing the remote session
                            Remove-SshSession -ComputerName "$Service.cloudapp.net"
                            #$fileName = "client1.rb"
                            #$NewFile = "updatedfile.rb"
                            #$rbData = Get-AzureStorageBlobContent -Blob $fileName -Container certificate -Destination $PSScriptRoot\$fileName -Context $context -Force
                            #$filecontent = Get-Content $PSScriptRoot\$fileName
                            #$New = @() 

                            #foreach($line in $filecontent)
                            #{
                            #    if($line -match ".cloudapp.net")
                            #    {
                            #        $line = "chef_server_url https://$Service.cloudapp.net"
                            #    }
                            #    $New += $line 
                            #}
                            #$New > $PSScriptRoot\$NewFile
                            #$setData = Set-AzureStorageBlobContent -Blob $fileName -Container certificate -File $PSScriptRoot\$NewFile -Context $context -Force#>
    ###################################################### Remvoing End Points of the Virtual Machine ###########################################
                            # deleting the end points which are useful 
                            #. $PSScriptRoot\removeallendpoint.ps1 $subscription $Service $VMName
                            return $true
                        }
                        else
                        {
                            #Write-Host -ForegroundColor Red "The was error while creating the VM"
                            return $false
                        }
                     }
                     catch
                     {
                        throw $_
                    }     
                    }                                                           
                }
                else
                {
                    Write-Host -ForegroundColor Red "The OS Type is not supported as of Now"
                    return "OS"
                }
        }
        catch [System.Net.Http.HttpRequestException]
        {
            return $_
        }
}

 ####################################### Validate VNet Subnet and IP for Virtual Machine ################################################

function ValidateVNetSubnetIPForVM 
{
    Param(
        [Parameter(Mandatory=$true)] 
        [String]$GivenSubNet,
        [Parameter(Mandatory=$true)] 
        [string]$GivenIPAddress,
        [Parameter(Mandatory=$true)] 
        [string]$GivenVnet,
        [Parameter(ParameterSetName="Affinity")] 
        [string]$AffinityGrp,
        [Parameter(ParameterSetName="Location")] 
        [string]$Location
        )


        [string]$IPAddressAll
    
        function Get-IPAddressrange
        {
            param ( 
                [string]$AddressPrefix
                ) 
                
            function IPAddress-toINT64 () 
            { 
                param ($IPAddresss) 
           
                $octets = $IPAddresss.split(".") 
                return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
            } 
 
            function INT64-toIPAddress() 
            { 
                param ([int64]$int) 

                return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
            } 
            
            $SplittingAddress = $AddressPrefix.split("/")
            $IPAddress = $SplittingAddress[0]
            $CIDR = $SplittingAddress[1]
         
            if ($IPAddress) 
            {
                $IPAddress = [Net.IPAddress]::Parse($IPAddress)
            } 
            if ($CIDR) 
            {       
                $maskaddr = [Net.IPAddress]::Parse((INT64-toIPAddress -int ([convert]::ToInt64(("1"*$CIDR+"0"*(32-$CIDR)),2))))           
            } 
            if ($IPAddress) 
            {
                $networkaddr = new-object net.IPAddress($maskaddr.address -band $IPAddress.address)
                $networkaddr
            } 
            if ($IPAddress) 
            {
                $broadcastaddr = new-object net.IPAddress(([system.net.IPAddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))
                $broadcastaddr
            } 
 
            $startaddr = IPAddress-toINT64 -IPAddress  $networkaddr.IPAddressToString
            $endaddr = IPAddress-toINT64 -IPAddress $broadcastaddr.IPAddressToString
        
            #$startaddr
            #$endaddr
     
            for ($i = $startaddr; $i -le $endaddr; $i++) 
            { 
                $IPAddressAll = INT64-toIPAddress -int $i
                $IPAddressAll
            }

            #$IPAddressAll
        return $IPAddressAll
    
        }

        if((GetConfigFile) -ieq $false)
        {
            Write-Host -ForegroundColor Red "Network error"
            return $false
        }
       
    try
    {
        [xml]$FileContent = Get-Content -Path "$PSScriptRoot\VirtualNetWorkConfiguration.xml"
        $Vsites = $FileContent.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite

        $Sites = $Vsites | %{$_.name}
        if($Sites.Contains($GivenVnet))
        {
            
            $site = $Vsites | Where-Object { $_.name -ieq $GivenVnet}
            if($AffinityGrp)
            {
                $AffinityGroupName = $site | %{$_.AffinityGroup}
                if(($AffinityGroupName -ine $AffinityGrp))
                {
                    Write-Host -ForegroundColor Red " The Vnet is not associated with the provided affinity group. Please provide the proper affinity group associated with Vnet"
                    return $false
                }
            }
            else
            {
                $IsLocation = $site | %{$_.Location}
                if(($IsLocation -ine $Location))
                {
                    Write-Host -ForegroundColor Red " The Vnet is not associated with the provided Location. Please provide the proper Loaction associated with Vnet"
                    return $false
                }
            }
            $SubNets = ($site.Subnets.Subnet).name
            $IPAddressPrefix = ($site.Subnets.Subnet | Where-Object { $_.name -eq $GivenSubNet}).AddressPrefix

            if($SubNets.Contains($GivenSubNet))
            {
                $IPAddressexist = (Test-AzureStaticVNetIP -IPAddress $GivenIPAddress -VNetName $GivenVnet).IsAvailable
                if($IPAddressexist)
                {
                    $IPAddressRanges = Get-IPAddressrange -AddressPrefix $IPAddressPrefix
                    $IPAddressRanges = $IPAddressRanges[4..($IPAddressRanges.Length -3)]
                                        
                    if($IPAddressRanges.Contains($GivenIPAddress))
                    {
                        return $true
                    }
                    else
                    {
                        Write-Host -ForegroundColor Red "Provided IPAddress falls beyond the Subnet Range in the Virtual Network or the IP address is not usable in this subnet"
                        return $false
                    }
                }
                else
                {
                    Write-Host -ForegroundColor Red "The Given IPAddress is already used.Please Select Another one."
                    return $false
                }
            }
            else
            {
                Write-Host -ForegroundColor Red "Provided Subnet does not exist in the Given Virtual Network."
                return $false
            }
        }
        else
        {
            write-host -ForegroundColor Red "Provided Virtual Network does not exist."
            return $false
        }
        Remove-Item -Path "$PSScriptRoot\Vnetconfig.xml"
    }
    catch [System.Net.Http.HttpRequestException]
    {
        #Write-Host -ForegroundColor Red "Exception occured while executing the commands. It is due to the connectivity to internet"
        #return "error"
        Throw $_
    }
}

 ##################################################### function to create end points ################################################
<# The code has been disbaled and the same functionality is available with EndPointsOps.ps1
function CreateEndPoints 
{
    Param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,
        [Parameter(Mandatory = $true)]
        [string]$VMName,
        [Parameter(Mandatory = $false)]
        [int]$num
        )

        try
        {   # Getting the vm details
            $VM = Get-AzureVM -ServiceName $ServiceName -Name $VMName
            # Read end points from the CSV file from the current directory
            
            $EndPoints = Import-Csv $PSScriptRoot\end$i.csv -header Name,Protocol,LocalPort -delimiter ',' | foreach { #Removed Public port to get it automatically
		                 New-Object PSObject -prop @{
			                                            Name = $_.Name;
			                                            Protocol = $_.Protocol;
			                                            #PublicPort = [int32]$_.PublicPort;
			                                            LocalPort = [int32]$_.LocalPort;
		                                            }
                                                } #ForEach close
                # Getting the Configured private ports
                $definedPrivatePorts = (Get-AzureEndpoint -VM $VM).LocalPort        #Added to check for the defined private port
                
                Foreach ($endpoint in $EndPoints)
                {
                    if($endpoint.Name -ne $null) # checking for name
                    {
                        # Checking whether name is already exist
                        $EndPointExist = Get-AzureEndpoint -Name $endpoint.Name -VM $vm.VM
                        # If name does not exist then check for the private port already exist
                        if(($EndPointExist -ne $null) -and ($definedPrivatePorts.Contains($endpoint.LocalPort)))
                        {
                             Write-Host -ForegroundColor Red " The End point name already exist or the private port has already been defined"
                             return $false
                        }
                        else
                        {   # Getting the ACL object
                            $AclList = New-AzureAclConfig
                            # reading ACl ruls from the CSV file
                            $rules = Import-Csv $PSScriptRoot\AclRule.csv -header Ordr,Act,Sub,Des -delimiter ',' | ForEach {
		                                    New-Object PSObject -prop @{
			                                                                Ordr = [int32]$_.Ordr;
                                                                            Act = [string]$_.Act;
			                                                                Sub = [string]$_.Sub;
			                                                                Des = [string]$_.Des;
            
		                                                                }
                                                            } # Ends Here
                            # for each rule from the CSV file, attach it to the end point
                            foreach($rule in $rules)
                            {
                                $rule
                                $data = Set-AzureAclConfig -ACL $AclList -Action $rule.Act -AddRule -RemoteSubnet $rule.Sub -Description $rule.Des -Order $rule.Ordr
                            }
                            # add the acl rule to the instance and update it
	                        $dump = $VM.VM | Add-AzureEndpoint -Name $endpoint.Name -Protocol $endpoint.Protocol.ToLower() -LocalPort $endpoint.LocalPort -ACL $AclList # -PublicPort $endpoint.PublicPort
                        }
                    }
                }
            # Updating the VM with end points along with ACL rules
            $dump = $VM | Update-AzureVM
            if($dump.OperationStatus -ieq "Succeeded")
            {
                return $true
            }
            else
            {
                return $false
            }
            
        }
        catch [System.Exception]
        {
            #return "error"
            Throw "error occured while sending the request"
        }
}#>