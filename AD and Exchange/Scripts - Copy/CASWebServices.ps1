#===================================================================
# Client Access Server - WebServices Virtual Directory
#===================================================================
#write-Output "..Client Access Server - WebServices Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$WEBSVDS = Get-ClientAccessServer | Get-WebServicesVirtualDirectory
$ClassHeaderWEBSVD = "heading1"
foreach ($WEBSVD in $WEBSVDS){
		$WVDSrv = $WEBSVD.server
		$WVDName = $WEBSVD.name
		$WVDIURL = $WEBSVD.InternalURL
		$WVDIAM = $WEBSVD.InternalAuthenticationMethods		
		$WVDEURL = $WEBSVD.ExternalURL
		$WVDEAM = $WEBSVD.ExternalAuthenticationMethods		
		$WVDINLB = $WEBSVD.InternalNLBBypassURL
		
    $DetailWEBSVD+=  "					<tr>"
    $DetailWEBSVD+=  "					</b><th width='10%'>Server Name : <font color='#0000FF'>$($WVDSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($WVDName)</font><th width='10%'>InternalUrl : <font color='#0000FF'>$($WVDIURL)</font></td></th>"
    $DetailWEBSVD+=  "					</tr>"
    $DetailWEBSVD+=  "					<tr>"
    $DetailWEBSVD+=  "					</b><th width='10%'>InternalAuthenticationMethods : <font color='#0000FF'>$($WVDIAM)</font><th width='10%'>ExternalURL : <font color='#0000FF'>$($WVDEURL)</font><th width='10%'>ExternalAuthenticationMethods : <font color='#0000FF'>$($WVDEAM)</font></td></th>"
    $DetailWEBSVD+=  "					</tr>"	
    $DetailWEBSVD+=  "					<tr>"	
    $DetailWEBSVD+=  "					</b><th width='10%'>InternalNLBBypassURL : <font color='#0000FF'>$($WVDINLB)</font></td></th>"
    $DetailWEBSVD+=  "					</tr>"
	$DetailWEBSVD+=  "					<tr>"	
	$DetailWEBSVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"
	$DetailWEBSVD+=  "					</tr>"	
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderWEBSVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - WebServices Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>

 		   		</tr>
                    $($DetailWEBSVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report