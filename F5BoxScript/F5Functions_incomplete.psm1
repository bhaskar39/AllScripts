<#
.SYNOPSIS
    Create connection with F5 BOX.
.DESCRIPTION
    This function will create connection with F5 BOX and return connection object.
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    Parameters		: -Username		User name of the user having access on server with admin rights.
					  -Password		Password of the user
					  -F5boxhostname	HostName of the F5 Box

.EXAMPLE
    Get-F5Connection -userName "fareast\testuser" -password "abcd" -F5boxhostname "testbox"
#>
#login admin pass Admin098
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

<#
.SYNOPSIS
    Create SNAT Pool
.DESCRIPTION
    This function will create the SNAT pool on F5 box. It will return 0 if SNAT pool gets created successfully else it will return 10.
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    Parameters		: -vipfqdn			Fully Qualified domain name of VIP.
					  -snatIP			IP address for Snat
					  -Username			User name of the user having access on server with admin rights.
					  -Password			Password of the user
					  -F5boxhostname	HostName of the F5 Box
					  -logPath 			Path of the folder in which log file needs to be stored.
					  -logFile 			Name of the log file
.EXAMPLE
    Create-SNATPool -vipfqdn "testVIP" -snatIP "10.10.10.10" -userName "fareast\testuser" -password "abcd" -F5boxhostname "testbox" -logPath "c:\logs" -logFile "testlog.log"
#>
################################################# CREATING SNAT POOL #################################################
Function Create-SNATPool 
{
[CmdletBinding()]
    Param (
			[parameter(Mandatory=$true)]
            [String]$vipfqdn,
			[parameter(Mandatory=$true)]
            [String[]]$snatIP,
			[parameter(Mandatory=$true)]
            [String]$username,
			[parameter(Mandatory=$true)]
            [String]$password,
			[parameter(Mandatory=$true)]
            [String]$F5boxhostname,
			[parameter(Mandatory=$true)]
            [String]$logPath,
			[parameter(Mandatory=$true)]
            [String]$logFile
			)
	#$vipfqdn="testfqdn.test.com"
	$vipname= $vipfqdn.split('.')
	$vipname1=$vipname[0]
	$SnatPoolName="$vipname1" + "_sn" + "_pl"
	New-Log -Dir $logPath $logFile
	#$snatIP="10.0.0.105"
	#$username="admin"
	#$password ="Admin098"
	#$F5boxhostname="52.24.197.85"
    Add-PSSnapIn iControlSnapIn
	if ( (Get-PSSnapin | Where-Object { $_.Name -eq "iControlSnapIn"}) -ne $null )
	{   
		Write-Log " Creating Connection to the F5box Device " 0
		
		$AuthObj = Get-F5Connection -username "admin" -password "Admin098" -F5boxhostname "52.25.85.77"
		# Get-F5.iControlCommands
		### $snatip1=@("10.0.0.2","10.0.0.3","10.0.0.4")
		### $snatip2=@("10.0.0.5","10.0.0.6","10.0.0.7","10.0.0.8")
		### $snatip = @($snatip1,$snatip2)
		### $vips=@("testvip3_sn_pl","testvip4_sn_pl")
		### $snatpoolname= "$vip" + "_sn" + "_pl"
		#$testobj=New-Object -TypeName icontrol.LocalLBSNATPool
		################# Getting the list of  Pools and checking already existed or not ###############
		$checkLBSnatpool=$AuthObj.LocalLBSNATPool.get_list()
		if($checkLBSnatpool -match $SnatPoolname)
		{
			write-Log "SnatPool is already Exists " 2
			$outputstatus=10
		}
		else
		{  
			Write-Log " SNAT Pool is not exists..Go ahead and create the SNAT" 0
			$createsnatpool=$AuthObj.LocalLBSNATPool.create_v2($SnatPoolName,$snatip)
			if($? -eq $true)
			{
				write-Log "Sucessfully created the snatpool" 0
				$AuthObj.SystemConfigSync.save_configuration("/config/bigip.conf","SAVE_HIGH_LEVEL_CONFIG")
				$outputstatus=0
			}
			else 
			{
				write-Log "Snatpool creation failed " 2
				$outputstatus=10
			}
		}
	}
	else
	{
		write-log "Snatpool creation failed as iControlSnapIn is not installed" 2
		return 10
	}
	return $outputstatus
}

<#
.SYNOPSIS
    Create health monitor.
.DESCRIPTION
    This function will create health monitor in F5 Box. It will return 0 if health monitor gets created successfully,
	else it will return 10.
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    Parameters		: -templateName		Name of the Template.
					  -templateType		Type of the template e.g. TTYPE_HTTP, TTYPE_HTTPS, TTYPE_TCP etc.
					  -templateInterval	Interval time for the template
					  -templateTimeOut	Timeout value for template
					  -Username			User name of the user having access on server with admin rights.
					  -Password			Password of the user
					  -F5boxhostname	HostName of the F5 Box
					  -logPath 			Path of the folder in which log file needs to be stored.
					  -logFile 			Name of the log file
