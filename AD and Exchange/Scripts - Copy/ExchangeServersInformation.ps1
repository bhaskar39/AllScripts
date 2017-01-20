#===================================================================
# Exchange Servers Information
#===================================================================
#write-Output "..Exchange Servers Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$E2K = Get-ExchangeServer
$E2KEdge = Get-ExchangeServer | Where-Object{$_.ServerRole -ne "Edge"}
$E2K3 = Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 6.*"} | Measure-Object
$E2K7 = Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 8.*"} | Measure-Object
$E2K10 = Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 14.*"} | Measure-Object
$ClassHeadersrvVersion = "heading1"
		$E2KNB = $E2K.count
		$E2K7NB = $E2K7.count
		$E2K10NB = $E2K10.count
		$E2K3NB = $E2K3.count
		
		$E2K7MCH = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -eq "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7CH = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7M = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -eq "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7H = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7C = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7E = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -eq "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7UM = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -eq "UnifiedMessaging"} | Measure-Object).count		
		
		$E2K10MCH = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -eq "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10CH = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10M = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -eq "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10H = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10C = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10E = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -eq "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10UM = (Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -eq "UnifiedMessaging"} | Measure-Object).count		
		
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>================================</b></font><tr><tr>"	
    $DetailsrvVersion+=  "				<td width='20%'><b>Total Exchange Servers : </b><font color='#FF0000'>$($E2KNB)</font></td><tr><tr>"
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>================================</b></font><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>- Exchange 2003 Number(s) : </b><font color='#FF0000'>$($E2K3NB) </b></font></th>"
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>================================</b></font><tr>"						
	$DetailsrvVersion+=  "				<th width='10%'><b>- Exchange 2007 Number(s) : </b><font color='#FF0000'>$($E2K7NB)</b></font></th><tr>"
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>--------------------------------</b></font><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Mailbox & ClientAccess & HubTransport number(s) : </b><font color='#0000FF'>$($E2K7MCH) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- ClientAccess & HubTransport number(s) : </b><font color='#0000FF'>$($E2K7CH) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Mailbox number(s) : </b><font color='#0000FF'>$($E2K7M) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- HubTransport number(s) : </b><font color='#0000FF'>$($E2K7H) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- ClientAccess number(s) : </b><font color='#0000FF'>$($E2K7C) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Edge number(s) : </b><font color='#0000FF'>$($E2K7E) </font>(The Edge servers information collects are not included in this report)</b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Unified Messaging number(s) : </b><font color='#0000FF'>$($E2K7UM) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>================================</b></font><tr>"						
	$DetailsrvVersion+=  "				<th width='10%'><b>- Exchange 2010 Number(s) : </b><font color='#FF0000'>$($E2K10NB)</b></font></th><tr>"
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>--------------------------------</b></font><tr>"		
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Mailbox & ClientAccess & HubTransport number(s) : </b><font color='#0000FF'>$($E2K10MCH) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- ClientAccess & HubTransport number(s) : </b><font color='#0000FF'>$($E2K10CH) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Mailbox number(s) : </b><font color='#0000FF'>$($E2K10M) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- HubTransport number(s) : </b><font color='#0000FF'>$($E2K10H) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- ClientAccess number(s) : </b><font color='#0000FF'>$($E2K10C) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Edge number(s) : </b><font color='#0000FF'>$($E2K10E) </font>(The Edge servers information collects are not included in this report)</b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Unified Messaging number(s) : </b><font color='#0000FF'>$($E2K10UM) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>================================</b></font><tr>"	
    $DetailsrvVersion+=  "				</tr>"
	
