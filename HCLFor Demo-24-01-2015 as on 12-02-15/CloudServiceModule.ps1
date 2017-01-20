<#
    .DESCRIPTION
        This is the Module which provides functions for cloud service opeerations such as Create, Delete, Start and Stopping.
    .AUTHOR
        BHASKAR DESHARAJU
    .USAGE
        Import this module into the script from where you want to operate the cloud servive and pass the parameters to functions
        in this module.
#>
function IsCloudServiceNameAvailableInSub
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
    catch [System.Net.Http.HttpRequestException]
    {
        #exit 1
        Throw $_
    }
}
############################################# Fucntion to create the cloud service ############################################
function CreateCloudService
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(ParameterSetName="Location")]
        [string]$Loc,
        [Parameter(ParameterSetName="Affinity")] 
        [string]$affi
        )
    try
    {                        
        if($affi)
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
        elseif($Loc)
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
    catch  [System.Net.Http.HttpRequestException]
    {
        Write-Host -ForegroundColor Red "Network error"
        #exit 1
        Throw $_
    }
}
############################################# Delete the Cloud Service ######################################################
function DeleteCloudService
{
        Param(
            [Parameter(Mandatory=$true)]
            [string]$Name
            )
            
        try
        {
            # calling the function to check the cloud service existence in subscription
            $exist = IsCloudServiceNameAvailableInSub -ServiceName $Name
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
                        $exist1 = IsCloudServiceNameAvailableInSub -ServiceName $Name
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
                    $exist1 = IsCloudServiceNameAvailableInSub -ServiceName $Name
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
        catch [System.Net.Http.HttpRequestException]
        {
            Write-Host -ForegroundColor Red "Network error"
            #exit 1
            Throw $_
        }
}

################################## Function to Start the cloud service ###############################################
function StartCloudService
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Name
        )
    try
    {   # calling the function to check the cloud service existence in subscription
        $exist = IsCloudServiceNameAvailableInSub -ServiceName $Name
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
    catch [System.Net.Http.HttpRequestException]
    {
        Write-Host -ForegroundColor Red "Network error"
        #exit 1
        Throw $_
    }
}
################################## Function to Stop the cloud service ###############################################
function StopCloudService
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Name
        )
    try
    {   # calling the function to check the cloud service existence in subscription
        $exist = IsCloudServiceNameAvailableInSub -ServiceName $Name
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
    catch [System.Net.Http.HttpRequestException]
    {
        Write-Host -ForegroundColor Red "Network error"
        #exit 1
        Throw $_
    }
}