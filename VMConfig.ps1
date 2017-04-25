$JSON = @{}
$sizes = Get-AzureRmVMSize -Location 'westus'
$array = New-Object System.Collections.ArrayList

$PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition

foreach($a in $sizes)
{
    $Prop = @{}
    $Prop['Name'] = $a.Name
    $Prop['NumberOfCores']= $a.NumberOfCores
    $Prop['MemoryInMB']= $a.MemoryInMB
    $Prop['MaxDataDiskCount']= $a.MaxDataDiskCount
    $Prop['OSDiskSizeInMB']=$a.OSDiskSizeInMB
    $Prop['ResourceDiskSizeInMB']=$a.ResourceDiskSizeInMB
    $array += $Prop
}
$JSON.vmconfig = $array
$JSON | ConvertTo-Json | Out-File -FilePath '$PSScriptRoot\VmConfigs.json' -Force