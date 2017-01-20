#Initialise:
Add-PSSnapin iControlSnapIn
$uname = "admin"
$password = "Admin098"
$password = ConvertTo-SecureString -String $password -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $uname,$password
Initialize-F5.iControl -HostName 52.24.197.85 -PSCredentials $cred

#Get-f5.iControl
$GetF5 = Get-F5.iControl 
#Snat pool:
$name = "demo_sn_pl"
$ipaddress = "10.10.120.3"
$ipaddress1 = "10.10.120.4"
#$obj = New-Object -TypeName iControl.LocalLBSNATPool
#new snat pool
$GetF5.LocalLBSNATPool.create($name,$ipaddress)
$obj = New-Object -TypeName iControl.LocalLBSNATPool
$obj.cre
#adding second member
$GetF5.LocalLBSNATPool.add_member($name,$ipaddress1)
#VIP pool:
$VIPPoolName = "demo_80_pl"
$health = "tcp"
$loadbalaceMethod = "LB_METHOD_ROUND_ROBIN"
$member = New-Object -TypeName iControl.CommonIPPortDefinition
$member.address = "10.10.0.5"
$member.port = 80
$member1 = New-Object -TypeName iControl.CommonIPPortDefinition
$member1.address = "10.10.0.6"
$member1.port = 801

$GetF5.LocalLBPool.create($VIPPoolName,$loadbalaceMethod,$member)
$GetF5.LocalLBPool.add_member($VIPPoolName,$member1)

#Add Health Monitor rule
$monitor_association = New-Object -TypeName iControl.LocalLBPoolMonitorAssociation
$monitor_association.pool_name = $VIPPoolName
$monitor_association.monitor_rule = New-Object -TypeName iControl.LocalLBMonitorRule
$monitor_association.monitor_rule.type = "MONITOR_RULE_TYPE_SINGLE"
$monitor_association.monitor_rule.quorum = 0
$monitor_association.monitor_rule.monitor_templates = (, 'udp')
  
$GetF5.LocalLBPool.set_monitor_association( (, $monitor_association) )
#VIP creation:

$vipdef = New-Object -TypeName iControl.CommonVirtualServerDefinition
$vipdef.name = "demo_80_vs"
$vipdef.address = '10.10.200.10'
$vipdef.port = 80
$vipdef.protocol = [iControl.CommonProtocolType]::PROTOCOL_ANY
#$VIPtype = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerType
#$vipconfig = New-Object -TypeName iControl.comm
$wildmask = @("0.0.0.0")
$resource = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerResource
$resource.default_pool_name = "demo_80_pl"
$resource.type = [icontrol.localLBVirtualServerVirtualServerType]::RESOURCE_TYPE_IP_FORWARDING

$profiles = new-object "iControl.LocalLBVirtualServerVirtualServerProfile[][]" 1
$GetF5.LocalLBVirtualServer.create($vipDefs, $wildmask, $resources, $null)

#Persistence creation: