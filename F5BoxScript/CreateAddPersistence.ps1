<#
.SYNOPSIS
    This is to check whether the persistnce is already available in F5 box level
.DESCRIPTION
.PARAMETERS
.EXAMPLES
#>
Function Is-PersistencesExists
{
    Param
    (
        # Name of the Persistence to be checked
        [Parameter(Mandatory=$true)]
        [string]$PersistenceName,
        # F5 box connection object
        [Parameter(Mandatory=$true)]
        $GetF5
    )

    try
    {
        if($PersistenceName)
        {
            # Persistence creation class from F5 module and using to get the list of persistnce
            $persistnceObj = New-Object -TypeName iControl.LocalLBProfilePersistence
            $availablePersistenceList = $persistnceObj.get_list()
            if($availablePersistenceList -contains $PersistenceName)
            { 
                # Persistence is already available in F5
                Return 0
            }
            else    
            { 
                # Not available and free to create a new one
                Return 1
            }
        }
        else 
        {
            write-log "Please provide the name of the persistnce"       
        }   
    }
    catch
    {
        $outputDesc = $_.Exception.Message
        return 1 
        write-log "$outputDesc", 2
    }
}
<#
.SYNOPSIS
    This is to create the custom persistence in F5
.DESCRIPTION
.PARAMETERS
.EXAMPLES
#>
Function Create-Persistence
{
    Param
    (
        # Name of the persistnce to be created
        [Parameter(Mandatory=$true)]
        [string]$PeristenceName,
        # Type of the persistences available in F5
        [Parameter(Mandatory=$true)]
        [ValidateSet("Cookie","Destination Address Affinity","Hash","Microsoft Remote Desktop","SIP","Source Address Affinity","SSL","Universal")]
        [string]$PeristenceType,
        # Related to cookie
        [Parameter(ParameterSetName="Set1")]
        [string]$cookiePersistnceMethod,
        [Parameter(ParameterSetName="Set1")]
        [string]$cookieName,
        [Parameter(ParameterSetName="Set1")]
        [string]$cookieFlag,
        #[Parameter(ParameterSetName="Set1")]
        #[string]$cookiePersistnceMethod,
        #[Parameter(ParameterSetName="Set1")]
        #[string]$cookiePersistnceMethod,
        #[Parameter(ParameterSetName="Set1")]
        #[string]$cookiePersistnceMethod,
        #[Parameter(ParameterSetName="Set1")]
        #[string]$cookieName,
        #[Parameter(Mandatory=$true,ParameterSetName="Set1")]
        # Session time of the persistnce
        [Parameter(Mandatory=$true)]
        [string]$persistenceTime,
        [Parameter(Mandatory=$true)]
        [string]$persistenceTimeFlag

    )
    try
    {
        if($PeristenceName)
        {
            # Persistence mode for persistence which is defined in PersistenceType variable
            $mode = New-Object -TypeName iControl.LocalLBPersistenceMode;
            $mode = $PeristenceType
            $modes=(,$mode)
            # Creating the persistence
            $GetF5.LocalLBProfilePersistence.create($PeristenceName,$modes);
            if($?)
            {
                write-log "Persistence has been created successfully"
                # based on the PeristenceType, properties will be set
                switch ($PeristenceType)
                {
                    'Cookie'  {
                                # Reffering the persistence method. please refer the codes for the same
                                $persistnceMethod = New-Object -TypeName iControl.LocalLBProfileCookiePersistenceMethod
                                $persistnceMethod.value = $cookiePersistnceMethod
                                $persistnceMethods = (,$persistnceMethod)
                                # Setting the name for the cookie, and is optional, we can remove this code
                                $cookieName = New-Object -TypeName iControl.LocalLBProfileString;
                                $cookieName.value = $cookieName;
                                $cookieName.default_flag = $cookieFlag
                                # setting the session timeout for the persistence
                                $time = New-Object -TypeName iControl.LocalLBProfileULong;
                                $time.value=$persistenceTime
                                $time.default_flag = $persistenceTimeFlag
                                try
                                {
                                    # Finallt Setting the properties for persistence
                                    $GetF5.LocalLBProfilePersistence.set_cookie_persistence_method($PeristenceName,$persistnceMethods)
                                    $GetF5.LocalLBProfilePersistence.set_cookie_name($PeristenceName,$cookieName); 
                                    $GetF5.LocalLBProfilePersistence.set_cookie_expiration($cookieName,$times);
                                    # here we need to have proper command to check the execution of all commands at once
                                    return 0
                                }
                                catch
                                {
                                    return 1
                                }
                                break;
                            }
                    'Destination Address Affinity'  {   
                                                        # TBD
                                                        break;
                                                    }
                    'Microsoft Remote Desktop'  {
                                                    # TBD
                                                    break;
                                                }
                    'Hash'  {
                                # TBD
                                break;
                            }
                    'Universal'  {
                                        # TBD
                                        break;
                                }
                    'SIP'  {
                                # TBD
                                break;
                            }
                    'Source Address Affinity'  {
                                                    # TBD
                                                    break;
                                                }
                    'SSL' {
                                # TBD
                                break;
                            }
                }
            }
            else
            {
                write-log "There was an error while creating Persistence"    
            }
        }
        else
        {
            write-log "Persistnce name should not be empty"
        }            
    }    
    catch
    {
        $outputDesc = $_.Exception.Message
        return 1 
        write-log "$outputDesc", 2
    }
}   
<#
.SYNOPSIS
    This to be used to add the profile to the virtual server
