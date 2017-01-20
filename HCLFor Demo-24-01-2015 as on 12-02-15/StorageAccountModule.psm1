<#
.SYNOPSIS
    The script to check whether the storage account exists
.DESCRIPTION
    This is to check whether the storage account is exist in given users azure subscription
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -Storage                    : Name of the storage account in lowercase
.EXAMPLE
    Is-StorageExists -Storage 'storage name'
#>
function Is-StorageExist
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$Storage
    )
    try
    {
        $Stores = Get-AzureStorageAccount | Where-Object {$_.StorageAccountName -ieq $Storage}           
        return $Stores            
    }
    catch
    {
       #exit 1
       Throw $_
    }
} 
<#
.SYNOPSIS
    The script to check availability of container
.DESCRIPTION
    This is to check whether the given container is exist in the storage account of user's azure account
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -NewStorageAccount          : name of the storage account
    -Container                  : container name
.EXAMPLE
    Container -NewStorageAccount 'storage account' -Container 'container name'
#>
function Is-ContainerExist
{
     Param
     (
        [Parameter(Mandatory=$true)]
        [string]$NewStorageAccount,
        [Parameter(Mandatory=$true)]
        [string]$Container
     )
     try
     {
        $Stores = Is-StorageExist -Storage $StorageName
        if($Stores -ne $null)
        {
            # Getting the Storage account key
             $storageAccountKey = Get-AzureStorageKey $NewStorageAccount | %{ $_.Primary }
             # Getting the storage context
             $context = New-AzureStorageContext -StorageAccountName $NewStorageAccount -StorageAccountKey $storageAccountKey
             # Getting the containers    
             $Containers = Get-AzureStorageContainer -Context $context
             # Checking for the container exists
             $ContainerName = $Containers | Where-Object {$_.Name -ieq $Container}    
             if($ContainerName)
             {
                write-host -ForegroundColor Red "The Container name already exist"
                return $false
             }
             else
             {     
                Write-Host -ForegroundColor Green "Creating new $Container Container for this Storage"
                # Creating the new container
                $data = New-AzureStorageContainer $Container -Permission Container -Context $context
             }
         }
        else
        {
            Write-Host -ForegroundColor Red "Storage is not available in the subscription"
            #exit 57
            return $false
        }
     }
    catch
    {
        #Write-Host -ForegroundColor Red "Network error"
        #exit 1
        Throw $_
    }
}
<#
.SYNOPSIS
    The script to create the storage account
.DESCRIPTION
    This is to create the new storage account in the given azure region with a container
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -StorageName                : new storage account name
    -ContainerName              : container name to be created by default
    -Affinity                   : name of the affinity group
    -Location                   : azure region
    -GeoReplicaStore            : whether geo replication is to be enabled or not
.EXAMPLE
    Create-StorageAccount -StorageName 'storage name' -ContainerName 'test' -Affinity 'affinity' -Location 'east us' -GeReplicaStore $true
