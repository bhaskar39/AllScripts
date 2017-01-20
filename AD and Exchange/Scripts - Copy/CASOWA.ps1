#===================================================================
# Client Access Server - OWA Virtual Directory
#===================================================================
#write-Output "..Client Access Server - OWA Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$OWAVDS = Get-ClientAccessServer | Get-OWAVirtualDirectory 
$ClassHeaderOWAVD = "heading1"
foreach ($OWAVD in $OWAVDS){
		$OVDSrv = $OWAVD.Server
		$OVDName = $OWAVD.name
		$OVDE2K3 = $OWAVD.Exchange2003URL
		$OVDFailb = $OWAVD.FailbackURL
		$OVDInt = $OWAVD.InternalUrl
		$OVDExt = $OWAVD.ExternalUrl
		
    $DetailOWAVD+=  "					<tr>"
    $DetailOWAVD+=  "					</b><th width='10%'>Server Name : <font color='#0000FF'>$($OVDSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($OVDName)</font><th width='10%'>Exchange2003URL : <font color='#0000FF'>$($OVDE2K3)</font></td></th>"
    $DetailOWAVD+=  "					</tr>"
    $DetailOWAVD+=  "					<tr>"
    $DetailOWAVD+=  "					</b><th width='10%'>FailbackURL : <font color='#0000FF'>$($OVDFailb)</font><th width='10%'>InternalUrl : <font color='#0000FF'>$($OVDInt)</font><th width='10%'>ExternalUrl : <font color='#0000FF'>$($OVDExt)</font></td></th>"
    $DetailOWAVD+=  "					</tr>"
    $DetailOWAVD+=  "					<tr>"
	$DetailOWAVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailOWAVD+=  "					</tr>"		
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderOWAVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - OWA Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
						
 		   		</tr>
                    $($DetailOWAVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report