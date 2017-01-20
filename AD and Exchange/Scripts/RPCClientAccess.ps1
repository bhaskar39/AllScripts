#===================================================================
# RPCClientAccess
#===================================================================
#Write-Output "..RPCClientAccess"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderRPC = "heading1"
$RPCall = Get-RPCClientAccess
Foreach($RPC in $RPCall)
 {
        $RPCSrv = $RPC.Server
		$RPCResp = $RPC.Responsibility
		$RPCMC = $RPC.MaximumConnections
		$RPCER = $RPC.EncryptionRequired
		$RPCBCV = $RPC.BlockedClientVersions		

    $DetailRPC+=  "					<tr>"
    $DetailRPC+=  "						<td width='20%'><font color='#0000FF'><b>$($RPCSrv)</b></font></td>"
    $DetailRPC+=  "						<td width='20%'><font color='#0000FF'><b>$($RPCResp)</b></font></td>"
    $DetailRPC+=  "						<td width='20%'><font color='#0000FF'><b>$($RPCMC)</b></font></td>"
    $DetailRPC+=  "						<td width='20%'><font color='#0000FF'><b>$($RPCER)</b></font></td>"
    $DetailRPC+=  "						<td width='20%'><font color='#0000FF'><b>$($RPCBCV)</b></font></td>"	
	$DetailRPC+=  "					</tr>"
}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderRPC)'>
            <SPAN class=sectionTitle tabIndex=0>RPCClientAccess Information</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='20%'><b>Server Name</b></font></th>
						<th width='20%'><b>Responsibility</b></font></th>
	  					<th width='20%'><b>MaximumConnections</b></font></th>
	  					<th width='20%'><b>EncryptionRequired</b></font></th>
	  					<th width='20%'><b>BlockedClientVersions</b></font></th>
	  				</tr>
                    $($DetailRPC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
"@
Return $Report