$ClassHeaderEXCOSW = "heading1"
foreach($EXCOS in $E2KEdge){
    $query = "Select * from Win32_pingstatus where address = '$EXCOS'"
    $result = Get-WmiObject -query $query
    if ($result.protocoladdress){ 
	$XCOS = (Get-WmiObject -Class Win32_OperatingSystem -Namespace root/cimv2 -computername $EXCOS)
	$XCOSN = $XCOS.CSName
    $XCOSOS = $XCOS.Caption
	$XCOSSP = $XCOS.CSDVersion
	$XCOSArch = $XCOS.OSArchitecture
    $XCOSLB = $XCOS.ConvertToDateTime($XCOS.LastBootUpTime)
    $DetailEXCOSW+=  "					<tr>"
    $DetailEXCOSW+=  "						<td width='20%'><font color='#0000FF'><b>$($XCOSN)</b></font></td>"
    $DetailEXCOSW+=  "						<td width='50%'><font color='#0000FF'><b>$($XCOSOS)</b></font></td>"
    $DetailEXCOSW+=  "						<td width='10%'><font color='#0000FF'><b>$($XCOSSP)</b></font></td>"
    $DetailEXCOSW+=  "						<td width='10%'><font color='#0000FF'><b>$($XCOSArch)</b></font></td>"
    $DetailEXCOSW+=  "						<td width='10%'><font color='#0000FF'><b>$($XCOSLB)</b></font></td>"
    $DetailEXCOSW+=  "					</tr>"
    }
    else
    {
    $ClassHeaderEXCOSW = "heading10"
    $DetailEXCOSW+=  "					<tr>"
    $DetailEXCOSW+=  "						<td width='20%'><font color='#FF0000'><b>$($EXCOS)</b></font></td>"
    $DetailEXCOSW+=  "						<td width='20%'><font color='#FF0000'><b>SERVER CANNOT BE CONTACTED</b></font></td>"  
    $DetailEXCOSW+=  "						<td width='60%'><b></b></font></td>"      
    $DetailEXCOSW+=  "					</tr>"
    }
}
$ClassHeaderEXIPSW = "heading1"
foreach($EXCIP in $E2KEdge){
   $query = "Select * from Win32_pingstatus where address = '$EXCIP'"
   $result = Get-WmiObject -query $query
   if ($result.protocoladdress){ 
    $XCIPNIC = (Get-WmiObject Win32_NetworkAdapterConfiguration -computer $EXCIP | where-object {$_.IPEnabled -eq $true} )
    foreach ($XCIP in $XCIPNIC){
    $XCIPN = $EXCIP.Name
    $XCIPIP = $XCIP.IPAddress
	$XCIPDG = $XCIP.DefaultIPGateway
	$XCIPDesc = $XCIP.Description
    $XCIPSN = $XCIP.ServiceName
    $DetailEXIPSW+=  "					<tr>"
    $DetailEXIPSW+=  "						<td width='20%'><font color='#0000FF'><b>$($XCIPN)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='20%'><font color='#0000FF'><b>$($XCIPIP)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='10%'><font color='#0000FF'><b>$($XCIPDG)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='30%'><font color='#0000FF'><b>$($XCIPDesc)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='10%'><font color='#0000FF'><b>$($XCIPSN)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='10%'></font></td>"    
    $DetailEXIPSW+=  "					</tr>"
    }
    }
    else
    {
    $ClassHeaderEXIPSW = "heading10"
    $DetailEXIPSW+=  "					<tr>"
    $DetailEXIPSW+=  "						<td width='20%'><font color='#FF0000'><b>$($EXCIP)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='20%'><font color='#FF0000'><b>SERVER CANNOT BE CONTACTED</b></font></td>"  
    $DetailEXIPSW+=  "						<td width='60%'><b></b></font></td>"      
    $DetailEXIPSW+=  "					</tr>"
    }
    }
	
$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderEXCOSW)'>
            <SPAN class=sectionTitle tabIndex=0>Exchange Servers Information</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						
	  				</tr>
                    $($DetailsrvVersion)
                </table>
                <table>
	  				<tr>
	  						
	  				</tr>
                    $($Detailmbxnumb)
                </table>
                <table>
	  			<tr>
	  				<br><th width='20%'><b>Name</b></font></th>                    
	  				<th width='50%'><b>Operating System</b></font></th>
					<th width='10%'><b>Service Pack</b></font></th>
					<th width='10%'><b>OS Version</b></font></th> 
					<th width='10%'><b>LastBootUpTime</b></font></th>  
  	  				</tr>
                    $($DetailEXCOSW)
                </table>
                <table>
	  			<tr>
	  				<br><th width='20%'><b>Server Name</b></font></th>                    
	  				<th width='20%'><b>IPAddress</b></font></th>
					<th width='10%'><b>DefaultIPGateway</b></font></th>
					<th width='30%'><b>Description</b></font></th> 
					<th width='10%'><b>ServiceName</b></font></th>  
 					<th width='10%'><b></b></font></th>                                                        
  	  				</tr>
                    $($DetailEXIPSW)
                </table>                             
            </div>
        </div>
        <div class='filler'></div>
    </div>  
"@
Return $Report