$user=$args[0]
$password=$args[1]
$F5Box=$args[2]
$inputPersistenceName=$args[3]
$VSName=$args[4]

Function Is-PersistencesExists()
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
            #$persistnceObj = New-Object -TypeName iControl.LocalLBProfilePersistence
            $availablePersistenceList = $GetF5.LocalLBProfilePersistence.get_list()
            $persistences = @()
            foreach($a in $availablePersistenceList)
            {
                $b = $a.Split("/")[2]
                $persistences+=$b
            }
            if($persistences.contains($PersistenceName))
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
            #write-log "Please provide the name of the persistnce"       
        }   
    }
    catch
    {
        $outputDesc = $_.Exception.Message
        return 1 
        #write-log "$outputDesc", 2
    }
}

Function Get-F5Connection($username,$password, $F5boxhostname)
{
	try
    {
        "h"
        Add-PSSnapin iControlSnapIn
	    $password = ConvertTo-SecureString -String $password -AsPlainText -Force
	    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password
	    #Initialize connection with F5 box
	    Initialize-F5.iControl -HostName $F5boxhostname -PSCredentials $cred
	    if($? -eq $true)
	    {
	    	#Get-f5.iControl
		    $GetF5 = Get-F5.iControl 
		    return $GetF5
    	}
    	else
	    { 
		    Return 10
	    }
    }
    catch [system.exception]
	{
		Return 10			
	}
}

Function Add-ProfileToVirtualServer()
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
                #write-log "HTTP profile has been added to the Virtual Server"
            }
            else 
            {
                #write-log "There was error while adding the Profile"    
            }
        }
    }
    catch
    {
        $outputDesc = $_.Exception.Message
        return 1 
        #write-log ""
    }
}
function Add-PersistenceToVirtualServer()
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
        #$GetF5 = Get-F5Connection -username "admin" -password "Admin098" -F5boxhostname 52.11.186.160
        $vippersistence = New-object -TypeName "iControl.LocalLBVirtualServerVirtualServerPersistence"
        # Setting the properties
        if($persistenceProfileName)
        {
            $vippersistence.profile_name = $persistenceProfileName
            $vippersistence.default_profile = $null
        }   
            # Adding the profile to the virtual server
            $GetF5.LocalLBVirtualServer.add_persistence_profile($virtualServer,$vippersistence)
            if($?)
            {
                #write-log "Persistence has been added Successfully", 1
                return 0
            }
            else 
            {
                #write-log "There was an error while attaching the Persistence"
                return 1   
            }
    }
    catch
    {
        $outputDesc = $_.Exception.Message
        return 1 
        #write-log "$outputDesc", 2
    }
}

Add-PSSnapIn iControlSnapIn
$GetF5 = Get-F5Connection -username $user -password $password -F5boxhostname $F5Box
switch ($inputPersistenceName)
{
    Simple  {
                # setting the persistence code for Simple
                $strpersistenceProfileName = "source_addr"
                $ab = Is-PersistencesExists -PersistenceName $strpersistenceProfileName -GetF5 $GetF5
                If($ab -eq 0)
                {
                    # Calling the function to add the persistence
                    $status = Add-PersistenceToVirtualServer -persistenceProfileName $strpersistenceProfileName -virtualServer $VSName -GetF5 $GetF5
                    if($status)
                    {
                        #write-log "Persistence has been added successfully to the server"
                    }
                    else
                    {
                        #write-log "There was error while adding the persistence"
                    }
                }
                else
                {
                    #write-log "The required Persistnec is not available in F5"
                }
                break;    
            }           
} 
$status