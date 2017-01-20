
# Fetching the Network details
$VNet = Get-AzureRmVirtualNetwork -Name Automation-VNet -ResourceGroupName resourcegrp-bhaskar

#Fetching the Subnet Details
$SNet = Get-AzureRmVirtualNetworkSubnetConfig -Name InfraSubnet -VirtualNetwork $VNet



# Create Public IP
$PublicIPStatus = New-AzureRmPublicIpAddress -Name AlievVaultPIP -ResourceGroupName resourcegrp-bhaskar -Location 'West Europe' -AllocationMethod Dynamic

#$availability = New-AzureRmAvailabilitySet -ResourceGroupName resourcegrp-bhaskar -Name MyAvailablity -Location 'East US' -PlatformUpdateDomainCount 10 -PlatformFaultDomainCount 3

# Create Network Interface Card
$NICStatus = New-AzureRmNetworkInterface -Name Alien -ResourceGroupName resourcegrp-bhaskar -Location 'West Europe' -SubnetId $SNet.Id -PublicIpAddressId $PublicIPStatus.Id

$VMConfig = New-AzureRmVMConfig -VMName Alien -VMSize "Standard_A2" # -AvailabilitySetId $availability.Id


$VMConfig = Set-AzureRmVMOSDisk -VM $VMConfig -Name Alien -VhdUri https://storageforautomation.blob.core.windows.net/customvhds/OSSIM.vhd -Caching ReadWrite -CreateOption Attach -Windows

Add-AzureRmVMNetworkInterface -VM $VMConfig -Id $NICStatus.Id -Primary

$Status = New-AzureRmVM -ResourceGroupName resourcegrp-bhaskar -Location 'West Europe' -VM $VMConfig

     