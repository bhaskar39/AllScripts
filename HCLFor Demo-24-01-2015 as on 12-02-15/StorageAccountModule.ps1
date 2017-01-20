<#
    .DESCRIPTION
        This is the module which provides function to operate on Azure Storage.
    .AUTHOR
        BHASKAR DESHARAJU
    .USAGE
        Import this module and call the storage functions with necessary parameters
#>
################################################# Fcuntion to check the storage exists ############################################
    function IsStorageExist
    {
        Param(
            [string]$Storage
            )
        try
        {
            $Stores = Get-AzureStorageAccount | Where-Object {$_.StorageAccountName -ieq $Storage}           
            return $Stores            
        }
        catch [System.Net.Http.HttpRequestException]
        {
           #exit 1
           Throw $_
        }
    } 
#################################### function to create the container in storage account####################################
    function Container
    {
         Param(
         [string]$NewStorageAccount,
         [string]$Container
         )
         try
         {
            $Stores = IsStorageExist -Storage $StorageName
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
        catch [System.Net.Http.HttpRequestException]
        {
            #Write-Host -ForegroundColor Red "Network error"
            #exit 1
            Throw $_
        }
    }
################################################ function to create the storage account ####################################################
    function CreateStorageAccount
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
                    $cres = Container -NewStorageAccount $StorageName -Container $ContainerName
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
                    $cres = Container -NewStorageAccount $StorageName -Container $ContainerName
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
        catch [System.Net.Http.HttpRequestException]
        {
            Write-Host -ForegroundColor Red "Network error"
            #exit 1
            Throw $_
        }
    }
############################################ function to delete the storage account #################################################
    function DeleteStorageAccount
    {
        Param(
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
        catch [System.Net.Http.HttpRequestException]
        {
            Write-Host -ForegroundColor Red "Network error"
            #exit 1
            Throw $_
        }
    }
################################################### function to Set the storage account to subscription ############################
    function SetStorageAccount
    {
        Param(
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
        catch [System.Net.Http.HttpRequestException]
        {
            Write-Host -ForegroundColor Red "Network error"
            #exit 1
            Throw $_
        }
    }