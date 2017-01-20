#===================================================================
# Client Access Server - OAB Virtual Directory
#===================================================================
#write-Output "..Client Access Server - OAB Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$OABVDS = Get-ClientAccessServer | Get-OABVirtualDirectory
$ClassHeaderOABVD = "heading1"
foreach ($OABVD in $OABVDS){
		$OBSrv = $OABVD.server
		$OBName = $OABVD.name
		$OBIURL = $OABVD.InternalURL
		$OBIAM = $OABVD.InternalAuthenticationMethods		
		$OBEURL = $OABVD.ExternalURL
		$OBEAM = $OABVD.ExternalAuthenticationMethods			
		
    $DetailOABVD+=  "					<tr>"
    $DetailOABVD+=  "					<th width='10%'><b>Server Name : <font color='#0000FF'>$($OBSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($OBName)</font><th width='10%'>InternalURL : <font color='#0000FF'>$($OBIURL)</b></font></td></th>"
    $DetailOABVD+=  "					</tr>"
    $DetailOABVD+=  "					<tr>"
    $DetailOABVD+=  "					<th width='10%'><b>InternalAuthenticationMethods : <font color='#0000FF'>$($OBIAM)</font><th width='10%'>ExternalURL : <font color='#0000FF'>$($OBEURL)</font><th width='10%'>ExternalAuthenticationMethods : <font color='#0000FF'>$($OBEAM)</b></font></td></th>"
    $DetailOABVD+=  "					</tr>"
    $DetailOABVD+=  "					<tr>"
	$DetailOABVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailOABVD+=  "					</tr>"	
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderOABVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - OAB Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
							
 		   		</tr>
                    $($DetailOABVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report