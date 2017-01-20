#===================================================================
# Database Availability Group - Information
#===================================================================
#write-Output "..Database Availability Group - Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$DAGS = Get-DatabaseAvailabilityGroup -Status 
$ClassHeaderDAG = "heading1"
Foreach($DAG in $DAGS){
		$DAGname = $DAG.Name
		$DAGServer = $DAG.Servers
		$DAGpam = $DAG.PrimaryActiveManager
		$DAGdac = $DAG.DatacenterActivationMode
		$DAGNet = $DAG.DatabaseAvailabilityGroupIpAddresses
		$DAGRPort = $DAG.ReplicationPort
    $DetailDAG+=  "					<tr>"
    $DetailDAG+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGName)</b></font></td>"
    $DetailDAG+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGServer)</b></font></td>"
    $DetailDAG+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGpam)</b></font></td>"
    $DetailDAG+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGdac)</b></font></td>"
    $DetailDAG+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGNet)</b></font></td>"	
	$DetailDAG+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGRPort)</b></font></td>"	
    $DetailDAG+=  "					</tr>"
		$DAGWS = $DAG.WitnessServer
		$DAGWD = $DAG.WitnessDirectory
		$DAGAWS = $DAG.AlternateWitnessServer
		$DAGAWD = $DAG.AlternateWitnessDirectory		
    $DetailDAG2+=  "					<tr>"
    $DetailDAG2+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGWS)</b></font></td>"
    $DetailDAG2+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGWD)</b></font></td>"
    $DetailDAG2+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGAWS)</b></font></td>"
    $DetailDAG2+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGAWD)</b></font></td>"
    $DetailDAG2+=  "					</tr>"
		$DAGNC = $DAG.NetworkCompression
		$DAGNE = $DAG.NetworkEncryption
		$DAGNetName = $DAG.NetworkNames	
    $DetailDAG3+=  "					<tr>"
    $DetailDAG3+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGNC)</b></font></td>"
    $DetailDAG3+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGNE)</b></font></td>"
    $DetailDAG3+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGNetName)</b></font></td>"
    $DetailDAG3+=  "					</tr>"
}
$DAGMBXS = Get-MailboxServer -Status | where-object{$_.DatabaseAvailabilityGroup -ne $null}
$ClassHeaderADM = "heading1"
foreach($DAGMBX in $DAGMBXS){
		$DAGMBXN = $DAGMBX.Name
		$DAGMBXADM = $DAGMBX.AutoDatabaseMountDial
		$DAGMBXDAG = $DAGMBX.DatabaseAvailabilityGroup
		$DAGMBXDCAP = $DAGMBX.DatabaseCopyAutoActivationPolicy
		$DAGMBXMAD = $DAGMBX.MaximumActiveDatabases
    $DetailADM+=  "					<tr>"
    $DetailADM+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGMBXN)</b></font></td>"
    $DetailADM+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGMBXADM)</b></font></td>"
    $DetailADM+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGMBXDAG)</b></font></td>"
    $DetailADM+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGMBXDCAP)</b></font></td>"
    $DetailADM+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGMBXAD)</b></font></td>"	
    $DetailADM+=  "					</tr>"
}	
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderDAG)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Information</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='10%'><b>DAG Name</b></font></th>
							<th width='20%'><b>Servers</b></font></th>
							<th width='10%'><b>P.A.M.</b></font></th>
							<th width='10%'><b>DAC Mode</b></font></th>
							<th width='10%'><b>Network IP</b></font></th>
							<th width='10%'><b>Replication Port</b></font></th>
					</tr>
                    $($DetailDAG)
                </table>
                <table>
	  				<tr>
	  						<br><th width='20%'><b>Witness Server</b></font></th>
							<th width='20%'><b>Witness Directory</b></font></th>
							<th width='20%'><b>Alternate Witness Server</b></font></th>
							<th width='20%'><b>Alternate Directory</b></font></th>
 		   		</tr>
                    $($DetailDAG2)
                </table>
                <table>
	  				<tr>
	  						<br><th width='20%'><b>NetworkCompression</b></font></th>
							<th width='20%'><b>NetworkEncryption</b></font></th>
							<th width='20%'><b>NetworkNames</b></font></th>
 		   		</tr>
                    $($DetailDAG3)
                </table>
                <table>
	  				<tr>
	  						<br><th width='20%'><b>Server Name</b></font></th>
							<th width='20%'><b>AutoDatabaseMountDial</b></font></th>
							<th width='20%'><b>DatabaseAvailabilityGroup</b></font></th>
							<th width='20%'><b>DatabaseCopyAutoActivationPolicy</b></font></th>
							<th width='20%'><b>MaximumActiveDatabases</b></font></th>
					</tr>
                    $($DetailADM)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  
"@
Return $Report