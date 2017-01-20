Add-PSSnapin iControlSnapIn

$obj = New-Object -TypeName iControl.GlobalLBMonitorCommonAttributes
$MonTemp = New-Object -TypeName iControl.LocalLBMonitorMonitorTemplate
$MonTemp.template_name = "http_demo_temp2"
$MonTemp.template_type = 'TTYPE_HTTP'
$MonAttr = New-Object -TypeName iControl.LocalLBMonitorCommonAttributes
$MonAttr.interval= 10
$MonAttr.timeout = 15
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