$vipDefs = new-object "iControl.CommonVirtualServerDefinition[]" 1
$vipDefs[0] = new-object "iControl.CommonVirtualServerDefinition"
$vipDefs[0].address = "10.10.10.10";
$vipDefs[0].name = "demo_80_vs"
$vipDefs[0].port = 0;
$vipDefs[0].protocol = [iControl.CommonProtocolType]::PROTOCOL_ANY;
$wildmask = @("255.255.255.255")
$resources = new-object "iControl.LocalLBVirtualServerVirtualServerResource[]" 1
$resources[0] = new-object "iControl.LocalLBVirtualServerVirtualServerResource"
$resources[0].default_pool_name = "demo_80_pl"
$resources[0].type = [iControl.LocalLBVirtualServerVirtualServerType]::RESOURCE_TYPE_IP_FORWARDING
$profiles = new-object "iControl.LocalLBVirtualServerVirtualServerProfile"
$GetF5.LocalLBVirtualServer.create($vipDefs, $wildmask, $resources, $profiles)