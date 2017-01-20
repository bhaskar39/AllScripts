#################################################################################################################
#.VERSION
#   Script Name                : UpdateAzureVMSize.ps1
#   VERSION                    : 1.0
#   Date of Authoring & Update : 19-Feb-2015 & 20-Feb-2015 1st Update
#    
#.AUTHOR
#   Bhaskar Desharaju on behalf of HCL Technologies Ltd
#.SYNOPSIS
#   The Script to Decrease the D-Series Instances to the lower level i.e A-Series as of now    
#.DESCRIPTION
#   The script provides an automated way to change the instance size to upper level or lower level as 
#   mapped in the script (hard coded).
#   1. As of now the script(v1.x) suports decreasing the Standard D-Series instance size to Standared A-Series size
#   2. User need to provide the path for the CSV file which has the service and server names. The user can keep the
#      the CSV file in the current directory of the script file, no need to provide the path for $FilePath param  
#   3. The user can change the Instance size mapping in the $SizeObj property and add the case to switch accordingly.
#################################################################################################################
Param
(
    [string]$SubscriptionName,
    [string]$FilePath
)

# Hash Variable which holds D to A mapping
$SizeObj = New-Object psobject -Property @{
                                                Standard_D1 = "Medium";
                                                Standard_D2 = "Large";
                                                Standard_D3 = "A5";
                                                Standard_D4 = "A6";
                                                Standard_D11 = "A5";
                                                Standard_D12 = "A6";
                                                Standard_D13 = "A7";
                                                Standard_D14 = "A9";
                                            }