.DESCRIPTION
.PARAMETERS
.EXAMPLES
#>
Function Add-ProfileToVirtualServer
{
    param
    (
        # Profle to be added to the virtual server
        [Parameter(Mandatory=$true)]
        [String]$profileName,
        # Code for the Profile
        [Parameter(Mandatory=$true)]
        [string]$profileContext,
        # Virtual Server Name
        [Parameter(Mandatory=$true)]
        [string]$vsName,
        [Parameter(Mandatory=$true)]
        $GetF5

    )
    try
    {
        # Creating the obj and setting the properties for profile
        $vipprofilehttp = New-Object "iControl.LocalLBVirtualServerVirtualServerProfile"
        if($profileName -and $profileContext -and $vsName)
        {
            $vipprofilehttp.profile_context = $profileContext
            $vipprofilehttp.profile_name = $profileName
        }
        if($vipprofilehttp)
        {
            # adding the profile to the virtualServer
            $GetF5.LocalLBVirtualServer.Add_profile($vsName,$vipprofilehttp)
            if($?)
            {
                write-log "HTTP profile has been added to the Virtual Server"
            }
            else 
            {
                write-log "There was error while adding the Profile"    
            }
        }
    }
    catch
    {
        $outputDesc = $_.Exception.Message
        return 1 
        write-log ""
    }
}
<#
.SYNOPSIS
    This is to add the persistence to the virtual server
.DESCRIPTION
.PARAMETERS
.EXAMPLES
#>
function Add-PersistenceToVirtualServer
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String]$persistenceProfileName,
        [Parameter(Mandatory=$true)]
        [String]$virtualServer,
        [Parameter(Mandatory=$true)]
        $GetF5
    )
    try
    {
        $vippersistence = New-object -TypeName iControlLocalLBVirtualServerVirtualServerPersistence;
        # Setting the properties
        if($persistenceProfileName)
        {
            $vippersistence.profile_name = $persistenceProfileName
            $vippersistence.default_profile = $null
        }   
        if(($virtualServer) -and ($vippersistence))
        {
            # Adding the profile to the virtual server
            $GetF5.LocalLBVirtualServer.add_persistence_profile($virtualServer,$vippersistence)
            if($?)
            {
                write-log "Persistence has been added Successfully", 1
                return 0
            }
            else 
            {
                write-log "There was an error while attaching the Persistence"
                return 1   
            }
        }
    }
    catch
    {
        $outputDesc = $_.Exception.Message
        return 1 
        write-log "$outputDesc", 2
    }
}