.EXAMPLE
    Res=Create-HealthMonitor -templateName "temp_1" -templateType "TTYPE_HTTP" -templateInterval 30 -templateTimeOut 60 -userName "fareast\testuser" -password "abcd" -F5boxhostname "testbox" -logPath "c:\logs" -logFile "testlog.log"
.EXAMPLE
    Example 2
#>
Function Create-HealthMonitor
{
	[CmdletBinding()]
    Param (
			[parameter(Mandatory=$true)]
            [String]$templateName,
			[parameter(Mandatory=$true)]
            [String]$templateType,
			[parameter(Mandatory=$true)]
            [int]$templateInterval,
			[parameter(Mandatory=$true)]
            [int]$templateTimeOut,
			[parameter(Mandatory=$true)]
            [String]$username,
			[parameter(Mandatory=$true)]
            [String]$password,
			[parameter(Mandatory=$true)]
            [String]$F5boxhostname,
			[parameter(Mandatory=$true)]
            [String]$logPath,
			[parameter(Mandatory=$true)]
            [String]$logFile
		)

	if(($templateName) -and ($templateType) -and ($templateInterval) -and ($templateTimeOut) -and ($username) -and ($password) -and ($F5boxhostname) -and ($logPath) -and ($logFile))
	{
        New-Log -Dir $logPath $logFile
	    Add-PSSnapin iControlSnapIn
		try
		{
            Write-Log "Connecting to F5 box" 0
			$GetF5=Get-F5Connection -username $username -password $password -F5boxhostname $F5boxhostname
			if ($GetF5 -ne 10)
			{
			    Write-Log "Connected to F5 box" 0	
			}
            else
            {
                write-log "Unable to connect with the F5 box." 2
				return 10
            }
			$obj = New-Object -TypeName iControl.GlobalLBMonitorCommonAttributes
			$MonTemp = New-Object -TypeName iControl.LocalLBMonitorMonitorTemplate
			$MonTemp.template_name = $templateName
			Switch ($templateType)
			{
				"TTYPE_HTTP"{$MonTemp.template_type = 'TTYPE_HTTP'} #On hold Bhasker need to confirm.
			}
			$MonAttr = New-Object -TypeName iControl.LocalLBMonitorCommonAttributes
			$MonAttr.interval= $templateInterval
			$MonAttr.timeout = $templateTimeOut
			$MonAttr.parent_template = 'http'
			$a = New-Object -TypeName iControl.LocalLBMonitorIPPort
			$a.address_type = "ATYPE_UNSET"
			$b = New-Object -TypeName iControl.CommonIPPortDefinition
			$b.address = '0.0.0.0'
			$b.port = 0 
			$a.ipport = $b
			$MonAttr.dest_ipport = $a
			$MonAttr.is_directly_usable = $null
			$MonAttr.is_read_only = $null
			$Mon = New-Object -TypeName iControl.LocalLBMonitor
			$GetF5.LocalLBMonitor.create_template($MonTemp,$MonAttr)
			if($? -eq $true)
			{
				$GetF5.SystemConfigSync.save_configuration("/config/bigip.conf","SAVE_HIGH_LEVEL_CONFIG")
				Write-Log "Health Monitor is created successfully" 0
				return 0
			}
			else
			{
				Write-Log "Health Monitor creation failed" 2
				return 10
			}
		}
		catch [system.exception]
		{
			$message = "Failed to create Health Monitor due to system exception + $_.exception"     
			Write-Log $message 2 
			Return 10			
		}
	}
	else
	{
		return 10
	}
}

<#
.SYNOPSIS
	This will create the VIP Pool
.DESCRIPTION
   This function will create VIP pool in F% box which will be used in the creation of Virtual server.
   It will return 0 if VIP pool gets created successfully, else it will return 10.
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    Parameters		: -vipName			Name of VIP
					  -port				Port numbers, it could be single or multiple
					  -IPS				IP addresses, it could be single or multiple
					  -lbMethod			Load balancing methond.
					  -monitoringEnabled Is monitoring need to be enable or not.
					  -Username			User name of the user having access on server with admin rights.
					  -Password			Password of the user
					  -F5boxhostname	HostName of the F5 Box
					  -logPath 			Path of the folder in which log file needs to be stored.
					  -logFile 			Name of the log file	
.EXAMPLE
	$outputstatus = Create-VIPPool -vipName "testVip" -ports "80","433" -IPS "10.10.10.10","10.10.10.11" -monitoringEnabled "YES" -userName "fareast\testuser" -password "abcd" -F5boxhostname "testbox" -logPath "c:\logs" -logFile "testlog.log"
