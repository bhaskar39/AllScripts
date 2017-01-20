$vipip=$args[0]
$VSName=$args[1]
$VSPort=$args[2]
$wildmask="255.255.255.255"
$defPool=$VSName+"_"+$VSPort+"_"+"pl"
$user=$args[3]
$password=$args[4]
$f5box=$args[5]

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

Function New-VIP()
{
	param(
			[Parameter (Mandatory=$true)] [string]$vip_Addr,
			[Parameter (Mandatory=$true)] [string]$VS_Name,
			[Parameter (Mandatory=$true)] [string]$VS_Port,
			[Parameter (Mandatory=$true)] [string]$wildmask,
			[Parameter (Mandatory=$true)] [string]$def_Pool_name,
            [Parameter (Mandatory=$true)] [string]$username,
            [Parameter (Mandatory=$true)] [string]$password,
            [Parameter (Mandatory=$true)] [string]$F5boxhostname		
		)	
			
	#New-Log -Dir $logPath $logFile
    #Add-PSSnapin icontrolsnapin
    try
    {
            Add-PSSnapin iControlSnapIn
		    $GetF5=Get-F5Connection -username $username -password $password -F5boxhostname $F5boxhostname   
            $vipDefs = new-object "iControl.CommonVirtualServerDefinition[]" 1
            if(($vip_Addr) -and ($VS_Name) -and ($VS_Port) -and ($def_Pool_name))
                {
                    $vipDefs = new-object "iControl.CommonVirtualServerDefinition"
                    $vipDefs.address = $vip_Addr;
                    $vipDefs.name = $VS_Name
                    $vipDefs.port = $VS_Port;
                    # Accepts input for protocol and values mentioned above
                    $vipDefs.protocol = [iControl.CommonProtocolType]::PROTOCOL_TCP;
                    #$resources = new-object "iControl.LocalLBVirtualServerVirtualServerResource"
                    $resources = new-object "iControl.LocalLBVirtualServerVirtualServerResource"
                    $resources.default_pool_name = $def_Pool_name
                    $resources.type = [iControl.LocalLBVirtualServerVirtualServerType]::RESOURCE_TYPE_FAST_L4
                    $profiles = new-object "iControl.LocalLBVirtualServerVirtualServerProfile"
                    $profiles.profile_context = "PROFILE_CONTEXT_TYPE_ALL"
                    $profiles.profile_name = "fastL4"
                }                                                            
                                  
            if(($vipDefs) -and ($wildmask) -and ($resources) -and ($profiles))
                {
                    $GetF5.LocalLBVirtualServer.create($vipDefs, $wildmask, $resources, $profiles)
                    if($?)
                    {          
                        #write-log "VIP Created", 0
                        $GetF5.LocalLBVirtualServer.set_default_pool_name($VS_Name,$def_Pool_name)
                        $snat = $VS_Name+"_"+"sn"+"_pl"
                        $GetF5.LocalLBVirtualServer.set_snat_pool($VS_Name,$snat)
                        return 0
                    }              
                    else
                    {
                        #write-log "VIP could not be created", 2
                        return 10
                    }
                }
	}			
    catch [System.Exception]
    {
        $outputDesc = $_.Exception.Message
        #write-log "$outputDesc", 2
        return 10                         
    }

}
				
$VIP_status = New-VIP -vip_Addr $vipip -VS_Name $VSName -VS_Port $VSPort -wildmask $wildmask -def_Pool_name $defPool -username $user -password $password -F5boxhostname $f5box
#$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "4 - Check VIP Creation status" "$VIP_status" "$Using:VMName" "redmond\stpatcha" "" ""
$VIP_status
