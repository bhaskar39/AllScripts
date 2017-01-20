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

    Login-AzureRmAccount -Credential $CredObj -SubscriptionId $SubscriptionID -ErrorAction Stop | Out-Null

    $AllResources = Get-AzureRmResource
    $FilteredResource = $AllResources | Select Name,ResourceName,ResourceType,ResourceGroupName,Location
    $FilteredResource | Export-Csv -NoTypeInformation -Path .\AllResourceDetails.csv -Force
}
catch
{
}