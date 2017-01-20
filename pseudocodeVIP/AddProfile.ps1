$profName = "http_demo"
$obj = New-Object -TypeName iControl.LocalLBVirtualServerVirtualServerPersistence
$obj.profile_name = $profName
$obj.default_profile = $true
$GetF5.LocalLBVirtualServer.add_persistence_profile("demo_80_vs",$obj)

#Add HTTP
$vipprofilehttp = New-Object "iControl.LocalLBVirtualServerVirtualServerProfile"
$vipprofilehttp.profile_context = "PROFILE_CONTEXT_TYPE_ALL";
$vipprofilehttp.profile_name = 'http';
$GetF5.LocalLBVirtualServer.Add_profile('demo_80_vs',(,$vipprofilehttp))

$GetF5.LocalLBVirtualServer.set_default_pool_name("demo_80_vs","demo_80_pl")