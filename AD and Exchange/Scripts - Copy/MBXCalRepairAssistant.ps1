#===================================================================
# Mailbox Server - Calendar Repair Assistant
#===================================================================
#Write-Output "..Mailbox Server - Calendar Repair Assistant"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderCRA = "heading1"
$MBXCRAall = Get-MailboxServer | ?{$_.AdminDisplayVersion -like "Version 14.*"}
Foreach($MBXCRA in $MBXCRAall)
 {
        $SRVCRA = $MBXCRA.Name
		$CRWC = $MBXCRA.CalendarRepairWorkCycle
		$CRWCC = $MBXCRA.CalendarRepairWorkCycleCheckpoint
		$CRLE = $MBXCRA.CalendarRepairLogEnabled
		$CRLSLE = $MBXCRA.CalendarRepairLogSubjectLoggingEnabled		
		$CRLFAL = $MBXCRA.CalendarRepairLogFileAgeLimit
		$CRLDSL = $MBXCRA.CalendarRepairLogDirectorySizeLimit
		$CRLP = $MBXCRA.CalendarRepairLogPath
    $DetailCRA+=  "					<tr>"
    $DetailCRA+=  "						<td width='10%'><font color='#0000FF'><b>$($SRVCRA)</b></font></td>"
    $DetailCRA+=  "						<td width='10%'><font color='#0000FF'><b>$($CRWC)</b></font></td>"
    $DetailCRA+=  "						<td width='15%'><font color='#0000FF'><b>$($CRWCC)</b></font></td>"
    $DetailCRA+=  "						<td width='10%'><font color='#0000FF'><b>$($CRLE)</b></font></td>"
    $DetailCRA+=  "						<td width='15%'><font color='#0000FF'><b>$($CRLSLE)</b></font></td>"	
    $DetailCRA+=  "						<td width='10%'><font color='#0000FF'><b>$($CRLFAL)</b></font></td>"
    $DetailCRA+=  "						<td width='10%'><font color='#0000FF'><b>$($CRLDSL)</b></font></td>"
    $DetailCRA+=  "						<td width='20%'><font color='#0000FF'><b>$($CRLP)</b></font></td>"
	$DetailCRA+=  "					</tr>"
}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderCRA)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox Server - Calendar Repair Assistant</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='10%'><b>Server Name</b></font></th>
						<th width='10%'><b>WorkCycle</b></font></th>
	  					<th width='15%'><b>WorkCycleCheckpoint</b></font></th>
	  					<th width='10%'><b>LogEnabled</b></font></th>
	  					<th width='15%'><b>LogSubjectLoggingEnabled</b></font></th>
	  					<th width='10%'><b>LogFileAgeLimit</b></font></th>
	  					<th width='10%'><b>LogDirectorySizeLimit</b></font></th>
	  					<th width='20%'><b>LogPath</b></font></th>							
	  				</tr>
                    $($DetailCRA)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
"@
Return $Report