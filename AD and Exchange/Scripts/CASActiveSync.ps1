#===================================================================
# Client Access Server - ActiveSync Virtual Directory
#===================================================================
#write-Output "..Client Access Server - ActiveSync Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderASyncVD = "heading1"
$CasSrv = Get-ClientAccessServer
Foreach ($ASyncVDS in $CasSrv){
$ASyncVDS = Get-ActiveSyncVirtualDirectory -server $ASyncVDS
foreach ($ASyncVD in $ASyncVDS){
		$ASSrv = $ASyncVD.server
		$ASName = $ASyncVD.name
		$ASIURL = $ASyncVD.InternalURL
		$ASIAM = $ASyncVD.InternalAuthenticationMethods		
		$ASEURL = $ASyncVD.ExternalURL
		$ASEAM = $ASyncVD.ExternalAuthenticationMethods			
		
    $DetailASyncVD+=  "					<tr>"
    $DetailASyncVD+=  "					<th width='10%'><b>Server Name : <font color='#0000FF'>$($ASSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($ASName)</font><th width='10%'>InternalURL : <font color='#0000FF'>$($ASIURL)</b></font></td></th>"
    $DetailASyncVD+=  "					</tr>"
    $DetailASyncVD+=  "					<tr>"
    $DetailASyncVD+=  "					<th width='10%'><b>InternalAuthenticationMethods : <font color='#0000FF'>$($ASIAM)</font><th width='10%'>ExternalURL : <font color='#0000FF'>$($ASEURL)</font><th width='10%'>ExternalAuthenticationMethods : <font color='#0000FF'>$($ASEAM)</b></font></td></th>"
    $DetailASyncVD+=  "					</tr>"
    $DetailASyncVD+=  "					<tr>"
	$DetailASyncVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailASyncVD+=  "					</tr>"	
	}
	}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderASyncVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - ActiveSync Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
						
 		   		</tr>
                $($DetailASyncVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report