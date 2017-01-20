#===================================================================
# Client Access Server - ECP Virtual Directory
#===================================================================
#write-Output "..Client Access Server - ECP Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ECPVDS = Get-ClientAccessServer | Get-ECPVirtualDirectory
$ClassHeaderECPVD = "heading1"
foreach ($ECPVD in $ECPVDS){
		$EPSrv = $ECPVD.server
		$EPName = $ECPVD.name
		$EPIURL = $ECPVD.InternalURL
		$EPIAM = $ECPVD.InternalAuthenticationMethods		
		$EPEURL = $ECPVD.ExternalURL
		$EPEAM = $ECPVD.ExternalAuthenticationMethods			
		
    $DetailECPVD+=  "					<tr>"
    $DetailECPVD+=  "						</b><th width='10%'>Server Name : <font color='#0000FF'>$($EPSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($EPName)</font><th width='10%'>InternalURL : <font color='#0000FF'>$($EPIURL)</font></td></th>"
    $DetailECPVD+=  "					</tr>"
    $DetailECPVD+=  "					<tr>"
    $DetailECPVD+=  "						</b><th width='10%'>InternalAuthenticationMethods : <font color='#0000FF'>$($EPIAM)</font><th width='10%'>ExternalURL : <font color='#0000FF'>$($EPEURL)</font><th width='10%'>ExternalAuthenticationMethods : <font color='#0000FF'>$($EPEAM)</font></td></th>"
    $DetailECPVD+=  "					</tr>"
    $DetailECPVD+=  "					<tr>"
	$DetailECPVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailECPVD+=  "					</tr>"	
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderECPVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - ECP Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
							
 		   		</tr>
                    $($DetailECPVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report