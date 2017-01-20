#===================================================================
# Database Availability Group - Database Size and Availability
#===================================================================
#write-Output "..Database Availability Group - Database Size and Availability"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$DBsizes = Get-MailboxDatabase -status | where-object{$_.ReplicationType -eq "Remote"} | sort Name
$ClassHeaderDBsize = "heading1"
foreach ($DBsize in $DBsizes){
		$DBname = $DBsize.Name
		$DBSrv = $DBsize.Server
		$DataBSize = $DBsize.DatabaseSize
		$DbANMS = $DBsize.AvailableNewMailboxSpace
		$DbDMRC = $DBsize.DataMoveReplicationConstraint
    $DetailDBsize+=  "					<tr>"
    $DetailDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DBname)</b></font></td>"
    $DetailDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DBSrv)</b></font></td>"	
    $DetailDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DataBsize)</b></font></td>"
    $DetailDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DBANMS)</b></font></td>"
    $DetailDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DbDMRC)</b></font></td>"	
    $DetailDBsize+=  "					</tr>"
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderDBsize)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Database Size and Availability</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Database Name</b></font></th>
	  						<th width='20%'><b>Server Name</b></font></th>							
							<th width='20%'><b>Database Size</b></font></th>
							<th width='20%'><b>AvailableNewMailboxSpace</b></font></th>
							<th width='20%'><b>DataMoveReplicationConstraint</b></font></th>							
 		   		</tr>
                    $($DetailDBsize)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>               
"@
Return $Report