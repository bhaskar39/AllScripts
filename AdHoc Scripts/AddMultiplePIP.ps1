$vm = Get-AzureRMVM -Name diva-v3-dev-api -ResourceGroupName diva-v3-dev

$nic = Get-AzureRmNetworkInterface -Name diva-v3-dev-api961 -ResourceGroupName diva-v3-dev

 Register-AzureRmProviderFeature -FeatureName AllowMultipleIpConfigurationsPerNic -ProviderNamespace Microsoft.Network

 Register-AzureRmProviderFeature -FeatureName AllowLoadBalancingonSecondaryIpconfigs -ProviderNamespace Microsoft.Network

 Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Network

 $myVnet = Get-AzureRMVirtualnetwork -Name diva-v3-dev -ResourceGroupName diva-v3-dev
 $Subnet = $myVnet.Subnets | Where-Object { $_.Name -eq "default" }

 $p1 = Get-AzureRmPublicIpAddress -Name diva-v3-dev-api-ip1 -ResourceGroupName diva-v3-dev
 $p2 = Get-AzureRmPublicIpAddress -Name diva-v3-dev-api-ip2 -ResourceGroupName diva-v3-dev

 Add-AzureRmNetworkInterfaceIpConfig -Name ip2 -NetworkInterface $nic -Subnet $Subnet -PublicIpAddress $p1
 Add-AzureRmNetworkInterfaceIpConfig -Name ip3 -NetworkInterface $nic -Subnet $Subnet -PublicIpAddress $p2

 Set-AzureRmNetworkInterface -NetworkInterface $nic
