#===================================================================
# Test OutlookWebServices
#===================================================================
#write-Output "..Test OutlookWebServices"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$OWSs = Test-OutlookWebServices
$ClassHeaderOWebS = "heading1"
foreach ($OWS.RunspaceId in $OWSs.RunspaceId){
			   	$OWSID = $OWS.ID
				$OWST = $OWS.Type
				$OWSMsg = $OWS.Message

    $DetailOWebS+=  "					<tr>"
    $DetailOWebS+=  "						<td width='20%'><font color='#0000FF'><b>$($OWSID)</b></font></td>"
	if ($OWST -like "Success")
	{
    $ClassHeaderOWebS = "heading1"	
    $DetailOWebS+=  "						<td width='20%'><font color='#0000FF'><b>$($OWST)</b></font></td>"
    $DetailOWebS+=  "						<td width='60%'><font color='#0000FF'><b>$($OWSMsg)</b></font></td>"
	}
	else
	{
    $ClassHeaderOWebS = "heading10"
    $DetailOWebS+=  "						<td width='20%'><font color='#FF0000'><b>$($OWST)</b></font></td>"
    $DetailOWebS+=  "						<td width='60%'><font color='#FF0000'><b>$($OWSMsg)</b></font></td>"
	}
    $DetailOWebS+=  "					</tr>"
}

$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderOWebS)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test OutlookWebServices</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>ID</b></font></th>
							<th width='20%'><b>Type</b></font></th>
	  						<th width='60%'><b>Message</b></font></th>
	  				</tr>
                    $($DetailOWebS)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>               
   
"@
Return $Report