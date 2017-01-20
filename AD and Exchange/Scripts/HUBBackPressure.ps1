#===================================================================
# HUB Transport - Back Pressure (E2K10 Only)
#===================================================================
#write-Output "..HUB Transport - Back Pressure Events (E2K10 Only)"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$E2K10HT = Get-ExchangeServer | ?{$_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsHubTransportServer -eq "True"}
$ClassHeaderHUBBP = "heading1"
foreach($HTBP in $E2K10HT){
	$HBPevt = get-eventlog -LogName Application -computername $HTBP -newest 100 | ?{$_.Source -like "MSExchange Transport" -AND $_.EventId -eq "15004" -OR $_.EventId -eq "15005" -OR $_.EventId -eq "15006" -OR $_.EventId -eq "15007"}
	foreach($HBP in $HBPevt){
	$HBPInst = $HBP.EventId
	$HBPTW = $HBP.TimeWritten
	$HBPEType = $HBP.EntryType
	$HBPSource = $HBP.Source
	$HBPMsg = $HBP.Message
	$DetailHUBBP+=  "					<tr>"
	$DetailHUBBP+=  "					    <td width='10%'><font color='#000080'><b>$($HTBP)</b></font></td>"
    $DetailHUBBP+=  "						<td width='5%'><font color='#0000FF'><b>$($HBPInst)</b></font></td>"
    $DetailHUBBP+=  "						<td width='10%'><font color='#0000FF'><b>$($HBPTW)</b></font></td>"
    $DetailHUBBP+=  "						<td width='10%'><font color='#0000FF'><b>$($HBPEType)</b></font></td>"
    $DetailHUBBP+=  "						<td width='15%'><font color='#0000FF'><b>$($HBPSource)</b></font></td>"
    $DetailHUBBP+=  "						<td width='50%'><font color='#0000FF'><b>$($HBPMsg)</b></font></td>"
    $DetailHUBBP+=  "					</tr>"
}
}
	
$Report += @"
	</TABLE>
	    <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderHUBBP)'>
            <SPAN class=sectionTitle tabIndex=0>HUB Transport - Back Pressure (E2K10 Only)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='10%'><b>Server Name</b></font></th>					
	  						<th width='5%'><b>EventId</b></font></th>
							<th width='10%'><b>TimeWritten</b></font></th>
							<th width='10%'><b>EntryType</b></font></th>
							<th width='15%'><b>Source</b></font></th>
	  						<th width='50%'><b>Message</b></font></th>
	  				</tr>
                    $($DetailHUBBP)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>	
"@
Return $Report