#===================================================================
# Database Availability Group - Network
#===================================================================
#write-Output "..Database Availability Group - Network"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$DAGNWKS = Get-DatabaseAvailabilityGroupNetwork
$ClassHeaderDAGNetworks = "heading1"
foreach($DAGNetwork in $DAGNWKS)
{
    	$DAGNWN = $DAGNetwork.Identity
		$DAGNWSub = $DAGNetwork.Subnets
		$DAGNWMAPI = $DAGNetwork.MapiAccessEnabled
		$DAGNWRE = $DAGNetwork.ReplicationEnabled	
		$DAGNWIN = $DAGNetwork.IgnoreNetwork
		$DAGNWInterf = $DAGNetwork.Interfaces
	$DetailDAGNetworks+=  "					<tr>"
    $DetailDAGNetworks+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGNWN)</b></font></td>"
    $DetailDAGNetworks+=  "						<td width='15%'><font color='#0000FF'><b>$($DAGNWSub)</b></font></td>"
    $DetailDAGNetworks+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGNWMAPI)</b></font></td>"
    $DetailDAGNetworks+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGNWRE)</b></font></td>"
    $DetailDAGNetworks+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGNWIN)</b></font></td>"	
	$DetailDAGNetworks+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGNWInterf)</b></font></td>"	
    $DetailDAGNetworks+=  "					</tr>"
}

$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderDAGNetworks)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Network</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='10%'><b>Identity</b></font></th>
							<th width='15%'><b>Subnets</b></font></th>
							<th width='10%'><b>MapiAccessEnabled</b></font></th>
							<th width='10%'><b>ReplicationEnabled</b></font></th>
							<th width='10%'><b>IgnoreNetwork</b></font></th>
							<th width='20%'><b>Interfaces</b></font></th>
					</tr>
                    $($DetailDAGNetworks)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
 
"@
Return $Report