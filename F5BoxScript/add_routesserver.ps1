$user="admin"#$args[0]
$pass="Admin098"#$args[1]
$F5box="52.11.186.160"#$args[2]
$destination="10.0.0.50"#$args[3]
$netMask="255.255.255.255"#$args[4]
$poolName="test_80_pl"#$args[5]

Function Get-F5Connection($username,$password, $F5boxhostname)
{
	try
    {
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

Function Add-RouteToServer
{
	[CmdletBinding()]
	Param (
			[parameter(Mandatory=$true)]
            [String]$destination,
            [parameter(Mandatory=$true)]
            [String]$netMask,
            [parameter(Mandatory=$true)]
            [String]$poolName,
            [parameter(Mandatory=$true)]
            [String]$userName,
            [parameter(Mandatory=$true)]
            [String]$passWord,
            [parameter(Mandatory=$true)]
            [String]$F5boxhostname

            )
    try
    {
        #New-Log -Dir $logPath $logFile
       $GetF5=Get-F5Connection -username $username -password $password -F5boxhostname $F5boxhostname
        if ($GetF5 -ne 10)
	    {
    		#Write-Log "Connected with F5 Box" 0
    	}
        else
        {
            #write-log "Unable to connect with the F5 box." 2
            return 10
        }
        $test=$GetF5.NetworkingRouteTable.get_static_route()
        #if ($test.destination.Contains($destination))
        #{
        #    #Write-Log "Destination IP and Netmask are already present" 2
        #    return 10
        #}
        #else
        #{
	        $Def1 = New-Object -TypeName iControl.NetworkingRouteTableRouteDefinition
	        $Def1.destination = $destination
	        $Def1.netmask = $netMask
	        $Attribute = New-Object -TypeName iControl.NetworkingRouteTableRouteAttribute
	       #If the user provide the route Type we need to proceed according to it for example if routeType is gateway then we need to accept gatewayIP as parameter
	       #Same is applicable for VLAN and Pool Name. This can only be coded once we will have the test box.
	        $Attribute.gateway = $null
	        $Attribute.pool_name = $poolName
	        $Attribute.vlan_name = $null
        	$GetF5.NetworkingRouteTable.add_static_route($Def1,$Attribute)
            if ($?)
            {
                 #Write-Log "Static Route created" 0
                 return 0
            }
            else
            {
                #Write-Log "Failed to create route" 2 
		        Return 10
            }
        #}
    }
    catch [system.exception]
	{
		
		#Write-Log "Failed to create route due to system exception + $_.exception" 2 
		Return 10			
	}
}
$status = Add-RouteToServer -destination $destination -netMask $netMask -poolName $poolName -userName $user -passWord $pass -F5boxhostname $F5box
$status