#>
Function Create-VIPPool 
{
	[CmdletBinding()]
	Param (
			[parameter(Mandatory=$true)]
            [String]$vipName,
			[parameter(Mandatory=$true)]
            [int[]]$ports,
			[parameter(Mandatory=$true)]
            [String[]]$ips,
			[parameter(Mandatory=$true)]
            [String]$lbMethod, 
			[parameter(Mandatory=$true)]
            [String]$monitoringEnabled,
			[parameter(Mandatory=$true)]
            [String]$username,
			[parameter(Mandatory=$true)]
            [String]$password,
			[parameter(Mandatory=$true)]
            [String]$F5boxhostname,
			[parameter(Mandatory=$true)]
            [string]$LogFilePath,
			[parameter(Mandatory=$true)]
            [String]$LogFileName)

	$names = @()
    $flag=0
	try
	{
		Add-PSSnapin iControlSnapIn
		$GetF5=Get-F5Connection -username $username -password $password -F5boxhostname $F5boxhostname
		New-Log -Dir $LogFilePath $LogFileName
		if ($GetF5 -ne 10)
		{
            write-log "Connected with F5 BOX" 0
		}
        else
        {
			write-log "Unable to connect with the F5 box." 2
            return 10            
        }
		Switch ($lbMethod)
		{
			"Round Robin"{$lbMethod = "LB_METHOD_ROUND_ROBIN"}
			"Ratio" {$lbMethod = "LB_METHOD_RATIO_MEMBER"}
			"Least Connections" {$lbMethod = "LB_METHOD_LEAST_CONNECTION_MEMBER"}
		}
		if($ports.Length -gt 1)
		{
			foreach($port in $ports)
			{
				$names += $vipName + "_" +$port +"_" + "pl"
			}
		}
		else
		{
			$names += $vipName + "_" +$ports + "_" + "pl"
		}

		$namesExist = $GetF5.LocalLBPool.get_list()
		#$GetF5.LocalLBPool.get_list() -like "/*/$names"
		if($namesExist)
		{
			$namesExist = $namesExist | %{($_ -split "/")[2]}
            for($i = 0;$i -lt $names.Length;$i++)
			{
				if($namesExist.Contains($names[$i]))
				{
					$msg="Conflict in the names " + $names[$i]
                    write-log $msg 2
                    $flag=10 
				}
            }
            if ($flag -eq 10)
            {Return 10}
			for($i = 0;$i -lt $names.Length;$i++)
			{
                $msg="Creating VIP Pools names " + $names[$i]
                write-log $msg 0
	    		$vipObj = New-Object -TypeName iControl.CommonIPPortDefinition[] $ips.Length
				for($j=0;$j -lt $ips.Length;$j++)
				{
					$vipObj[$j]  = New-Object -TypeName iControl.CommonIPPortDefinition
					$vipObj[$j].address = $ips[$j]
					$vipObj[$j].port = $ports[$i]
				}
				$status = $GetF5.LocalLBPool.create($names[$i],$lbMethod,(,$vipObj))
				$GetF5.LocalLBPool.set_description($names[$i],$ports[$i])
				if($monitoringEnabled -eq 'YES')
				{
					$monitor_association = New-Object -TypeName iControl.LocalLBPoolMonitorAssociation
					$monitor_association.pool_name = $names[$i]
					$monitor_association.monitor_rule = New-Object -TypeName iControl.LocalLBMonitorRule
					$monitor_association.monitor_rule.type = "MONITOR_RULE_TYPE_SINGLE"  #Check with Bhasker once we have the box
					$monitor_association.monitor_rule.quorum = 0
					$monitor_association.monitor_rule.monitor_templates = (, 'tcp')		#Check with Bhasker once we have the box
					$GetF5.LocalLBPool.set_monitor_association( (, $monitor_association) )     
					#$GetF5.LocalLBPool.get_monitor_association($names[$i]).monitor_rule		#To get the updated rule list
				}
				Write-Log "VIP Pool created successfully" 0
			}
		
		}
	}
	catch
	{
			Write-Log "Failed to create VIP POOL due to system exception + $_.exception" 2 
			Return 10	
	}
return 0
}
<#
.SYNOPSIS
	Check the status of VIP
.DESCRIPTION
    This function will check the status of newly created VIP and check if it is fullfilling all the 
	needs requested by the user.
.NOTES
    Author          :	Pankaj Soni
    Prerequisite    :	PowerShell V2 over Vista and upper.
	Parameters		: -VIPName			name of VIP
					  -Username			User name of the user having access on server with admin rights.
					  -Password			Password of the user
					  -F5boxhostname	HostName of the F5 Box
					  -logPath 			Path of the folder in which log file needs to be stored.
					  -logFile 			Name of the log file	    
