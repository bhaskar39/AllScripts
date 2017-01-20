#===================================================================
# Mailbox Server - Database Size and Availability
#===================================================================
#write-Output "..Mailbox Server - Database Size and Availability"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$MBXDBsizes = Get-MailboxDatabase -status | where-object{$_.ReplicationType -ne "Remote"} | sort Name
$ClassHeaderMBXDBsize = "heading1"
foreach ($MBXDBsize in $MBXDBsizes){
		$DBname = $MBXDBsize.Name
		$DataBSize = $MBXDBsize.DatabaseSize
		$DbANMS = $MBXDBsize.AvailableNewMailboxSpace
    $DetailMBXDBsize+=  "					<tr>"
    $DetailMBXDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DBname)</b></font></td>"
    $DetailMBXDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DataBsize)</b></font></td>"
    $DetailMBXDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DBANMS)</b></font></td>"
    $DetailMBXDBsize+=  "						<td width='40%'><font color='#0000FF'><b> </b></font></td>"	
    $DetailMBXDBsize+=  "					</tr>"
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderMBXDBsize)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox Server - Database Size and Availability</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Database Name</b></font></th>
							<th width='20%'><b>Database Size</b></font></th>
							<th width='20%'><b>AvailableNewMailboxSpace</b></font></th>
							<th width='40%'><b> </b></font></th>							
 		   		</tr>
                    $($DetailMBXDBsize)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>                
"@
Return $Report