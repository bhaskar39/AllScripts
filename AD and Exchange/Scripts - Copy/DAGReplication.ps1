#===================================================================
# Database Availability Group - Replication
#===================================================================
#write-Output "..Database Availability Group - Replication"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderRepl = "heading1"
$DBReplication = (Get-MailboxServer | where{$_.AdminDisplayVersion.Major -ge 14 -AND $_.DatabaseAvailabilityGroup -ne $null} | sort server | Test-ReplicationHealth)
Foreach($Repl in $DBReplication)
 {
              $server = $Repl.Server
			  $check = $Repl.check
              $result = $Repl.result
              $err = $Repl.error
    $DetailRepl+=  "					<tr>"
    $DetailRepl+=  "						<td width='20%'><font color='#0000FF'><b>$($server)</b></font></td>"
    $DetailRepl+=  "						<td width='20%'><font color='#0000FF'><b>$($check)</b></font></td>"
	if ($result -like "Passed")
	{
        $DetailRepl+=  "					<td width='20%'><font color='#0000FF'><b>$($result)</b></font></td>"
    }
    else
    {
    $ClassHeaderRepl = "heading10"
    $DetailRepl+=  "						<td width='20%'><font color='#FF0000'><b>$($result)</b></font></td>"
	$DetailRepl+=  "						<td width='20%'><font color='#FF0000'><b>$($err)</b></font></td>"
	$DetailRepl+=  "					</tr>"
	}
}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderRepl)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Replication Status</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='20%'><b>Server Name</b></font></th>
						<th width='20%'><b>Check</b></font></th>
	  					<th width='20%'><b>Result</b></font></th>
	  					<th width='20%'><b>Error</b></font></th>							
	  				</tr>
                    $($DetailRepl)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report