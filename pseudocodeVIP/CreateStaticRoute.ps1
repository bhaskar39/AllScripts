#$Dom = New-Object -TypeName iControl.NetworkingRouteTableRouteDefinition
#$Dom.
#$Def1 = New-Object -TypeName iControl.NetworkingRouteTableRouteDefinition
#$Def1.destination = "0.0.0.0"
#$Def1.netmask = "255.255.255.255"

$Attribute = New-Object -TypeName iControl.NetworkingRouteTableRouteAttribute
$Attribute.gateway = $null
$Attribute.pool_name = "demo_80_pl"
$Attribute.vlan_name = $null
#$GetF5.NetworkingRouteTable.add_static_route($Def1,$Attribute)
#$Attribute = New-Object -TypeName iControl.NetworkingRouteTableV2RouteAttribute
#$Attribute.

#$Attribute.gateway = $null
#$Attribute.pool_name = "demo_80_pl"
#$Attribute.vlan_name = $null
#$res = New-Object -TypeName iControl.NetworkingRouteTable
#$GetF5.NetworkingRouteTable.add_static_route($Def1,$Attribute)

$Des = New-Object -TypeName iControl.NetworkingRouteTableV2RouteDestination
$Des.address = "0.0.0.0"
$Des.netmask = "255.255.255.255"

$GetF5.NetworkingRouteTableV2.create_static_route("demo_route",$Des,$Attribute)