# This is to be included in the mail end-to-end workflow
#****** Persistence Modes ****************************************
#PERSISTENCE_MODE_NONE
#PERSISTENCE_MODE_SOURCE_ADDRESS_AFFINITY
#PERSISTENCE_MODE_DESTINATION_ADDRESS_AFFINITY
#PERSISTENCE_MODE_COOKIE
#PERSISTENCE_MODE_MSRDP
#PERSISTENCE_MODE_SSL_SID
#PERSISTENCE_MODE_SIP
#PERSISTENCE_MODE_UIE
#PERSISTENCE_MODE_HASH
#****** Cookie Methods *******************************************
#COOKIE_PERSISTENCE_METHOD_NONE
#COOKIE_PERSISTENCE_METHOD_INSERT
#COOKIE_PERSISTENCE_METHOD_REWRITE
#COOKIE_PERSISTENCE_METHOD_PASSIVE
#COOKIE_PERSISTENCE_METHOD_HASH
#*******HTTP profile *********************************************
#PROFILE_CONTEXT_TYPE_ALL
#PROFILE_CONTEXT_TYPE_CLIENT
#PROFILE_CONTEXT_TYPE_SERVER
#*****************************************************************
$inputPersistenceName = ""
$nameOfPersistence = ""
$typeOfPersistence=""
$cookieName=""
$cookieFlag=""
$timeOfPersistence=""
$timeFlagPersistence=""
$persistenceMethod=""
switch ($inputPersistenceName)
{
    Simple  {
                # setting the persistence code for Simple
                $strpersistenceProfileName = "source_addr"
                If((Is-PersistencesExists -PersistenceName $strpersistenceProfileName -GetF5 $GetF5) -eq 0)
                {
                    # Calling the function to add the persistence
                    $status = Add-PersistenceToVirtualServer -strpersistenceProfileName $strpersistenceProfileName -virtualServer $VS_Name
                    if($status)
                    {
                        write-log "Persistence has been added successfully to the server"
                    }
                    else
                    {
                        write-log "There was error while adding the persistence"
                    }
                }
                else
                {
                    write-log "The required Persistnec is not available in F5"
                }
                break;    
            }
    Cookie[Active] {
                        $strpersistenceProfileName = "cookie"
                        If((Is-PersistencesExists -PersistenceName $strpersistenceProfileName -F5Obj $GetF5) -eq 0)
                        {   
                            $strProfileName = "http"
                            $Profile_Context_typ = 'PROFILE_CONTEXT_TYPE_ALL'
                            # adding the profile to the virtualServer and should be used while creating the cookie persistence
                            $statusOfAdd = Add-ProfileToVirtualServer -profileName $strProfileName -profileContext $Profile_Context_typ -vsName $virtualServer
                            if($out)
                            {
                                $status = Add-PersistenceToVirtualServer -strpersistenceProfileName $strpersistenceProfileName -virtualServer $virtualServer                                
                                if($status)
                                {
                                    write-log "Persistence has been added successfully"
                                }
                                else
                                {
                                    write-log "There was an error while adding the persistence"
                                }
                            }
                            else
                            {
                                write-log "There was an error while adding the HTTP profile to the virtual server"
                            }
                        }
                        else
                        {
                            write-log "the required persistence is not available in F5 Box. Please create a new one"
                        }
                        break;       
                   }
    HTTP/SSL    {
                    $strpersistenceProfileName = 'ssl'
                    If((Is-PersistencesExists -PersistenceName $strpersistenceProfileName -F5Obj $GetF5) -eq 0)
                    {
                        $status = Add-PersistenceToVirtualServer -strpersistenceProfileName $strpersistenceProfileName -virtualServer $virtualServer
                        if($status)
                        {
                            Write-log "The persistnce has been added successfully"
                        }
                        else
                        {
                            write-log "There was an error while attching the Persistence"
                        }
                    }
                    else
                    {
                        write-log "the required persistence is not available in F5 Box. Please create a new one"
                    }
                    break;   
                }
    RDP     {
                $strpersistenceProfileName = 'msrdp'
                If((Is-PersistencesExists -PersistenceName $strpersistenceProfileName -F5Obj $GetF5) -eq 0)
                {
                    $status = Add-PersistenceToVirtualServer -strpersistenceProfileName $strpersistenceProfileName -virtualServer $virtualServer
                    if($status)
                    {
                        Write-log "The persistnce has been added successfully"
                    }
                    else
                    {
                        write-log "There was an error while attching the Persistence"
                    }
                }
                else
                {
                    write-log "the required persistence is not available in F5 Box. Please create a new one"
                }
                break;
            }

    Persistence_across_services     {
                                        $strpersistenceProfileName = 'universal'
                                        If((Is-PersistencesExists -PersistenceName $strpersistenceProfileName -F5Obj $GetF5) -eq 0)
                                        {
                                            $status = Add-PersistenceToVirtualServer -strpersistenceProfileName $strpersistenceProfileName -virtualServer $virtualServer                                           if($status)
                                            {
                                                Write-log "The persistnce has been added successfully"
                                            }
                                            else
                                            {
                                                write-log "There was an error while attching the Persistence"
                                            }
                                        }
                                        else
                                        {
                                            write-log "the required persistence is not available in F5 Box. Please create a new one"
                                        }
                                        break;
                                    }
            
    None    {
                break;
            }
    Custom  {
                If((Is-PersistencesExists -PersistenceName $nameOfPersistence -F5Obj $GetF5) -eq 1)
                {
                    Switch ($persistType)
                    {
                        "Cookie" {
                                        $createStatus = Create-Persistence -PeristenceName $nameOfPersistence -PeristenceType Cookie -cookiePersistnceMethod $persistenceMethod -cookieName $cookieName -cookieFlag $cookieFlag -persistenceTime $timeOfPersistence -persistenceTimeFlag $timeFlagPersistence 
                                    }
                        "Destination Address Affinity" {
                                                            $createStatus = Create-Persistence -PeristenceName $nameOfPersistence -PeristenceType Cookie -cookiePersistnceMethod $persistenceMethod -cookieName $cookieName -cookieFlag $cookieFlag -persistenceTime $timeOfPersistence -persistenceTimeFlag $timeFlagPersistence 
                                                        }
                        "Hash" {
                                    $createStatus = Create-Persistence -PeristenceName $nameOfPersistence -PeristenceType Cookie -cookiePersistnceMethod $persistenceMethod -cookieName $cookieName -cookieFlag $cookieFlag -persistenceTime $timeOfPersistence -persistenceTimeFlag $timeFlagPersistence 
                                }
                        "Microsoft Remote Desktop" {
                                                        $createStatus = Create-Persistence -PeristenceName $nameOfPersistence -PeristenceType Cookie -cookiePersistnceMethod $persistenceMethod -cookieName $cookieName -cookieFlag $cookieFlag -persistenceTime $timeOfPersistence -persistenceTimeFlag $timeFlagPersistence 
                                                    }
                        "SIP" {
                                    $createStatus = Create-Persistence -PeristenceName $nameOfPersistence -PeristenceType Cookie -cookiePersistnceMethod $persistenceMethod -cookieName $cookieName -cookieFlag $cookieFlag -persistenceTime $timeOfPersistence -persistenceTimeFlag $timeFlagPersistence 
                                }
                        "Source Address Affinity" {
                                                        $createStatus = Create-Persistence -PeristenceName $nameOfPersistence -PeristenceType Cookie -cookiePersistnceMethod $persistenceMethod -cookieName $cookieName -cookieFlag $cookieFlag -persistenceTime $timeOfPersistence -persistenceTimeFlag $timeFlagPersistence 
                                                    }
                        "Universal" {
                                        $createStatus = Create-Persistence -PeristenceName $nameOfPersistence -PeristenceType Cookie -cookiePersistnceMethod $persistenceMethod -cookieName $cookieName -cookieFlag $cookieFlag -persistenceTime $timeOfPersistence -persistenceTimeFlag $timeFlagPersistence 
                                        }
                    }
                    $status = Add-PersistenceToVirtualServer -strpersistenceProfileName $strpersistenceProfileName -virtualServer $virtualServer
                    if($status)
                    {
                        Write-log "The persistnce has been added successfully"
                    }
                    else
                    {
                        write-log "There was an error while attching the Persistence"
                    }
                }
                else
                {
                    write-log "the required persistence is not available in F5 Box. Please create a new one"
                }
                break;
            }
            
}                 