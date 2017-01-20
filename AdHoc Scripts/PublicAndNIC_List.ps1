

$AllPublicIps = Get-AzureRmPublicIpAddress

$PublicIpList = New-Object System.Collections.ArrayList

foreach ( $publicip in $AllPublicIps)
{
    $c = new-object -TypeName PSObject
    $c | Add-Member -MemberType NoteProperty -Name PublicIPName -Value $publicip.Name
    $c | Add-Member -MemberType NoteProperty -Name "Allocation Method" -Value $publicip.PublicIpAllocationMethod
    $c | Add-Member -MemberType NoteProperty -Name "IP Address" -Value $publicip.IpAddress
    $c | Add-Member -MemberType NoteProperty -Name "Location" -Value $publicip.Location
    if($publicip.IpConfiguration -eq $null)
    {
        $c | Add-Member -MemberType NoteProperty -Name "In Use" -Value "No"
        $c | Add-Member -MemberType NoteProperty -Name "NIC Card Name" -Value ""
    }
    else
    {
        $c | Add-Member -MemberType NoteProperty -Name "In Use" -Value "Yes"
        $c | Add-Member -MemberType NoteProperty -Name "NIC Card Name" -Value $($publicip[0].IpConfiguration.Id.Trim()).Split("/")[8]
    }
    $PublicIpList += $c
}
$PublicIpList


$AllNetworkInterfaces = Get-AzureRmNetworkInterface

$NetworkInterfaceList = New-Object System.Collections.ArrayList

foreach ( $NICCard in $AllNetworkInterfaces)
{
    $d = new-object -TypeName PSObject
    $d | Add-Member -MemberType NoteProperty -Name "NIC Card Name" -Value $NICCard.Name
    $d | Add-Member -MemberType NoteProperty -Name "Resource Group" -Value $NICCard.ResourceGroupName

    if($NICCard.VirtualMachine -eq $null)
    {
        $d | Add-Member -MemberType NoteProperty -Name "Attached To" -Value "None" 
    }
    else
    {
        $d | Add-Member -MemberType NoteProperty -Name "Attached To" -Value $NICCard.VirtualMachine.Id.Split("/")[-1]
    }
    $NetworkInterfaceList += $d
}
$NetworkInterfaceList