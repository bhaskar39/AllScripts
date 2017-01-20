<#
.SYNOPSIS
    The script to check the whether the cloud service exist 
.DESCRIPTION
    This is to check whether the cloud service is exist in given users azure subscription
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -ServiceName                    : Name of the storage account in lowercase
.EXAMPLE
    Is-CloudServiceNameAvailable -ServiceName 'service name'
#>
function Is-CloudServiceNameAvailable
{
    param(
        [Parameter(Mandatory=$true)] 
        [string]$ServiceName
            )
    try
    {
        $NameAvailableInSub = Get-AzureService | Where-Object {$_.ServiceName -ieq $ServiceName}
        return $NameAvailableInSub       
    }
    catch
    {
        #exit 1
        Throw $_
    }
}
<#
.SYNOPSIS
    The script to create new cloud service in the given user's azure subscription
.DESCRIPTION
    This is to create the new cloud service in user's azure subscription
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Name                       : name of cloud service
    -Location                   : azure region
    -Affinity                   : affinity group name

.EXAMPLE
    Create-CloudService -Name 'service name' -Location 'east us' -Affinity 'affinity'
#>
function Create-CloudService
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(ParameterSetName="Location")]
        [string]$Location,
        [Parameter(ParameterSetName="Affinity")] 
        [string]$Affinity
        )
    try
    {                        
        if($Affinity)
        {
            # create the cloud service  based on the affinity group
            $success = New-AzureService -ServiceName $Name -AffinityGroup $affi
            if($success.OperationStatus -ieq "Succeeded")
            {
                #Write-Host -ForegroundColor Green "The Cloud Service has been successfully created in this affinity Group"
                return $true
            }
            else
            {
                Write-Host -ForegroundColor Red "The was error while creating the cloud service"
                #exit 73
                return $false
            }       
        }
        elseif($Location)
        {   # create the cloud service  based on the Location
            $success = New-AzureService -ServiceName $Name -Location $Loc   
            if($success.OperationStatus -ieq "Succeeded")
            {
                #Write-Host -ForegroundColor Green "The Cloud Service has been successfully created in this Location"
                return $true
            }
            else
            {
                Write-Host -ForegroundColor Red "The was error while creating the Cloud service"
                #exit 73
                return $false
            } 
        }
        else
        {
            #
        }
    }
    catch
    {
        Write-Host -ForegroundColor Red "Network error"
        #exit 1
        Throw $_
    }
}
<#
.SYNOPSIS
    The script to delete the cloud service
.DESCRIPTION
    This is to delete the cloud service which is not having any virtual machines
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Name                    : Name of the cloud service
.EXAMPLE
    Delete-CloudService -Name 'cloud service name'
#>
function Delete-CloudService
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )       
    try
    {
        # calling the function to check the cloud service existence in subscription
        $exist = Is-CloudServiceNameAvailable -ServiceName $Name
        if($exist -ne $null)
        {
            $InstancesInSer = Get-AzureVM -ServiceName $Name # Checking for the Instances in the cloud service
            if($InstancesInSer -ne $null)
            {
                Write-Host -ForegroundColor Green "The cloud service having these Virtual Machines "                    
                $InstancesInService = $InstancesInSer | %{$_.Name}  # Displying the instances in the cloud service
                Write-Host -ForegroundColor Green "$InstancesInService"
                if((Read-Host "Do you want to delete all deployments:y/n") -ieq "y") # asking for the conformation
                {
                    Remove-AzureService -ServiceName $Name -Force -DeleteAll # Deleting the cloud service with all deployments
                    $exist1 = Is-CloudServiceNameAvailable -ServiceName $Name
                    if($exist1 -eq $null)
                    {
                        #Write-Host -ForegroundColor Green "The Cloud service has been deleted successfully"
                        return $true
                    }
                    else
                    {
                        Write-Host -ForegroundColor Red "There was an error while deleting the Service"
                        #exit 75
                        return $false
                    }
                }
                else
                {
                    Write-Host -ForegroundColor Red "Exiting Now.."
                    #exit
                    return $false
                } 
            }
            else
            {
                Remove-AzureService -ServiceName $Name -Force # deleting the empty cloud service
                $exist1 = Is-CloudServiceNameAvailable -ServiceName $Name
                if($exist1 -eq $null)
                {
                    #Write-Host -ForegroundColor Green "The Cloud service has been deleted successfully"
                    return $true
                }
                else
                {
                    Write-Host -ForegroundColor Red "The Cloud Service deletion was not successful"
                    #exit
                    return $false 
                }
            }   
        }
        else
        {
            Write-Host -ForegroundColor Red "The cloud service does not exist in your subscription"
            #exit 71
            return $false
        }
    }
    catch
    {
        Write-Host -ForegroundColor Red "Network error"
        #exit 1
        Throw $_
    }
}
<#
.SYNOPSIS
    The script to start the cloud service
.DESCRIPTION
    This is to start the cloud service
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Name                       : Name of the cloud service
.EXAMPLE
    Start-CloudService -Name 'cloud service name'
#>
function Start-CloudService
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    try
    {   # calling the function to check the cloud service existence in subscription
        $exist = Is-CloudServiceNameAvailable -ServiceName $Name
        if($exist -ne $null)
        {   # Starting the cloud service
            Start-AzureService -ServiceName $Name -Slot Production
            #Write-Host -ForegroundColor Green "The cloud Service is being started"
            return $true                 
        }
        else
        {
            Write-Host -ForegroundColor Red "The cloud service does not exist in your subscription"
            #exit 71
            return $false
        }
    }
    catch
    {
        Write-Host -ForegroundColor Red "Network error"
        #exit 1
        Throw $_
    }
}
<#
.SYNOPSIS
    The script to stop the cloud service
.DESCRIPTION
    This is to stop the cloud service
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Name                       : Name of the cloud service
.EXAMPLE
    Stop-CloudService -Name 'cloud service name'
#>
function Stop-CloudService
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    try
    {   # calling the function to check the cloud service existence in subscription
        $exist = Is-CloudServiceNameAvailable -ServiceName $Name
        if($exist -ne $null)
        {   # Stopping the cloud service
            Stop-AzureService -ServiceName $Name -Slot Production
            #Write-Host -ForegroundColor Green "The cloud Service is being stopped"
            return $true                
        }
        else
        {
            Write-Host -ForegroundColor Red "The cloud service does not exist in your subscription"
            #exit 71
            return $false
        }
    }
    catch
    {
        Write-Host -ForegroundColor Red "Network error"
        #exit 1
        Throw $_
    }
}