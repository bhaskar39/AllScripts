#===================================================================
# Mailbox Server - RPCClientAccessServer
#===================================================================
# write-Output "..Mailbox Server - RPCClientAccessServer"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderMBXRPCCAS = "heading1"
$MBXInfos = Get-MailboxServer -Status | where-object{$_.DatabaseAvailabilityGroup -eq $null}
foreach ($MBXInfo in $MBXInfos)
{
    $DetailMBXRPCCAS+=  "					<tr>"
    $DetailMBXRPCCAS+=  "						<tr><td width='20%'><font color='#000080'><b>$($MBXInfo)</b></font></td><tr>"
$MBXDBrpcs = Get-MailboxDatabase -status | Where{$_.ReplicationType -ne "Remote"} | sort Name
foreach ($MBXDBrpc in $MBXDBrpcs){
		$MBXDB = $MBXDBrpc.Name
		$MBXSrv = $MBXDBrpc.Server
		$MBXDBrpc = $MBXDBrpc.RpcClientAccessServer
		
    $DetailMBXRPCCAS+=  "					<tr>"
    $DetailMBXRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXDB)</b></font></td>"
    $DetailMBXRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXSrv)</b></font></td>"	
    $DetailMBXRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXDBrpc)</b></font></td>"
	$DetailMBXRPCCAS+=  "						<td width='40%'><font color='#0000FF'></font></td>"	
    $DetailMBXRPCCAS+=  "					</tr>"
}
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderMBXRPCCAS)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox Server - RPCClientAccessServer (Out of DAG servers)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Database Name</b></font></th>
	  						<th width='20%'><b>Server Name</b></font></th>							
							<th width='20%'><b>RPC Client Access Server</b></font></th>
							<th width='40%'><b></b></font></th>                            
 		   		</tr>
                    $($DetailMBXRPCCAS)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>         
"@
Return $Report