#>
function Create-StorageAccount
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$StorageName,
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(ParameterSetName="Aff")]
        [string]$Affinity,
        [Parameter(ParameterSetName="Loc")]
        [string]$Location,
        [Boolean]$GeoReplicaStore
        )        
    try
    {   
        if($Affinity)
        {
            # Creating the storage based on affinity
            $success = New-AzureStorageAccount -StorageAccountName $StorageName -AffinityGroup $Affinity
            if($success.OperationStatus -ieq "Succeeded")
            {
                #Write-Host -ForegroundColor Green "The Storage account $StorageAccount has been created successfully "
                Set-AzureStorageAccount -StorageAccountName $StorageName -GeoReplicationEnabled $GeoReplicaStore
                # Setting it to subscription
                Set-AzureSubscription -SubscriptionName $Subscription -CurrentStorageAccountName $StorageName
                # calling function to create the containers
                $cres = Is-ContainerExist -NewStorageAccount $StorageName -Container $ContainerName
                if($cres -ne $false)
                {
                    return $true
                }
                else
                {
                    return $false
                }  
            }
            else
            {
                Write-Host -ForegroundColor Red "Error occured while creating the storage account"
                return $false 
            }                        
        }
        elseif($Location)
        {   # creating storage based on Location
            $success = New-AzureStorageAccount -StorageAccountName $StorageName -Location $Location
            if($success.OperationStatus -ieq "Succeeded")
            {
                #Write-Host -ForegroundColor Green "The Storage account $StorageAccount has been created successfully "
                #Write-Host -ForegroundColor Green "The Storage account $StorageAccount has been created successfully "
                Set-AzureStorageAccount -StorageAccountName $StorageName -GeoReplicationEnabled $GeoReplicaStore
                # Setting it to subscription
                Set-AzureSubscription -SubscriptionName $Subscription -CurrentStorageAccountName $StorageName
                # calling function to create the containers
                $cres = Is-ContainerExist -NewStorageAccount $StorageName -Container $ContainerName
                if($cres -ne $false)
                {
                    return $true
                }
                else
                {
                    return $false
                }  
            }
            else
            {
                Write-Host -ForegroundColor Red "Error occured while creating the storage account"
                #exit 52
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
    The script to delete the storage account
.DESCRIPTION
    This is to delete the storage account with all it containers and blobs in it. user should make ensure before deleting the storage account
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -StorageName                : Name of the storage account
.EXAMPLE
    Delete-StorageAccount -StorageName 'storage name'
#>
function Delete-StorageAccount
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$StorageName
    )
    try
    {               
        # Getting the storage account key
        $StorageKey = Get-AzureStorageKey -StorageAccountName $StorageName
        # Getting the context for storage
        $context = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $StorageKey.Primary
        # Getting the containers in storage
        $ContainerPresent = Get-AzureStorageContainer -Context $context
        if($ContainerPresent -eq $null)
        {   # Removing storage if there are no containers   
            $a = Remove-AzureStorageAccount -StorageAccountName $StorageName
            if($a.OperationStatus -ieq "Succeeded")
            {
                #Write-Host -ForegroundColor Red "The Storage account $StorageName has been removed successfully"
                return $true
            }
            else
            {
                Write-Host -ForegroundColor Red "Error occured while removing the Storage Account"
                #exit 56
                return $false
            }          
        }
        else
        {   #if containers are there
            foreach($Container in $ContainerPresent)
            {   # getting the blobs in each container
                $Blobs = Get-AzureStorageBlob -Container $Container.Name -Context $context
                if($Blobs -ne $null)
                {
                    foreach($Blob in $Blobs)
                    {   # removing the blobs first
                        Remove-AzureStorageBlob -Blob $Blob.Name -Container $Container.Name -Context $context -Force -Verbose 
                    }
                }
                else
                {
                    write-host -ForegroundColor Green "Container is empty..."
                    #Remove-AzureStorageContainer -Name $Container.Name -Context $context
                }
                # then removing the container
                $a = Remove-AzureStorageContainer -Name $Container.Name -Context $context -Force
            }
            # removing the storage finnaly
            $a = Remove-AzureStorageAccount -StorageAccountName $StorageName
            if($a.OperationStatus -ieq "Succeeded")
            {
                #Write-Host -ForegroundColor Red "The Storage account $StorageName has been successfully removed along with all its containers "
                return $true
            }
            else
            {
                Write-Host -ForegroundColor Red "Error occured while removing the Storage Account"
                #exit 56
                return $false
            }  
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
    The script to set the storage account to current subscription
.DESCRIPTION
    This is to set the user provided storage account to current subscription
.NOTES
    Author                      : Bhaskar Desharaju
    Last Modified               : 02-07-2015
    Modification Description    : Added comments to the function
.PARAMETERS
    -StorageName                : Name of the storage account
    -Subscription               : Current subscription name
.EXAMPLE
    Set-StorageAccount -StorageName 'storage name' -Subscription 'subscription name'
#>
function Set-StorageAccount
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$StorageName,
        [Parameter(Mandatory=$true)]
        [string]$Subscription
    )
    try
    {   # checking for Storage existence in subscription
        # Setting the Storage account to Subscription
        $a = Set-AzureSubscription -SubscriptionName $Subscription -CurrentStorageAccountName $StorageName
        if((Get-AzureSubscription -Current -ExtendedDetails).CurrentStorageAccountName -ieq $StorageName)
        {
            #Write-Host -ForegroundColor Green "The Storage has been set successfully"
            return $true
        }
        else
        {
            Write-Host -ForegroundColor Red "Error occured while setting the storage account"
            #exit 58
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

########### Exporting all functions as power shell cmdlet ####################

Export-ModuleMember -Function * -Alias *

####################### End of the Script ##################################