.EXAMPLE
	$outputstatus = Check-VIPStatus -VIPName "testVIP" -userName "fareast\testuser" -password "abcd" -F5boxhostname "testbox" -logPath "c:\logs" -logFile "testlog.log"
#>
function Check-VIPStatus
{
	[CmdletBinding()]
	Param (
			[parameter(Mandatory=$true)]
            [String]$VIPName,
			[parameter(Mandatory=$true)]
            [String]$route,
			[parameter(Mandatory=$true)]
            [String]$givenRouteType,
			[parameter(Mandatory=$true)]
            [String]$routeTypeValue,
			[parameter(Mandatory=$true)]
            [String]$poolName,
			[parameter(Mandatory=$true)]
            [String]$persistenceName,
			[parameter(Mandatory=$true)]
            [String]$snatName,
			[parameter(Mandatory=$true)]
            [String]$templateName,
			[parameter(Mandatory=$true)]
            [int[]]$LogFilePath,
			[parameter(Mandatory=$true)]
            [String[]]$LogFileName,
			[parameter(Mandatory=$true)]
            [String[]]$username,
			[parameter(Mandatory=$true)]
            [String[]]$password,
			[parameter(Mandatory=$true)]
            [String[]]$F5boxhostname,			
			[parameter(Mandatory=$true)]
            [string]$LogPath,
			[parameter(Mandatory=$true)]
            [String]$LogFile)
	try
	{
		$VIPStatus=0
		$VIPPingStatus=0
		$snatStatus=0
		$routesStatus=0
		$persistenceStatus=0
		$poolStatus=0
		
		Add-PSSnapin iControlSnapIn
		$GetF5=Get-F5Connection -username $username -password $password -F5boxhostname $F5boxhostname
		New-Log -Dir $logPath $logFile
		if ($GetF5 -eq 10)
		{
			write-log "Unable to connect with the F5 box." 2
            return 10
		}
		$namesExist = $GetF5.LocalLBPool.get_list() -like "/*/$VIPName"
		if($namesExist)
		{
			write-log "VIP Name present on the server" 0
		}
		else
		{
			Write-Log "VIP Name is not present on the server" 2
			$VIPStatus=10
		}
			
		#We will perform the below tasks when we have the commands and test box available
			#Capture the VIP Map to see if the Nodes and VIP status is healthy. PING the VIP Name
			$VIPPingStatus=Check-Connection -server $VIPName -logPath $inputValidationLogPath -logFile $inputValidationLogFile #Calling CheckConnection function from PreCheckMod to Check if the server is on-line 
			if (VIPPingStatus -eq 10)
			{
				#Write log for Failed ping status
			}
			#Check if the routes are added correctly.
			$rt = New-Object -TypeName iControl.NetworkingRouteTableV2
			#$rtname = "static route"
			$getRoute=$rt.get_static_route_list() -like "/*/$route" ## we need to check for the particular static route by filtering
			if ($getRoute)
			{
				$routeType = $rt.get_static_route_type($route) ## to get the type selected for routing i.e gateway, pool, vlan 3 options are available
				<#switch ($routeType) #$routeTypeValue variable need to be compared with the value received from the below routeType switch statement 
				{
					"gateway" {$gatewayIP=$rt.get_static_route_gateway($route)} # if type is gateway, get the gateway address
					"pool" {$vipPoolName=$rt.get_static_route_pool($route)} # if type is pool, then get the pool associated
					"vlan" {$vlanID=$rt.get_static_route_vlan($route)} # if type is vlan, then get the vlan id
				}#>
				if (!$?)
				{
					$routesStatus=10
					Write-Log "Route detials are not found on server. Route either not created or not configured correctly" 2
				}
				else
				{
					#Write log
					#Success
				}
			}
			else
			{
				#Write log Route not found
				$routesStatus=10
			}
			#Check if the persistence is set as per requirement.
			$vs = New-Object -TypeName iControl.LocalLBVirtualServer
			$vs.get_persistence_profile($persistenceName)
			if (!$?)
			{
				$persistenceStatus = 10
			}
			else
			{
				#Success
			}
			#Check if the SNAT pool is applied to the VIP
			$vs.get_snat_pool($snatName)
			if (!$?)
			{
				$snatStatus = 10
			}
			else
			{
				#successfully
			}
			#Check if the extended monitor is configured as per requirement
			$mon = New-Object -TypeName iControl.LocalLBPool
			$mon.get_monitor_association($poolName)
			if ($?)
			{
				$mon = New-Object -TypeName iControl.LocalLBMonitor
				$mon.get_parent_template($templateName)
				$mon.get_template_type($templateName)
				$mon.get_template_address_type($templateName)
				if(!$?)
				{
					$poolStatus = 10
				}
				else
				{
					#Success
				}
			}

	}
	catch [system.exception]
	{
		
		Write-Log "Failed to check VIP Name due to system exception + $_.exception" 2 
		Return 10			
	}
	if (($VIPStatus -eq 10) -or ($snatStatus -eq 10) -or ($routesStatus -eq 10) -or ($persistenceStatus -eq 10) -or ($poolStatus -eq 10))
	{
		#Write fail log
		return 10
	}
	else
	{
		#Write successful log
		return 0
	}
}