# Checking for the Azure subscription
$data = Get-AzureSubscription | Where-Object {$_.SubscriptionName -eq $SubscriptionName}
if($data)
{
    # Selecting the provided subscription
    $data = Select-AzureSubscription -SubscriptionName $SubscriptionName
    $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
    # if the user given $CSVFilePath, then checking for the file availability
    if($FilePath)
    {
        $FileExist = Test-Path -Path $FilePath
        if($FileExist -ne $true)
        {
            Write-Host -ForegroundColor Red "File does not exist in the specified path"
            exit
        }
    }
    else ##  Otherwise looking for the CSV file in the current directory
    {
        Write-Host -ForegroundColor Green "Checking for the CSV file in the current directory"
        $file = (Get-ChildItem -Path "$PSScriptRoot\*.csv").Name
        if($file)
        {
            $Filepath = "$PSScriptRoot\$file"
        }
        else
        {
            Write-Host -ForegroundColor Red "File not fount in the current directory"
            exit
        }
    }
    ### Creating Log file for the script
    $LogFile = Test-Path -Path "$PSScriptRoot\SizeUpdate.log"
    if($LogFile -ne $true)
    {
        Add-Content -Path "$PSScriptRoot\SizeUpdate.log" -Value "$($(Get-Date)) ************Welcome*****************"
    }
    echo " " > $PSScriptRoot\SizeStatusReport.txt
    # Getting the servers details from the status report
    $ServersData = Import-Csv -Path $FilePath -Header ServiceName,ServerName,Status -Delimiter "," |
                    foreach { New-Object PSObject -Property @{
                                ServiceName = [string]$_.ServiceName;
                                ServerName = [string]$_.ServerName;
                                Status = [string]$_.Status;
                            }
                        }
    $ServersData = $ServersData | Select -Skip 1
    if($ServersData)
    {
        foreach($detail in $ServersData)
        {
            if($detail)
            {
                # Getting the Instance details
                $VMdetails = Get-AzureVM -ServiceName $detail.ServiceName -Name $detail.ServerName -ErrorAction Continue
                if(($VMdetails.InstanceStatus -in ("ReadyRole","Stopped","StoppedDeallocated")))
                {
                    # Getting the current size of the instance
                    $currentSize = ($VMdetails).InstanceSize
                    # Changing the instance size to intended size based on the current size of instance
                    switch ($currentSize)
                    {
                        "Standard_D1" {
                                            $OpStatus = $VMdetails | Set-AzureVMSize -InstanceSize $SizeObj.Standard_D1 | Update-AzureVM
                                            if($OpStatus.OperationStatus -ne "Succeeded")
                                            {
                                                Add-Content -Value "Increasing or Decreasing the instance size was not successfull" -Path $PSScriptRoot\SizeUpdate.Log
                                            }
                                            else
                                            {
                                                Write-Host -ForegroundColor "Updating $($detail.ServerName) instance size to $($SizeObj.Standard_D1)"
                                                Add-Content -Value "$($detail.ServerName) Instance is resized from $currentSize to $($SizeObj.Standard_D1)" -Path $PSScriptRoot\SizeStatusReport.txt
                                            }
                                            break
                                      }
                        "Standard_D2" {
                                            $OpStatus = $VMdetails | Set-AzureVMSize -InstanceSize $SizeObj.Standard_D2 | Update-AzureVM
                                            if($OpStatus.OperationStatus -ne "Succeeded")
                                            {
                                                Add-Content -Value "Increasing or Decreasing the instance size was not successfull" -Path $PSScriptRoot\SizeUpdate.Log
                                            }
                                            else
                                            {
                                                Write-Host -ForegroundColor "Updating $($detail.ServerName) instance size to $($SizeObj.Standard_D2)"
                                                Add-Content -Value "$($detail.ServerName) Instance is resized from $currentSize to $($SizeObj.Standard_D2)" -Path $PSScriptRoot\SizeStatusReport.txt
                                            }
                                            break
                                      }
                        "Standard_D3" {
                                            $OpStatus = $VMdetails | Set-AzureVMSize -InstanceSize $SizeObj.Standard_D3 | Update-AzureVM
                                            if($OpStatus.OperationStatus -ne "Succeeded")
                                            {
                                                Add-Content -Value "Increasing or Decreasing the instance size was not successfull" -Path $PSScriptRoot\SizeUpdate.Log
                                            }
                                            else
                                            {
                                                Write-Host -ForegroundColor "Updating $($detail.ServerName) instance size to $($SizeObj.Standard_D3)"
                                                Add-Content -Value "$($detail.ServerName) Instance is resized from $currentSize to $($SizeObj.Standard_D3)" -Path $PSScriptRoot\SizeStatusReport.txt
                                            }
                                            break
                                      }
                        "Standard_D4" {
                                            $OpStatus = $VMdetails | Set-AzureVMSize -InstanceSize $SizeObj.Standard_D4 | Update-AzureVM
                                            if($OpStatus.OperationStatus -ne "Succeeded")
                                            {
                                                Add-Content -Value "Increasing or Decreasing the instance size was not successfull" -Path $PSScriptRoot\SizeUpdate.Log
                                            }
                                            else
                                            {
                                                Write-Host -ForegroundColor "Updating $($detail.ServerName) instance size to $($SizeObj.Standard_D4)"
                                                Add-Content -Value "$($detail.ServerName) Instance is resized from $currentSize to $($SizeObj.Standard_D4)" -Path $PSScriptRoot\SizeStatusReport.txt
                                            }
                                            break
                                      }
                        "Standard_D11" {
                                            $OpStatus = $VMdetails | Set-AzureVMSize -InstanceSize $SizeObj.Standard_D11 | Update-AzureVM
                                            if($OpStatus.OperationStatus -ne "Succeeded")
                                            {
                                                Add-Content -Value "Increasing or Decreasing the instance size was not successfull" -Path $PSScriptRoot\SizeUpdate.Log
                                            }
                                            else
                                            {
                                                Write-Host -ForegroundColor "Updating $($detail.ServerName) instance size to $($SizeObj.Standard_D11)"
                                                Add-Content -Value "$($detail.ServerName) Instance is resized from $currentSize to $($SizeObj.Standard_D11)" -Path $PSScriptRoot\SizeStatusReport.txt
                                            }
                                            break
                                        }
                        "Standard_D12" {
                                            $OpStatus = $VMdetails | Set-AzureVMSize -InstanceSize $SizeObj.Standard_D12 | Update-AzureVM
                                            if($OpStatus.OperationStatus -ne "Succeeded")
                                            {
                                                Add-Content -Value "Increasing or Decreasing the instance size was not successfull" -Path $PSScriptRoot\SizeUpdate.Log
                                            }
                                            else
                                            {
                                                Write-Host -ForegroundColor "Updating $($detail.ServerName) instance size to $($SizeObj.Standard_D12)"
                                                Add-Content -Value "$($detail.ServerName) Instance is resized from $currentSize to $($SizeObj.Standard_D12)" -Path $PSScriptRoot\SizeStatusReport.txt
                                            }
                                            break
                                        }
                        "Standard_D13" {
                                            $OpStatus = $VMdetails | Set-AzureVMSize -InstanceSize $SizeObj.Standard_D13 | Update-AzureVM
                                            if($OpStatus.OperationStatus -ne "Succeeded")
                                            {
                                                Add-Content -Value "Increasing or Decreasing the instance size was not successfull" -Path $PSScriptRoot\SizeUpdate.Log
                                            }
                                            else
                                            {
                                                Write-Host -ForegroundColor "Updating $($detail.ServerName) instance size to $($SizeObj.Standard_D13)"
                                                Add-Content -Value "$($detail.ServerName) Instance is resized from $currentSize to $($SizeObj.Standard_D13)" -Path $PSScriptRoot\SizeStatusReport.txt
                                            }
                                            break
                                        }
                        "Standard_D14" {
                                            $OpStatus = $VMdetails | Set-AzureVMSize -InstanceSize $SizeObj.Standard_D14 | Update-AzureVM
                                            if($OpStatus.OperationStatus -ne "Succeeded")
                                            {
                                                Add-Content -Value "Increasing or Decreasing the instance size was not successfull" -Path $PSScriptRoot\SizeUpdate.Log
                                            }
                                            else
                                            {
                                                Write-Host -ForegroundColor "Updating $($detail.ServerName) instance size to $($SizeObj.Standard_D14)"
                                                Add-Content -Value "$($detail.ServerName) Instance is resized from $currentSize to $($SizeObj.Standard_D14)" -Path $PSScriptRoot\SizeStatusReport.txt
                                            }
                                            break
                                        }
                    }
                    continue
                }
                else
                {
                    Add-Content -Value "Cannot update the instance while it is in provisioning or updating state" -Path $PSScriptRoot\SizeUpdate.Log
                    continue
                }
            }
            else
            {
                Add-Content -Value "Cannot find the details" -Path $PSScriptRoot\SizeUpdate.Log
                continue
            }
        }
    }
    else
    {
        Add-Content -Value "Unable to servers data in the specified file" -Path $PSScriptRoot\SizeUpdate.log
        exit
    }
}
else
{
    Write-Host "The provided subscription does not exist"
    exit    
}