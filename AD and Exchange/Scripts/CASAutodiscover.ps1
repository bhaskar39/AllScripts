#===================================================================
# Client Access Server - Autodiscover Virtual Directory
#===================================================================
#write-Output "..Client Access Server - Autodiscover Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$AUTOVDS = Get-ClientAccessServer | Get-AutodiscoverVirtualDirectory
$ClassHeaderAUTOVD = "heading1"
foreach ($AUTOVD in $AUTOVDS){
		$ATDSrv = $AUTOVD.server
		$ATDName = $AUTOVD.name
		$ATDIURL = $AUTOVD.InternalURL
		$ATDIAM = $AUTOVD.InternalAuthenticationMethods		
		$ATDEURL = $AUTOVD.ExternalURL
		$ATDEAM = $AUTOVD.ExternalAuthenticationMethods			
		
    $DetailAUTOVD+=  "					<tr>"
    $DetailAUTOVD+=  "					<th width='10%'><b>Server Name : <font color='#0000FF'>$($ATDSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($ATDName)</font><th width='10%'>InternalURL : <font color='#0000FF'>$($ATDIURL)</b></font></td></th>"
    $DetailAUTOVD+=  "					</tr>"
    $DetailAUTOVD+=  "					<tr>"
    $DetailAUTOVD+=  "				    <th width='10%'><b>InternalAuthenticationMethods : <font color='#0000FF'>$($ATDIAM)</font><th width='10%'>ExternalURL : <font color='#0000FF'>$($ATDEURL)</font><th width='10%'>ExternalAuthenticationMethods : <font color='#0000FF'>$($ATDEAM)</b></font></td></th>"
    $DetailAUTOVD+=  "					</tr>"
    $DetailAUTOVD+=  "					<tr>"
	$DetailAUTOVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailAUTOVD+=  "					</tr>"
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderAUTOVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - Autodiscover Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
							
 		   		</tr>
                    $($DetailAUTOVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report