<#
.SYNOPSIS

.DESCRIPTION
   
.NOTES
    Author         : Pankaj Soni
    Prerequisite   : PowerShell V2 over Vista and upper.
    
.EXAMPLE
$outputstatus = Sync-F5box -userName "fareast\testuser" -password "abcd" -F5boxhostname "testbox" -logPath "c:\logs" -logFile "testlog.log"
#>
Function Sync-F5box
{
	[CmdletBinding()]
	Param (
			[parameter(Mandatory=$true)]
            [int[]]$LogFilePath,
			[parameter(Mandatory=$true)]
            [String[]]$LogFileName,
			[parameter(Mandatory=$true)]
            [String[]]$username,
			[parameter(Mandatory=$true)]
            [String[]]$password,
			[parameter(Mandatory=$true)]
            [String[]]$F5boxhostname)
	try
	{
		New-Log -Dir $logPath $logFile
		$password = ConvertTo-SecureString -String $password -AsPlainText -Force
		$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $uname,$password
		$session = New-SSHSession -ComputerName $F5boxhostname -Port 22 -Credential $cred 
		Invoke-SSHCommand -Command ' b config sync all' -SSHSession $session
		if ($?)
		{
			Write-Log "F5 Box Synced successfully" 0
		}
		else
		{
			Write-Log "Unable to Sync F5 Box" 2
			return 10
		}
		$Success = Remove-SSHSession -SSHSession $session
		$GetF5.SystemConfigSync.save_configuration("/config/bigip.conf","SAVE_HIGH_LEVEL_CONFIG")
		if ($?)
		{
			Write-Log "Configuration saved successfully" 0
			return 0
		}
		else
		{
			Write-Log "Failed to Sync the configuration" 2
			return 10
		}
	}
	catch [system.exception]
	{
		
		Write-Log "Failed to Sync the F5 Box's due to system exception + $_.exception" 2 
		Return 10			
	}
}
<#
.SYNOPSIS
	Check if port is opened or not.
.DESCRIPTION
	It will check if the ports passed in argumant -ports are open for IP or server name given in -VIPName
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    Parameters		: -VIPName			name of VIP
					  -Ports			Port(s) number which needes to be checked
					  -logPath 			Path of the folder in which log file needs to be stored.
					  -logFile 			Name of the log file		
.EXAMPLE
	$outputstatus = Check-VIPPortStatus -VIPName "testVIP" -logPath "c:\logs" -logFile "testlog.log"
#>
Function Check-VIPPortStatus($VIPName,$Ports,$logPath,$logFile)
{
	if ( ($Ports) -and ($VIPName) -and ($logPath) -and ($logFile)) #Check for all parameters
	{
		try
		{
			New-Log -Dir $logPath $logFile
			$flag=0
			foreach ($Port in $Ports) 
			{
				# Create a Net.Sockets.TcpClient object to use for
				# checking for open TCP ports.
				$Socket = New-Object Net.Sockets.TcpClient
				# Suppress error messages
				$ErrorActionPreference = 'SilentlyContinue'
				# Try to connect
				$Socket.Connect($VIPName, $Port)
				# Make error messages visible again
				$ErrorActionPreference = 'Continue'
				# Determine if we are connected.
				if ($Socket.Connected) 
				{
					Write-Log "${VIPName}: Port $Port is open" 0
					$Socket.Close()
				}
				else 
				{
					Write-Log "${VIPName}: Port $Port is closed or filtered" 1 
					$flag=10
				}
			}
		}
		catch [system.exception]
		{
			$ConStatus = $null
			$message = "Failed to check server health due to system exception + $_.exception"     
			Write-Log $message 2   
			return 10
		}
	}
	else
	{
		Write-Log "Some parameters are missing" 2
		Return 10
	}
	return $flag
}

<#
.SYNOPSIS
	Add the routes to server.
.DESCRIPTION
   Add the requested routes to the destination passed as parameter to function
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    Parameters		: -destination	
					  -netMask
					  -poolName
.EXAMPLE

