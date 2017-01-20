$vipname=$args[0]
$port=$args[1]
$ip=$args[2]
$lb=$args[3]
$monitor=$args[4]
$user=$args[5]
$passwrd = $args[6]
$f5=$args[7]
$ports=@()
$ports+=$port
$ips = @()
$ip = $ip.Split(",")
foreach($i in $ip)
{
    $ips+=$i
}
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
            [String]$F5boxhostname)

	$names = @()
    $flag=0
	try
	{
		Add-PSSnapin iControlSnapIn
		$GetF5=Get-F5Connection -username $username -password $password -F5boxhostname $F5boxhostname
		#New-Log -Dir $LogFilePath $LogFileName
		if ($GetF5 -ne 10)
		{
            #write-log "Connected with F5 BOX" 0
		}
        else
        {
			#write-log "Unable to connect with the F5 box." 2
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
                    #write-log $msg 2
                    $flag=10 
				}
            }
            if ($flag -eq 10)
            {Return 10}
			for($i = 0;$i -lt $names.Length;$i++)
			{
                $msg="Creating VIP Pools names " + $names[$i]
                $msg
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
				#Write-Log "VIP Pool created successfully" 0
			}
		
		}
        else
        {
            for($i = 0;$i -lt $names.Length;$i++)
			{
                $msg="Creating VIP Pools names " + $names[$i]
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
				#Write-Log "VIP Pool created successfully" 0
			}
        }
	}
	catch
	{
			#Write-Log "Failed to create VIP POOL due to system exception + $_.exception" 2 
			Return 10	
	}
return 0
}

$status = Create-VIPPool -vipName $vipname -ports $ports -ips $ips -lbMethod $lb -monitoringEnabled $monitor -username $user -password $passwrd -F5boxhostname $f5
$status

