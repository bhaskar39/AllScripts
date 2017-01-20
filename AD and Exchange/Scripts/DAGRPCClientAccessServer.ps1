#===================================================================
# Database Availability Group - RPCClientAccessServer
#===================================================================
#write-Output "..Database Availability Group - RPCClientAccessServer"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderRPCCAS = "heading1"
$DBrpcs = Get-MailboxDatabase -status | Where{$_.ReplicationType -eq "Remote"} | sort Name
$Sites = ((Get-ClientAccessArray).site).name
$Carrays = Get-ClientAccessArray
foreach ($Site in $Sites)
{
    $DetailRPCCAS+=  "					<tr>"
    $DetailRPCCAS+=  "						<td width='20%'><font color='#000080'><b>$($Site)</b></font></td><tr>"
foreach ($DBRPC in $DBRpcs){
		$DBname = $DBrpc.Name
		$DBSrv = $DBrpc.Server
		$DBRPC = $DBrpc.RpcClientAccessServer
		$DetailRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($DBname)</b></font></td>"
		$DetailRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($DBSrv)</b></font></td>"		
		$DetailRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($DBRPC)</b></font></td>"
	    $DetailRPCCAS+=  "						<td width='40%'><font color='#0000FF'></font></td>"	
        $DetailRPCCAS+=  "					</tr>"
}
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderRPCCAS)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - RPCClientAccessServer</SPAN>
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
                    $($DetailRPCCAS)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>               
"@
Return $Report