#>
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
            [String]$F5boxhostname,
            [parameter(Mandatory=$true)]
            [String]$LogPath,
            [parameter(Mandatory=$true)]
            [String]$logFile

            )
    try
    {
        New-Log -Dir $logPath $logFile
       $GetF5=Get-F5Connection -username $username -password $password -F5boxhostname $F5boxhostname
        if ($GetF5 -ne 10)
	    {
    		Write-Log "Connected with F5 Box" 0
    	}
        else
        {
            write-log "Unable to connect with the F5 box." 2
            return 10
        }
        $test=$getf5.NetworkingRouteTable.get_static_route()
        if ($test.destination.Contains($destination) -and $test.netmask.Contains($netMask))
        {
            Write-Log "Destination IP and Netmask are already present" 2
            return 10
        }
        else
        {
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
                 Write-Log "Static Route created" 0
                 return 0
            }
            else
            {
                Write-Log "Failed to create route" 2 
		        Return 10
            }
        }
    }
    catch [system.exception]
	{
		
		Write-Log "Failed to create route due to system exception + $_.exception" 2 
		Return 10			
	}
}
function Get-IPrange
{
<# 
  .SYNOPSIS  
    Get the IP addresses in a range 
  .EXAMPLE 
   Get-IPrange -start 192.168.8.2 -end 192.168.8.20 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.2 -mask 255.255.255.0 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.3 -cidr 24 
#> 
 
param 
( 
  [string]$start, 
  [string]$end, 
  [string]$ip, 
  [string]$mask, 
  [int]$cidr 
) 
 
function IP-toINT64 () { 
  param ($ip) 
 
  $octets = $ip.split(".") 
  return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
} 
 
function INT64-toIP() { 
  param ([int64]$int) 

  return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
} 
 
if ($ip) {$ipaddr = [Net.IPAddress]::Parse($ip)} 
if ($cidr) {$maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2)))) } 
if ($mask) {$maskaddr = [Net.IPAddress]::Parse($mask)} 
if ($ip) {$networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)} 
if ($ip) {$broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))} 
 
if ($ip) { 
  $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring 
  $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring 
} else { 
  $startaddr = IP-toINT64 -ip $start 
  $endaddr = IP-toINT64 -ip $end 
} 
 
 
for ($i = $startaddr; $i -le $endaddr; $i++) 
{ 
  INT64-toIP -int $i 
}

}

Function Get-FreeVIPBySQL ($dataSource,$database,$datacenter)
{
	$i=0
	[string]$IPList = @()
	[string]$IPrange="0"
	#$usedIPs = $GetF5.LocalLBVirtualAddress.get_list()
	$usedIPs = "157.58.197.128","157.58.197.129","157.58.197.131","157.58.197.150","157.58.197.151"
	$freeIPs= @()
	#$dataSource = "CY1STPPSRV02"
	#$database = "Orchestrator_Logging"
	#$datacenter = "TK1"
	$connectionString = “Server=$dataSource;Database=$database;Integrated Security = True”
	$connection = New-Object System.Data.SqlClient.SqlConnection
	$connection.ConnectionString = $connectionString
	$connection.Open()
	$query = "SELECT Internet_VIPRange FROM VIP_SNAT where DATACENTER = '$datacenter' AND LTM_TYPE = 'PRIMARY'"
	$command = $connection.CreateCommand()
	$command.CommandText = $query
	$result = $command.ExecuteReader()
	$table = new-object “System.Data.DataTable”
	$table.Load($result)
	$table.Rows | ForEach-Object {$IPrange=$_.Internet_VIPRange}
	$ipPart=$IPrange.Split("/")
	$IPList=Get-IPrange -ip $ipPart[0] -cidr $ipPart[1]
	$IPs=$IPList.Split(" ")
	foreach ($ip in $IPs)
	{
		if(!($usedIPs -contains $ip))
		{
			$freeIPs += $Ip
		}
	}
	$usedIPs= $usedIPs | sort {"{0:d3}.{1:d3}.{2:d3}.{3:d3}" -f @([int[]]$_.split('.'))} 
	$freeIPs=$freeIPs |  sort {"{0:d3}.{1:d3}.{2:d3}.{3:d3}" -f @([int[]]$_.split('.'))} 
	$smallestUsedIp = $usedIPs[0]
	$smallestFreeIP=0
	$currentFreeIP=0
	for ($i=($freeIPs.Count-1 );$i -gt 14;$i--)
	{
		if($freeIPs[$i] -lt $smallestUsedIp)
		{
		   $ConStatus = Test-Connection -ComputerName $freeIPs[$i] -Count 1 -ea 0
		   if($ConStatus)
		   {
				continue 
		   }
		   else
		   {
				$smallestFreeIP=$freeIPs[$i]
				break
		   }
		}
		else
		{
			$ConStatus = Test-Connection -ComputerName $freeIPs[$i] -Count 1 -ea 0
			if($ConStatus)
			{
				continue 
			}
			else
			{
				$currentFreeIP=$freeIPs[$i]
			}   
		}
	}
	if ($smallestFreeIP -eq 0 -and $currentFreeIP -ne 0)
	{
		return $currentFreeIP
	}
	else
	{
		return $smallestFreeIP
	}
}

