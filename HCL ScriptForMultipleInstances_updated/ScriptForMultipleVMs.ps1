#################################################################################################################
#.VERSION
#   Script Name                : ScriptForMultipleVMs.ps1
#   VERSION                    : 1.0
#   Date of Authoring          : 5th-Feb-2015
#   Updates                    : 20-Feb-2015
#    
#.AUTHOR
#   Bhaskar Desharaju on behalf of HCL Technologies Ltd
#.SYNOPSIS
#   The Script to launch multiple instances in Microsoft Azure in a single execution of script.    
#.DESCRIPTION
#   The script provides an automated way to launch multiple instances in single execution of script.
#   1. The user has to fill the excel sheet to provide the configuration information for all instances, which is avaolable in current directory.
#   2. Once the execution is done, a statue report file will be generated in the current directory.
#   3. The script creates instances in existing Azure Virtual Network, Azure Storage account for a location.
#################################################################################################################
Param(
	[Parameter(Mandatory=$true)]
	[string]$SubscriptionName,
	[Parameter(Mandatory=$false)]
	[string]$ImportFilePath,
    [Parameter(Mandatory=$false)]
	[string]$ExcelFilepath
	)

# if the ImportFilePath is provided, imports the publishsettings file from the path
if($ImportFilePath)
{
    Import-AzurePublishSettingsFile $ImportFilePath
}
############################# Fucntion to get the Image Information ###############################
function Get-ImageInfo
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$OSType,
        [Parameter(Mandatory=$true)]
        [string]$Location,
        [Parameter(Mandatory=$true)]
        [string]$ImageFamily
    )
    try
    {
        if($serverDetail.OSType -eq "Windows")
        {
            # Getting the list of Images for Windows family 
            $VMImages = Get-AzureVMImage | where-Object { $_.Label -match $ImageFamily } | Sort-Object -Descending -Property PublishedDate
        }
        elseif($serverDetail.OSType -eq "Linux")
        {
            # Getting the list of Images for Linux family
            $VMImages = Get-AzureVMImage | where-Object { $_.Label -ieq $ImageFamily } | Sort-Object -Descending -Property PublishedDate   
        }else{}

        if(!$VMImages)
        {
            Add-Content -Value "$($(Get-Date)): Unable to find the ImageName for the Image family specified" -Path $PSScriptRoot\Azure.log #| Out-File -Append $PSScriptRoot\Azure.log
            return
        }
        else
        {
            # Checking the availability of the latest Image in the Location that the user provided
            $LocationList = $VMImages[0].Location
            $LocationList = $LocationList.Split(";")
            if($LocationList.Contains($Location))
            {
                $VMImage = $VMImages[0].ImageName
                return $VMImage
            }
        }
    }
    catch
    {
        Add-Content -Value "$($(Get-Date)): Error: Unable to find the image for the Image Family provided" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
        return
    }
}
############################# Chech for reserved IP ################################################
function GetReservedIPInfo
{
    Param
    (
        [string]$ResIPName,
        [string]$ResServiceName,
        [string]$ResLocation
    )
    try
    {
        $ResIPInfo = Get-AzureReservedIP -ReservedIPName $ResIPName -ErrorAction Continue
        if($ResIPInfo)
        {
            if($ResIPInfo.Location -eq $ResLocation)
            {
                if($ResIPInfo.InUse -eq $false)
                {
                    # IP address is free to assign
                    return $true
                }
                elseif($ResIPInfo.ServiceName -eq $ResServiceName)
                {
                    # IP Address is already associted with this cloud service
                    return $true
                }
                else
                {
                    Add-Content -Value "$($(Get-Date)): The reserved IP is not free i.e associated with some other cloud service." -Path $PSScriptRoot\Azure.log
                    return $false
                }
            }
            else
            {
                Add-Content -Value "$($(Get-Date)): The reserved IP does not belogns to this $ResLocation location." -Path $PSScriptRoot\Azure.log
                return $false
            }
        }
        else
        {
            Add-Content -Value "$($(Get-Date)): The Reserved IP does not exist or unable to get the reserved IP details." -Path $PSScriptRoot\Azure.log
            return $false
        }
    }
    catch
    {
        Add-Content -Value "$($(Get-Date)): Exception occued" -Path $PSScriptRoot\Azure.log
        return $false
    }
}
############################# Function to get the Location Information ##############################
function Get-LocationSizeInfo
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Location,
        [Parameter(Mandatory=$true)]
        [string]$Size
    )
    try
    {
        # Getting all Azure regions
        $Loc = Get-AzureLocation
        $AzureLoc = $Loc | %{$_.Name}
        # Checking the validity of user provided location
        if($AzureLoc.Contains($Location))
        {
            # Getting the user provided location details
            $LocObj = $Loc | Where-Object {$_.Name -eq $Location}
            if($LocObj)
            {
                # Checking for the available Virtual Machine sizes in user provided location
                $SupportedSizes = $LocObj.VirtualMachineRoleSizes
                if($SupportedSizes.Contains($Size))
                {
                    return $true
                }
                else
                {
                    Add-Content -Value "$($(Get-Date)): Location does not support the $Size" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                    return $false
                }
            }
            else
            {
                Add-Content -Value "$($(Get-Date)): Location does not exit" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                return $false
            }
        }
        else
        {
            Add-Content -Value "$($(Get-Date)): Location does not exist" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
            return $false
        } 
    }
    catch
    {
        Add-Content -Value "$($(Get-Date)): Exception occured" -Path $PSScriptRoot\Azure.log
        return $false
    }
}
##################################### Check for Subnet and IP ################################################
function GetSubnetIPInfo 
{
    Param
    (
        [string]$cidr,
        [string]$ip
    )

    $network, [int]$subnetlen = $cidr.Split('/')
    $a = [uint32[]]$network.split('.')
    [uint32] $unetwork = ($a[0] -shl 24) + ($a[1] -shl 16) + ($a[2] -shl 8) + $a[3]

    $mask = (-bnot [uint32]0) -shl (32 - $subnetlen)

    $a = [uint32[]]$ip.split('.')
    [uint32] $uip = ($a[0] -shl 24) + ($a[1] -shl 16) + ($a[2] -shl 8) + $a[3]

    return ($unetwork -eq ($mask -band $uip))
}
##################################### Function to check the VNET, Subnet and IP ##############################
function Get-VnetSubnetIPAddressInfo
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Vnet,
        [Parameter(Mandatory=$true)]
        [string]$Subnet,
        [Parameter(Mandatory=$true)]
        [string]$IP
    )
    try
    {
        # Getting the user provided Virtual Network details
        $VnetInfo = Get-AzureVNetSite | Where-Object {$_.Name -ieq $Vnet}
        if($VnetInfo -ne $null)
        {
            $SubnetsInfo = $VnetInfo.Subnets
            # Checking the user provided subnet name
            $Subs = $SubnetsInfo | %{$_.Name}
            if($Subs.Contains($Subnet))
            {
                # Checking for the availability of the IP Address
                $SubnetCIDR = ($SubnetsInfo | Where-Object {$_.Name -ieq $Subnet}).AddressPrefix
                $LastNum = $IP.Split(".")[-1]
                if($LastNum -notin (0,1,2,3,255))
                {
                    $IPavail = (Test-AzureStaticVNetIP -VNetName $Vnet -IPAddress $IP).IsAvailable
                    if($IPavail -eq $true)
                    {
                        $IPValid = GetSubnetIPInfo -cidr $SubnetCIDR -ip $IP
                        if($IPValid -eq $true)
                        {
                            return $true
                        }
                        else
                        {
                            Add-Content -Value "$($(Get-Date)): IP Address does not fall in the subnet provided" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                            return $false 
                        }
                    }
                    else
                    {
                        Add-Content -Value "$($(Get-Date)): IP Address is not free to asssign" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                        return $false
                    }
                }
                else
                {
                    Add-Content -Value "$($(Get-Date)): IP Address is not usable. Please select IP from usable addresses" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                    return $false   
                }
            }
            else
            {
                Add-Content -Value "$($(Get-Date)): Subnet does not exist in this $Vnet network" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                return $false
            }

        }
        else
        {
            Add-Content -Value "$($(Get-Date)): Virtual Network $Vnet does not exit" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
            return $false
        }
    }
    catch
    {
        Add-Content -Value "$($(Get-Date)): Exception occured: $($Error[0].Exception.Message)" -Path $PSScriptRoot\Azure.log
        return $false
    }
}
################################# Function to Check the Storage ############################################################
function Get-StorageInfo
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$StoreAc,
        [Parameter(Mandatory=$true)]
        [string]$Sub,
        [Parameter(Mandatory=$true)]
        [string]$Location
    )
    try
    {
        # Getting details of user provided storage
        $StoreInfo = Get-AzureStorageAccount -StorageAccountName $StoreAc -WarningAction Ignore
        if(($StoreInfo -ne $null) -and ($StoreInfo.Location -eq $Location))
        {
            # Setting the storage to the current subscription
            $raw = Set-AzureSubscription -SubscriptionName $Sub -CurrentStorageAccountName $StoreAc
            return $true
        }
        else
        {
            Add-Content -Value "$($(Get-Date)): Storage account does not exist in $Location Location" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
            return $false
        }
    }
    catch
    {
        Add-Content -Value "$($(Get-Date)): Exception occured" -Path $PSScriptRoot\Azure.log
        return $false
    }
}
########################### Function to Get the Disk information ################################################
function Get-DiskInfo
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$DiskNum,
        [Parameter(Mandatory=$true)]
        [string]$VMSize
    )
    try
    {
        $res = " "
        # Validating the Number of Disk against Instance Size
        Switch -Exact ($VMSize)
        {
            {$_ -in ("Basic_A0","extrasmall")} {
                                                    if( $DiskNum -eq 1)
                                                    {
                                                        $res = $true
                                                    }
                                                    else
                                                    {
                                                        Add-Content -Value "$($(Get-Date)): Error:Cannot attach more than 1 disk to this type of Instance" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                                                        $res = $false
                                                    }
                                                    break
                                                }
            {$_ -in ("Basic_A1","Small","STANDARD_D1","STANDARD_DS1")} {
                                                                            if(($DiskNum -eq 1) -or ($DiskNum -eq 2))
                                                                            {
                                                                                $res = $true   
                                                                            }
                                                                            else
                                                                            {
                                                                                Add-Content -Value "$($(Get-Date)): Error:Cannot attach more than 2 disk to this type of Instance" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                                                                                $res = $false
                                                                            }
                                                                            break
                                                                        }
            {$_ -in ("Basic_A2","medium","A5","STANDARD_D2","STANDARD_D11","STANDARD_DS2","STANDARD_DS11","STANDARD_G1")} {
                                                                                                                                if(($DiskNum -ge 1) -or ($DiskNum -le 4))
                                                                                                                                {
                                                                                                                                    $res = $true   
                                                                                                                                }
                                                                                                                                else
                                                                                                                                {
                                                                                                                                    Add-Content -Value "$($(Get-Date)): Cannot attach more than 4 disk to this type of Instance" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                                                                                                                                    $res = $false
                                                                                                                                }
                                                                                                                                break
                                                                                                                            }
            {$_ -in ("Basic_A3","large","A6","STANDARD_D3","STANDARD_D12","STANDARD_DS3","STANDARD_DS12","STANDARD_G2")} {
                                                                                                                                if(($DiskNum -ge 1) -or ($DiskNum -le 8))
                                                                                                                                {
                                                                                                                                    $res = $true   
                                                                                                                                }
                                                                                                                                else
                                                                                                                                {
                                                                                                                                    Add-Content -Value "$($(Get-Date)): Cannot attach more than 8 disk to this type of Instance" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                                                                                                                                    $res = $false
                                                                                                                                }
                                                                                                                                break
                                                                                                                            }
            {$_ -in ("Basic_A4","extralarge","A7","A8","A9","STANDARD_D4","STANDARD_D13","STANDARD_DS4","STANDARD_DS13","STANDARD_G3")} {
                                                                                                                                            if(($DiskNum -ge 1) -or ($DiskNum -le 16))
                                                                                                                                            {
                                                                                                                                                $res = $true   
                                                                                                                                            }
                                                                                                                                            else
                                                                                                                                            {
                                                                                                                                                Add-Content -Value "$($(Get-Date)): Cannot attach more than 16 disk to this type of Instance" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                                                                                                                                                $res = $false
                                                                                                                                            }
                                                                                                                                            break
                                                                                                                                          }
            {$_ -in ("STANDARD_D14","STANDARD_DS14","STANDARD_G4")} {
                                                                            if(($DiskNum -ge 1) -or ($DiskNum -le 32))
                                                                            {
                                                                                $res = $true   
                                                                            }
                                                                            else
                                                                            {
                                                                                Add-Content -Value "$($(Get-Date)): Cannot attach more than 32 disk to this type of Instance" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                                                                                $res = $false
                                                                            }
                                                                            break
                                                                        }
            {$_ -in ("STANDARD_G5")} {
                                            if(($DiskNum -ge 1) -or ($DiskNum -le 64))
                                            {
                                                $res = $true   
                                            }
                                            else
                                            {
                                                Add-Content -Value "$($(Get-Date)): Cannot attach more than 64 disk to this type of Instance" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                                                $res = $false
                                            }
                                            break
                                        }
            default {$res = $false}
        }
        return $res
    }
    catch
    {
        Add-Content -Value "$($(Get-Date)): Exception occured" -Path $PSScriptRoot\Azure.log
        return $false
    }
}
################### function to convert Excel file to CSV file ########################################################
function ConverExcelTo-CSV
{
    Param
    (
        $FilePath
    )

    $excelFile = "$PSScriptRoot\Parameters.xlsx"
    $E = New-Object -ComObject Excel.Application
    $E.Visible = $false
    $E.DisplayAlerts = $false
    $wb = $E.Workbooks.Open($excelFile)
    $wb.SaveAs("$PSScriptRoot\Parameters.csv",6)
    $E.Quit()
    return "$PSScriptRoot\Parameters.csv"
}
## Selecting the User given subscription
$data = Get-AzureSubscription | Where-Object {$_.SubscriptionName -eq $SubscriptionName}
if($data)
{
    $data = Select-AzureSubscription -SubscriptionName $SubscriptionName

    $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition


    # if the user given $CSVFilePath, then checking for the file availability
    if($ExcelFilepath)
    {
        $FileExist = Test-Path -Path $ExcelFilepath
        if($FileExist -ne $true)
        {
            Write-Host -ForegroundColor Red "File does not exist in the specified path"
            exit
        }
        else
        {
            $CSVFile = ConverExcelTo-CSV -FilePath $ExcelFilepath
        }
    }
    else ##  Otherwise looking for the CSV file in the current directory
    {
        Write-Host -ForegroundColor Green "Checking for the CSV file in the current directory"
        $file = (Get-ChildItem -Path "$PSScriptRoot\*.xlsx").Name
        if($file)
        {
            $ExcelFilepath = "$PSScriptRoot\$file"
            $CSVFile = ConverExcelTo-CSV -FilePath $ExcelFilepath
        }
        else
        {
            Write-Host -ForegroundColor Red "File not fount in the current directory"
            exit
        }
    }
    ### Creating Log file for the script
    $LogFile = Test-Path -Path "$PSScriptRoot\Azure.log"
    if($LogFile -ne $true)
    {
        Add-Content -Path "$PSScriptRoot\Azure.log" -Value "$($(Get-Date)) ************Welcome*****************"
    }
    #echo "Server Name`t`tCloud Service`t`t`tStatus" > $PSScriptRoot\StatusReport.txt
    #echo "-----------`t`t-------------`t`t`t------" | Out-File -FilePath $PSScriptRoot\StatusReport.txt
    echo " " > $PSScriptRoot\Temp.csv
    #$NewCSVFileObj = New-Object psobject -Property @{"Server Name" = "";"Cloud Service"="";"Status"=""}
    #Export-Csv -InputObject $NewCSVFileObj -Path "$PSScriptRoot\StatusReport.csv" -Encoding ASCII -NoTypeInformation
    # Reading the CSV file row by row
    $ServersData = Import-Csv -Path $CSVFile -Header ServerType,VirtualMachineName,ImageName,Size,UserName,Password,ServiceName,ReservedIP,VirtualNetworkName,SubnetName,StaticIP,StorageAccount,Location,Disks,DiskSize -Delimiter "," |
                    foreach { New-Object PSObject -Property @{
                                OSType = [string]$_.ServerType;
                                VirtuaMachineName = [string]$_.VirtualMachineName;
                                ImageName = [string]$_.ImageName;
                                Size = [string]$_.Size;
                                UserName = [string]$_.UserName;
                                Password = [String]$_.Password;
                                ServiceName = [string]$_.ServiceName;
                                ReservedIP = [string]$_.ReservedIP;
                                VirtualNetworkName = [string]$_.VirtualNetworkName;
                                SubnetName = [string]$_.SubnetName;
                                StaticIP = [string]$_.StaticIP;
                                StorageAccount = [string]$_.StorageAccount;
                                Location = [string]$_.Location;
                                Disks = $_.Disks;
                                DiskSize = $_.DiskSize;
                    }
            }
    # Skipping the Header row
    $ServersData = $ServersData[1..($ServersData.Count - 1)]
    # Looping through the file for each row. Each single row contains data for single server
    foreach($serverDetail in $ServersData)
    {
        if($serverDetail)
        {
            # Checking for least parameters required
            if(!(($serverDetail.OSType) -and ($serverDetail.VirtuaMachineName) -and ($serverDetail.ImageName) -and ($serverDetail.Size) -and ($serverDetail.UserName) -and ($serverDetail.Password) -and ($serverDetail.ServiceName) -and ($serverDetail.VirtualNetworkName) -and ($serverDetail.SubnetName) -and ($serverDetail.StaticIP) -and ($serverDetail.StorageAccount) -and ($serverDetail.Location)))
            {
                Add-Content -Value "`r`n$($(Get-Date)): Insufficient parameters provided for virtual machine $($serverDetail.VirtuaMachineName) with ImageName: $($serverDetail.ImageName) , Service Name: $($serverDetail.ServiceName) , StaticIP: $($serverDetail.StaticIP)" -Path $PSScriptRoot\Azure.log
                Write-Host -ForegroundColor Red "Insufficient parameters found for one of the servers. Check the Azure.log for details"
                exit
            }

            try
            {
                function ContinueLoop
                {
                    Param
                    (
                        $Details,
                        $servicedetails
                    )
                    Add-Content -Value "$($(Get-Date)): Failed to launch $Details virtual machine in $servicedetails" -Path $PSScriptRoot\Azure.log
                    Write-Host -ForegroundColor Red "$($(Get-Date)): Failed to launch $Details virtual machine in in $servicedetails. See the Azure.log file(in the current directory) for specific error."
                    continue
                }
                Add-Content -Value "`r`n$($(Get-Date)): Creating $($serverDetail.VirtuaMachineName) Server in $($serverDetail.ServiceName) cloud service" -Path $PSScriptRoot\Azure.log  #|  Out-File -Append $PSScriptRoot\Azure.log
                #validating Location and Size
                $LocationInfo = Get-LocationSizeInfo -Location $serverDetail.Location -Size $serverDetail.Size
                if($LocationInfo -ne $true)
                {
                    Add-Content -Value "$($(Get-Date)): Error: Location does not support the provided instance size" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                    #continue
                    ContinueLoop -Details $serverDetail.VirtuaMachineName -servicedetails $serverDetail.ServiceName  
                }
                # Validating the Storage account
                $StorageInfor = Get-StorageInfo -StoreAc $serverDetail.StorageAccount -Sub $SubscriptionName -Location $serverDetail.Location
                if($StorageInfor -eq $false)
                {
                    Add-Content -Value "$($(Get-Date)): Error: Invalid details have been provided for the storage account" -Path $PSScriptRoot\Azure.log
                    #continue
                    ContinueLoop -Details $serverDetail.VirtuaMachineName -servicedetails $serverDetail.ServiceName
                }
                # Getting the ImageName for the Image family provided by the user 
                [string]$ImageName = Get-ImageInfo -OSType $serverDetail.OSType -Location $serverDetail.Location -ImageFamily $serverDetail.ImageName
                if($ImageName)
                {
                    # creating the Virtual Machine configuration Object with name,Image,size
                    $vm = New-AzureVMConfig -Name $serverDetail.VirtuaMachineName -ImageName $ImageName -InstanceSize $serverDetail.Size
                }
                else
                {
                    Add-Content -Value "$($(Get-Date)): Error: Image is not found for the Image Familty provided" -Path $PSScriptRoot\Azure.log #| Out-File -Append $PSScriptRoot\Azure.log
                    #continue
                    ContinueLoop -Details $serverDetail.VirtuaMachineName -servicedetails $serverDetail.ServiceName
                }
                # validating Virtual Network, Subnet and IP Address 
                $VnetSubIPInfo = Get-VnetSubnetIPAddressInfo -Vnet $serverDetail.VirtualNetworkName -Subnet $serverDetail.SubnetName -IP $serverDetail.StaticIP
                if($VnetSubIPInfo -ne $true)
                {
                    Add-Content -Value "$($(Get-Date)): Error: Details provided for VNet, Subnet and IP Address are not valid" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                    #continue
                    ContinueLoop -Details $serverDetail.VirtuaMachineName -servicedetails $serverDetail.ServiceName
                }
                else
                {
                    # adding the Subnet and Static IP config to the Virtual Machine config Object
                    $vm = $vm | Set-AzureSubnet -SubnetNames $serverDetail.SubnetName | Set-AzureStaticVNetIP -IPAddress $serverDetail.StaticIP
                }
                # Validating number of  Disks supported 
                if($serverDetail.Disks)
                {
                    $DiskInfo = Get-DiskInfo -DiskNum $serverDetail.Disks -VMSize $serverDetail.Size
                    if($DiskInfo -eq $true)
                    {
                        if($serverDetail.DiskSize)
                        {
                            # If the user provide disk size more than 1023 GB, then it sets the size to 1023
                           [int32]$ModifiedSize = $serverDetail.DiskSize
                           if($ModifiedSize -ge 1024)
                           {
                                Add-Content -Value "$($(Get-Date)): warning: Cannot attach the Disk of size more than 1023 GB and Trying to attach 1023 GB disk." -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                                $ModifiedSize = 1023
                           }
                           for($disk=1;$disk -eq $serverDetail.Disks;$disk++)
                           {
                                # Adding the Datadisk config to the Virtual Machine Config Object
                                $vm = $vm | Add-AzureDataDisk -CreateNew -DiskSizeInGB $ModifiedSize -LUN $disk -HostCaching None -DiskLabel "Datadisk-$disk" 
                           } 
                        }
                    }
                }
                # Cheking for the reserved Ip availability
                if($serverDetail.ReservedIP)
                {
                    $ResExist = GetReservedIPInfo -ResIPName $serverDetail.ReservedIP -ResServiceName $serverDetail.ServiceName -ResLocation $serverDetail.Location
                    if($ResExist -ne $true)
                    {
                        Add-Content -Value "$($(Get-Date)): Reserved IP is not available" -Path $PSScriptRoot\Azure.log

                        ContinueLoop -Details $serverDetail.VirtuaMachineName -servicedetails $serverDetail.ServiceName
                    }
                }
                # Adding the provisioning configuration for Windows and Linux
                switch  ($serverDetail.OSType)
                {
                    "Windows" {
                                    $vm = Add-AzureProvisioningConfig -Windows -AdminUsername $serverDetail.UserName -Password $serverDetail.Password -VM $vm
                                    break
                                }
                    "Linux"  {
                                    $vm = Add-AzureProvisioningConfig -Linux -LinuxUser $serverDetail.UserName -Password $serverDetail.Password -VM $vm
                                    break
                                }
                }                
                $status = $null
                # Testing the availability of the Cloud servive that the user has provided
                $ServiceExist = Test-AzureName -Service $serverDetail.ServiceName
                if($ServiceExist -eq $true)
                {
                    # If cloud Service exist, then get the information of the service
                    $CloudInfo = Get-AzureService | Where-Object {$_.ServiceName -eq $serverDetail.ServiceName}
                    # Checking the location of the Service
                    if($CloudInfo -and ($CloudInfo.Location -eq $serverDetail.Location))
                    {
                        # Checking for the deployments in the cloud service
                        $Check = Get-AzureVM -ServiceName $serverDetail.ServiceName
                        if($Check)
                        {
                            # If deployments available, get info about VNet
                            if(($CloudInfo | Get-AzureDeployment).VNetName -eq ($serverDetail.VirtualNetworkName))
                            {
                                # If deployements are same in the VNet that the user has provided, then go ahead
                                if($serverDetail.ReservedIP)
                                {
                                    $status = New-AzureVM -ServiceName $serverDetail.ServiceName -ReservedIPName $serverDetail.ReservedIP -VNetName $serverDetail.VirtualNetworkName -VMs $vm -ErrorAction SilentlyContinue -WarningAction Ignore
                                }
                                else
                                {
                                    $status = New-AzureVM -ServiceName $serverDetail.ServiceName -VNetName $serverDetail.VirtualNetworkName -VMs $vm -ErrorAction SilentlyContinue -WarningAction Ignore
                                }
                            }
                            else
                            {
                                Add-Content -Value "$($(Get-Date)): Error: Existing cloud service not associated with the Virtual network that you have provided" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                                #continue
                                ContinueLoop -Details $serverDetail.VirtuaMachineName -servicedetails $serverDetail.ServiceName
                            }
                        }
                        else
                        {
                            # Cloud Service is not associted with any VNet..i.e no deployements found, then go ahead
                            if($serverDetail.ReservedIP)
                            {
                                $status = New-AzureVM -ServiceName $serverDetail.ServiceName -ReservedIPName $serverDetail.ReservedIP -VNetName $serverDetail.VirtualNetworkName -VMs $vm -ErrorAction SilentlyContinue -WarningAction Ignore
                            }
                            else
                            {
                                $status = New-AzureVM -ServiceName $serverDetail.ServiceName -VNetName $serverDetail.VirtualNetworkName -VMs $vm -ErrorAction SilentlyContinue -WarningAction Ignore
                            }
                        }
                    }
                    else
                    {
                        Add-Content -Value "$($(Get-Date)): Error:Cloud service is not associted with the Location $($serverDetail.Location)" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                        #continue
                        ContinueLoop -Details $serverDetail.VirtuaMachineName -servicedetails $serverDetail.ServiceName
                    }
                }
                else
                {
                    # Creating Virtual Machine in a new cloud service
                    if($serverDetail.ReservedIP)
                    {
                        $status = New-AzureVm -ServiceName $serverDetail.ServiceName -ReservedIPName $serverDetail.ReservedIP -VNetName $serverDetail.VirtualNetworkName -Location $serverDetail.Location -VMs $vm -ErrorAction SilentlyContinue -WarningAction Ignore
                    }
                    else
                    {
                        $status = New-AzureVm -ServiceName $serverDetail.ServiceName -VNetName $serverDetail.VirtualNetworkName -Location $serverDetail.Location -VMs $vm -ErrorAction SilentlyContinue -WarningAction Ignore
                    }
                    #$status = "Succeeded"
                }
                # Checking for the Command execution for the Instance creation
                #if($status.OperationStatus -eq "Succeeded")
                if($status.OperationStatus -eq "Succeeded")
                {
                    Add-Content -Value "$($(Get-Date)): Instance $($serverDetail.VirtuaMachineName) is being provisioned in $($serverDetail.ServiceName) cloud Service...check the poratl for the status." -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                    Write-Host -ForegroundColor Green "Instance $($serverDetail.VirtuaMachineName) is being provisioned in $($serverDetail.ServiceName) cloud Service."
                    
                    #$ServerObj = New-Object psobject -Property @{Server = $serverDetail.VirtuaMachineName;Cloud=$serverDetail.ServiceName;Status="In progress"}
                    #$ServerObj | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Out-File -FilePath "$PSScriptRoot\StatusReport.csv" -Encoding ascii -Append
                    #echo "$($serverDetail.VirtuaMachineName),$($serverDetail.ServiceName),'In progress'"
                    $Sta = "In progress"
                    echo "$($serverDetail.VirtuaMachineName),$($serverDetail.ServiceName),$Sta" | Out-File -FilePath $PSScriptRoot\Temp.csv -Append
                    #$Detail = Get-AzureVM -ServiceName $serverDetail.ServiceName -Name $serverDetail.VirtuaMachineName
                    # Checking for the Status of the Virtual Machine
                    #while($Detail.InstanceStatus -ne "ReadyRole")
                    #{
                    Sleep(60)
                        #$Detail = Get-AzureVM -ServiceName $serverDetail.ServiceName -Name $serverDetail.VirtuaMachineName
                    #}                  
                }
                else
                {
                    Add-Content -Value "$($(Get-Date)): Error while provisioning the $($serverDetail.VirtuaMachineName) - $($serverDetail.ServiceName) : $($Error[0].Exception.Message)" -Path $PSScriptRoot\Azure.log # | Out-File -Append $PSScriptRoot\Azure.log
                    #continue
                    ContinueLoop -Details $serverDetail.VirtuaMachineName -servicedetails $serverDetail.ServiceName
                }         
            }
            catch
            {
                
                Add-Content -Value $($Error[0].Exception.Message) -Path $PSScriptRoot\Azure.log #| Out-File -Append $PSScriptRoot\Azure.log
                #continue
                ContinueLoop -Details $serverDetail.VirtuaMachineName -servicedetails $serverDetail.ServiceName
            }        
        }
        else
        {
            Add-Content -Value "Server details not found" -Path $PSScriptRoot\Azure.log
            continue
        }
    }
    Import-Csv $PSScriptRoot\Temp.csv -Header ServerName,ServiceName,Status | Export-Csv -Path $PSScriptRoot\StatusReport.csv -NoTypeInformation

    $data = Import-Csv -Path $PSScriptRoot\StatusReport.csv -Header ServerName,ServiceName,Status -Delimiter "," | foreach {
                    New-Object psobject -Property @{
                                                        ServerName = $_.ServerName;
                                                        ServiceName = $_.ServiceName;
                                                        Status = $_.Status;
                                                        }
                                                    }
    $data = $data | select -Skip 1
    if($data)
    {
        #for($i = 0;$i -lt 5;$i++)
        #{
            foreach($element in $data)
            {
                if($element.ServerName)
                {
                    $vm = Get-AzureVM -Name $element.ServerName -ServiceName $element.ServiceName -ErrorAction Continue
                    <#if($vm.InstanceStatus -eq "ReadyRole")
                    {
                        if($element.Status -eq "In progress")
                        {
                            $element.Status = "Running"
                        }
                        else
                        {
                            Continue
                        }
                    }#>
                    #else
                    #{
                    #    continue
                    #}
                    while($vm.InstanceStatus -ne "ReadyRole")
                    {
                        sleep(20)
                        $vm = Get-AzureVM -Name $element.ServerName -ServiceName $element.ServiceName -ErrorAction Continue
                    }
                    if($element.Status -eq "In progress")
                    {
                        $element.Status = "Running"
                    }
                    else
                    {
                        Continue
                    }
                }
                else
                {
                    Continue
                }

            }
            #sleep(30)
        #}
        $data | Export-Csv -Path $PSScriptRoot\ServersStatusReport.csv -NoTypeInformation
        Remove-Item $PSScriptRoot\Temp.csv -Force
        Remove-Item $PSScriptRoot\StatusReport.csv -Force
    }
}
else
{
    Write-Host "Unable to find the subscription that has been provided"
    exit
}