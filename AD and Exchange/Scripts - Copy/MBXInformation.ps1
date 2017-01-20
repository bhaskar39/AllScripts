#===================================================================
# Mailbox Server - Information
#===================================================================
#write-Output "..Mailbox Server - Information (Out of DAG servers)"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$MBXInfos = Get-MailboxServer -Status | where-object{$_.DatabaseAvailabilityGroup -eq $null}
$ClassHeaderMBXI = "heading1"
foreach($MBXInfo in $MBXInfos){
		$MBXInfoN = $MBXInfo.Name
		$MBXInfoADM = $MBXInfo.AutoDatabaseMountDial
		$MBXInfoADV = $MBXInfo.AdminDisplayVersion
    $DetailMBXI+=  "					<tr>"
    $DetailMBXI+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXInfoN)</b></font></td>"
    $DetailMBXI+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXInfoADM)</b></font></td>"
    $DetailMBXI+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXInfoADV)</b></font></td>"
    $DetailMBXI+=  "						<td width='40%'><font color='#0000FF'><b> </b></font></td>"	
    $DetailMBXI+=  "					</tr>"
}	
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderMBXI)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox Server - Information (Out of DAG servers)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                 </table>
                <table>
	  				<tr>
	  						<th width='20%'><b>Server Name</b></font></th>
							<th width='20%'><b>AutoDatabaseMountDial</b></font></th>
							<th width='20%'><b>AdminDisplayVersion</b></font></th>
							<th width='40%'><b> </b></font></th>
					</tr>
                    $($DetailMBXI)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  
"@
Return $Report