Function Get-FreeSNATIPBySQL ($dataSource,$database,$datacenter)
{
	$i=0
	[string]$IPList = @()
	[string]$IPrange="0"
	#$usedIPs = $GetF5.LocalLBVirtualAddress.get_list()
	$usedIPs = "157.58.197.128","157.58.197.129","157.58.197.131","157.58.197.150","157.58.197.151"
	$freeIPs= @()
	#$dataSource = "CY1STPPSRV02"
	#$database = "Orchestrator_Logging"
	#$datacenter = "TK1"
	$connectionString = “Server=$dataSource;Database=$database;Integrated Security = True”
	$connection = New-Object System.Data.SqlClient.SqlConnection
	$connection.ConnectionString = $connectionString
	$connection.Open()
	$query = "SELECT SNATRange FROM VIP_SNAT where DATACENTER = '$datacenter' AND LTM_TYPE = 'PRIMARY'"
	$command = $connection.CreateCommand()
	$command.CommandText = $query
	$result = $command.ExecuteReader()
	$table = new-object “System.Data.DataTable”
	$table.Load($result)
	$table.Rows | ForEach-Object {$IPrange=$_.SNATRange}
	$ipPart=$IPrange.Split("/")
	$IPList=Get-IPrange -ip $ipPart[0] -cidr $ipPart[1]
	$IPs=$IPList.Split(" ")
	foreach ($ip in $IPs)
	{
		if(!($usedIPs -contains $ip))
		{
			$freeIPs += $Ip
		}
	}
	$usedIPs= $usedIPs | sort {"{0:d3}.{1:d3}.{2:d3}.{3:d3}" -f @([int[]]$_.split('.'))} 
	$freeIPs=$freeIPs |  sort {"{0:d3}.{1:d3}.{2:d3}.{3:d3}" -f @([int[]]$_.split('.'))} 
	$smallestUsedIp = $usedIPs[0]
	$smallestFreeIP=0
	$currentFreeIP=0
	for ($i=($freeIPs.Count-1 );$i -gt 14;$i--)
	{
		if($freeIPs[$i] -lt $smallestUsedIp)
		{
		   $ConStatus = Test-Connection -ComputerName $freeIPs[$i] -Count 1 -ea 0
		   if($ConStatus)
		   {
				continue 
		   }
		   else
		   {
				$smallestFreeIP=$freeIPs[$i]
				break
		   }
		}
		else
		{
			$ConStatus = Test-Connection -ComputerName $freeIPs[$i] -Count 1 -ea 0
			if($ConStatus)
			{
				continue 
			}
			else
			{
				$currentFreeIP=$freeIPs[$i]
			}   
		}
	}
	if ($smallestFreeIP -eq 0 -and $currentFreeIP -ne 0)
	{
		return $currentFreeIP
	}
	else
	{
		return $smallestFreeIP
	}
}

Function Get-FreeVIPByExcel ($strFilePath,$strFileName,$strSheetName,$dataCenter)
{
	$i=0
	[string]$IPList = @()
	[string]$IPrange="0"
	#$usedIPs = $GetF5.LocalLBVirtualAddress.get_list()
	$usedIPs = "157.58.197.128","157.58.197.129","157.58.197.131","157.58.197.150","157.58.197.151"
	$freeIPs= @()
	$strFileName = $strFilePath + "\" + $strFileName
	#$strSheetName = 'LTM$'
	$strProvider = "Provider=Microsoft.ACE.OLEDB.12.0"
	$strDataSource = "Data Source = $strFileName"
	$strExtend = "Extended Properties=Excel 8.0"
	$strQuery = "Select * from [$strSheetName]"
	$objConn = New-Object System.Data.OleDb.OleDbConnection("$strProvider;$strDataSource;$strExtend")
	$sqlCommand = New-Object System.Data.OleDb.OleDbCommand($strQuery)
	$sqlCommand.Connection = $objConn
	$objConn.open()
	$DataReader = $sqlCommand.ExecuteReader()
	While($DataReader.read())
	{
		if ($DataReader[1].Tostring() -eq $dataCenter -and $DataReader[2].Tostring() -eq "PRIMARY")
		{
			$IPrange=$DataReader[9].Tostring()
		}

	}  
	$dataReader.close()
	$objConn.close()
	$ipPart=$IPrange.Split("/")
	$IPList=Get-IPrange -ip $ipPart[0] -cidr $ipPart[1]
	$IPs=$IPList.Split(" ")
	foreach ($ip in $IPs)
	{
		if(!($usedIPs -contains $ip))
		{
			$freeIPs += $Ip
		}
	}
	$usedIPs= $usedIPs | sort {"{0:d3}.{1:d3}.{2:d3}.{3:d3}" -f @([int[]]$_.split('.'))} 
	$freeIPs=$freeIPs |  sort {"{0:d3}.{1:d3}.{2:d3}.{3:d3}" -f @([int[]]$_.split('.'))} 
	$usedIPs
	$freeIPs
	$smallestUsedIp = $usedIPs[0]
	$smallestFreeIP=0
	$currentFreeIP=0
	for ($i=($freeIPs.Count-1 );$i -gt 14;$i--)
	{
		if($freeIPs[$i] -lt $smallestUsedIp)
		{
		   $ConStatus = Test-Connection -ComputerName $freeIPs[$i] -Count 1 -ea 0
		   if($ConStatus)
		   {
				continue 
		   }
		   else
		   {
				$smallestFreeIP=$freeIPs[$i]
				break
		   }
		}
		else
		{
			$ConStatus = Test-Connection -ComputerName $freeIPs[$i] -Count 1 -ea 0
			if($ConStatus)
			{
				continue 
			}
			else
			{
				$currentFreeIP=$freeIPs[$i]
			}   
		}
	}
	if ($smallestFreeIP -eq 0 -and $currentFreeIP -ne 0)
	{
		return $currentFreeIP
	}
	else
	{
		return $smallestFreeIP
	}
}


