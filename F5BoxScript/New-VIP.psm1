<#

.SYNOPSIS
#Aim: Creates Virtual IP -------------------------------#
#Author: Vidya Hirlekar-------------------------------------#
#Date of development: 18-June-2015----------------------------#

.DESCRIPTION

If DNS A record does not exist then create it.

.I/P - VIP Address, VS Name, VS Port, Wildmask, Pool Name, Resource Type.
	    $vip_Addr = "10.10.10.10";
		$VS_Name = "demo_80_vs";
		$VS_Port = "0";
		$wildmask = @("255.255.255.255");
		$def_Pool_name = "demo_80_pl";
		$resource_Type = "RESOURCE_TYPE_IP_FORWARDING"

.O/P - 0 on success and VIP is created successfully
	  10 if VIP exists
	  2 on error in creating the VIP.

.EXAMPLE Create_VIP $vip_Addr $VS_Name $VS_Port $wildmask $def_Pool_name $resource_Type

.PARAMETERS $vip_Addr $VS_Name $VS_Port $wildmask $def_Pool_name $resource_Type
	  
#>


Function New-VIP()
{
	param(
			[Parameter (Mandatory=$true)] [string]$vip_Addr,
			[Parameter (Mandatory=$true)] [string]$VS_Name,
			[Parameter (Mandatory=$true)] [string]$VS_Port,
			[Parameter (Mandatory=$true)] [string]$wildmask,
			[Parameter (Mandatory=$true)] [string]$def_Pool_name,
			[Parameter (Mandatory=$true)] [string]$resource_Type,			
			[Parameter (Mandatory=$true)] [string]$Protocol_type,
			[Parameter (Mandatory=$true)] [string]$Prof_Context,
			[Parameter (Mandatory=$true)] [string]$Prof_Name		
		)	
			
	New-Log -Dir $logPath $logFile
    Add-PSSnapin icontrolsnapin

    try
    {
        $VIP_Exists = Test-Connection $vip_Addr -Quiet
        if(!$VIP_Exists)
        {
            $vipDefs = new-object "iControl.CommonVirtualServerDefinition[]" 1
            if(($vipDefs) -and ($vip_Addr) -and ($VS_Name) -and ($VS_Port) -and ($resources) -and ($def_Pool_name) -and ($resource_Type) -and ($Prof_Context) -and ($Prof_Name))
                {
                    $vipDefs = new-object "iControl.CommonVirtualServerDefinition"
                    $vipDefs.address = $vip_Addr;
                    $vipDefs.name = $VS_Name
                    $vipDefs.port = $VS_Port;
                    # Accepts input for protocol and values mentioned above
                    $vipDefs.protocol = [iControl.CommonProtocolType]::$Protocol_type;
                    $resources = new-object "iControl.LocalLBVirtualServerVirtualServerResource"
                    $resources = new-object "iControl.LocalLBVirtualServerVirtualServerResource"
                    $resources.default_pool_name = $def_Pool_name
                    $resources.type = [iControl.LocalLBVirtualServerVirtualServerType]::$resource_Type
                    $profiles = new-object "iControl.LocalLBVirtualServerVirtualServerProfile"
                    $profiles.profile_context = $Prof_Context
                    $profiles.profile_name = $Prof_Name
                }                                                            
                                  
            if(($vipDefs) -and ($wildmask) -and($resources) -and($profiles))
                {
                    $GetF5.LocalLBVirtualServer.create($vipDefs, $wildmask, $resources, $profiles)
                    if($?)
                    {              
                        write-log "VIP Created", 0
                        return 0
                    }              
                    else
                    {
                        write-log "VIP could not be created", 2
                        return 10
                    }
                }
		}
	}			
    catch [System.Exception]
    {
        $outputDesc = $_.Exception.Message
        write-log "$outputDesc", 2
        return 10                         
    }

}

#Sample Input
#New-VIP -vip_Addr 14.99.159.12 -VS_Name VSDEM4 -wildmask 255.255.255.255 -def_Pool_name vip_pool_test -resource_Type RESOURCE_TYPE_UNKNOWN -Protocol_type PROTOCOL_ANY -VS_Port 80 -Prof_Context PROFILE_CONTEXT_TYPE_ALL -Prof_Name http
