Param
(
    [string]$UserName,
    [string]$Password,
    [string]$SubscriptionID
)

Try
{
    $secString = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $CredObj = New-Object System.Management.Automation.PSCredential ($UserName,$secString)

    $CompleteObj = New-Object System.Collections.ArrayList
    
    Login-AzureRmAccount -Credential $CredObj -SubscriptionId $SubscriptionID | Out-Null

    # ARM Resources
    $rmVMCount = (Get-AzureRmVM).Count
    $rmStorageCount = (Get-AzureRMStorageAccount -ErrorAction Ignore).Count
    $rmVnet = (Get-AzureRmVirtualNetwork).Count
    $rmTrafficManagers = (Get-AzureRmTrafficManagerProfile).Count
    $Apps = Get-AzureRmADApplication
    $rmApps = $Apps.Count 

    Add-AzureAccount -Credential $CredObj | Out-Null
    # ASM Resources
    $asmVmCount = (Get-AzureVM).Count
    $asmStorageCount = (Get-AzureStorageAccount).Count
    $Vnet = [xml](Get-AzureVNetConfig).XMLConfiguration
    $asmVNet = $Vnet.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite.Count

    $regoinStr = @"
"@
    $CloudServices = Get-AzureService
    $listOutOfVnet = New-Object System.Collections.ArrayList
    foreach ($cs in $CloudServices)
    {
        $Deployments = Get-AzureDeployment -ServiceName $cs.ServiceName -ErrorAction SilentlyContinue
        if($Deployments -and $($Deployments.VNetName -eq $null))
        {
            $listOutOfVnet += $Deployments
            if($Deployments.Count -gt 1)
            {
                foreach ($d in $Deployments)
                {
                    $regoinStr += "$($d.Name):$($cs.Location); `n"
                }
            }
            else
            {
                $regoinStr += "$($Deployments.Name):$($cs.Location); `n"
            }
        }
    }
    $asmOutOfVNet = $listOutOfVnet.Count

    # User login credentials
    $SubObj = New-Object psobject
    $SubObj | Add-Member -MemberType NoteProperty -Name Attribute -Value 'Specify the Microsoft ID/Live ID that you are using to login to your subscription'
    $SubObj | Add-Member -MemberType NoteProperty -Name Value -Value $UserName
    $CompleteObj += $SubObj

    # Total number of Virtual Machines
    $SubObj1 = New-Object psobject
    $SubObj1 | Add-Member -MemberType NoteProperty -Name Attribute -Value "Count of total number of Virtual machines that are in EA/Open subscription"
    $SubObj1 | Add-Member -MemberType NoteProperty -Name Value -Value $($rmVMCount + $asmVmCount)
    $CompleteObj += $SubObj1

    # Total Number of ASM Virtual Machines
    $SubObj2 = New-Object psobject
    $SubObj2 | Add-Member -MemberType NoteProperty -Name Attribute -Value "Count of Azure VMs that are provisioned through ASM (Azure Service Management)"
    $SubObj2 | Add-Member -MemberType NoteProperty -Name Value -Value $asmVmCount
    $CompleteObj += $SubObj2

    # Total Number of Storage Accounts
    $SubObj3 = New-Object psobject
    $SubObj3 | Add-Member -MemberType NoteProperty -Name Attribute -Value "Number of Storage accounts provisioned?"
    $SubObj3 | Add-Member -MemberType NoteProperty -Name Value -Value $($rmStorageCount + $asmStorageCount)
    $CompleteObj += $SubObj3

    # ASM and ARM Storage accounts
    $SubObj4 = New-Object psobject
    $SubObj4 | Add-Member -MemberType NoteProperty -Name Attribute -Value "Is Storage provisioned ASM  or ARM?"
    $SubObj4 | Add-Member -MemberType NoteProperty -Name Value -Value "ASM:$asmStorageCount; ARM:$rmStorageCount"
    $CompleteObj += $SubObj4

    # Total Number of Virtual Network
    $SubObj5 = New-Object psobject
    $SubObj5 | Add-Member -MemberType NoteProperty -Name Attribute -Value "Number of Vnet deployed in the network?"
    $SubObj5 | Add-Member -MemberType NoteProperty -Name Value -Value $($rmVnet + $asmVNet)
    $CompleteObj += $SubObj5

    # Non-VNet deployments of ASM
    $SubObj6 = New-Object psobject
    $SubObj6 | Add-Member -MemberType NoteProperty -Name Attribute -Value "Number of Azure VM outside Vnet?"
    $SubObj6 | Add-Member -MemberType NoteProperty -Name Value -Value $asmOutOfVNet
    $CompleteObj += $SubObj6

    # Non-VNet deployments location
    $SubObj9 = New-Object psobject
    $SubObj9 | Add-Member -MemberType NoteProperty -Name Attribute -Value "Which region does these resources provisioned?"
    $SubObj9 | Add-Member -MemberType NoteProperty -Name Value -Value $regoinStr
    $CompleteObj += $SubObj9

    # Total Number of Traffic Managers
    $SubObj7 = New-Object psobject
    $SubObj7 | Add-Member -MemberType NoteProperty -Name Attribute -Value "Currently do you have traffic managers deployed?"
    $SubObj7 | Add-Member -MemberType NoteProperty -Name Value -Value $rmTrafficManagers
    $CompleteObj += $SubObj7

    # Total Number of AD Applications
    $SubObj8 = New-Object psobject
    $SubObj8 | Add-Member -MemberType NoteProperty -Name Attribute -Value "Does any of the applications currently Azure Active directory auth?"
    $SubObj8 | Add-Member -MemberType NoteProperty -Name Value -Value $rmApps
    $CompleteObj += $SubObj8

    $CompleteObj | Export-Csv -NoTypeInformation -Path .\SubscriptionDetails.csv -Force
}
catch
{
    $Error[0].Exception.Message
}