Function Get-FreeSNATIPByExcel ($strFilePath,$strFileName,$strSheetName,$dataCenter)
{
	$i=0
	[string]$IPList = @()
	[string]$IPrange="0"
	#$usedIPs = $GetF5.LocalLBVirtualAddress.get_list()
	$usedIPs = "157.58.197.128","157.58.197.129","157.58.197.131","157.58.197.150","157.58.197.151"
	$freeIPs= @()
	$strFileName = $strFilePath + "\" + $strFileName
	#$strSheetName = 'LTM$'
	$strProvider = "Provider=Microsoft.ACE.OLEDB.12.0"
	$strDataSource = "Data Source = $strFileName"
	$strExtend = "Extended Properties=Excel 8.0"
	$strQuery = "Select * from [$strSheetName]"
	$objConn = New-Object System.Data.OleDb.OleDbConnection("$strProvider;$strDataSource;$strExtend")
	$sqlCommand = New-Object System.Data.OleDb.OleDbCommand($strQuery)
	$sqlCommand.Connection = $objConn
	$objConn.open()
	$DataReader = $sqlCommand.ExecuteReader()
	While($DataReader.read())
	{
		if ($DataReader[1].Tostring() -eq $dataCenter -and $DataReader[2].Tostring() -eq "PRIMARY")
		{
			$IPrange=$DataReader[11].Tostring()
		}

	}  
	$dataReader.close()
	$objConn.close()
	$ipPart=$IPrange.Split("/")
	$ipPart[0]
	$ipPart[1]
	$IPList=Get-IPrange -ip $ipPart[0] -cidr $ipPart[1]
	$IPs=$IPList.Split(" ")
	foreach ($ip in $IPs)
	{
		if(!($usedIPs -contains $ip))
		{
			$freeIPs += $Ip
		}
	}
	$usedIPs= $usedIPs | sort {"{0:d3}.{1:d3}.{2:d3}.{3:d3}" -f @([int[]]$_.split('.'))} 
	$freeIPs=$freeIPs |  sort {"{0:d3}.{1:d3}.{2:d3}.{3:d3}" -f @([int[]]$_.split('.'))} 
	$usedIPs
	$freeIPs
	$smallestUsedIp = $usedIPs[0]
	$smallestFreeIP=0
	$currentFreeIP=0
	for ($i=($freeIPs.Count-1 );$i -gt 14;$i--)
	{
		if($freeIPs[$i] -lt $smallestUsedIp)
		{
		   $ConStatus = Test-Connection -ComputerName $freeIPs[$i] -Count 1 -ea 0
		   if($ConStatus)
		   {
				continue 
		   }
		   else
		   {
				$smallestFreeIP=$freeIPs[$i]
				break
		   }
		}
		else
		{
			$ConStatus = Test-Connection -ComputerName $freeIPs[$i] -Count 1 -ea 0
			if($ConStatus)
			{
				continue 
			}
			else
			{
				$currentFreeIP=$freeIPs[$i]
			}   
		}
	}
	if ($smallestFreeIP -eq 0 -and $currentFreeIP -ne 0)
	{
		return $currentFreeIP
	}
	else
	{
		return $smallestFreeIP
	}
}

########### Exporting all functions as power shell cmdlet ####################

Export-ModuleMember -Function * -Alias *

####################### End of the Script ##################################