$vippersistence = New-object -TypeName iControl.LocalLBVirtualServerVirtualServerPersistence;
$vippersistence.profile_name = "dest_addr"
$vippersistence.default_profile = "dest_addr"
$GetF5.LocalLBVirtualServer.add_persistence_profile("demo_80_vs",$vippersistence)

$GetF5.LocalLBVirtualServer.get_persistence_profile("demo_80_vs")
$GetF5.LocalLBVirtualServer.remove_persistence_profile("demo_80_vs",$vippersistence)

#Add-Profile:
$vipprofilehttp = New-Object "iControl.LocalLBVirtualServerVirtualServerProfile"
$vipprofilehttp.profile_context = "PROFILE_CONTEXT_TYPE_ALL";
$vipprofilehttp.profile_name = 'http';
$GetF5.LocalLBVirtualServer.Add_profile("demo_80_vs",(,$vipprofilehttp))
$GetF5.LocalLBVirtualServer.remove_profile("demo_80_vs",(,$vipprofilehttp))

$mode = New-Object -TypeName iControl.LocalLBPersistenceMode;
$mode ="PERSISTENCE_MODE_COOKIE";
$modes=(,$mode)

$GetF5.LocalLBProfilePersistence.create('http_demo',$modes); 
$method1 = New-Object -TypeName iControl.LocalLBProfileCookiePersistenceMethod; $method1.value =1;#"COOKIE_PERSISTENCE_METHOD_INSERT"; $methods=(,$method1); (Get-F5.iControl).LocalLBProfilePersistence.set_cookie_persistence_method($profiles,$methods);

$cookieName = New-Object -TypeName iControl.LocalLBProfileString;
$cookieName.value = "cookie-Xy";
$cookieName.default_flag = "false";
$cookieNames = (, $cookieName);
$GetF5.LocalLBProfilePersistence.set_cookie_name("http_demo",$cookieNames);

$time = New-Object -TypeName iControl.LocalLBProfileULong;
$time.value=600;
$time.default_flag = "false";
$times=(,$time);    
$GetF5.LocalLBProfilePersistence.set_cookie_expiration("http_demo",$times);
