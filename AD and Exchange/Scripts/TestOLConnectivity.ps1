#===================================================================
# Test OutlookConnectivity
#===================================================================
#write-Output "..Test OutlookConnectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$TOCs = get-clientAccessServer | Test-OutlookConnectivity -RPCTestType:Server
foreach ($TOC in $TOCs){
$ClassHeaderCasOC = "heading1"
			   	$TOCCas = $TOC.ClientAccessServer
                $TOCEP = $TOC.ServiceEndpoint
				$TOCS = $TOC.Scenario
				$TOCRes = $TOC.Result
				$TOCLatency = $TOC.Latency
    $DetailCasOC+=  "					<tr>"
    $DetailCasOC+=  "						<td width='20%'><font color='#0000FF'><b>$($TOCCas)</b></font></td>"
    $DetailCasOC+=  "						<td width='20%'><font color='#0000FF'><b>$($TOCEP)</b></font></td>"
    $DetailCasOC+=  "						<td width='30%'><font color='#0000FF'><b>$($TOCS)</b></font></td>"
	if ($TOCRes -like "Success")
	{
    $ClassHeaderCasOC = "heading1"	
    $DetailCasOC+=  "						<td width='10%'><font color='#0000FF'><b>$($TOCRes)</b></font></td>"
    $DetailCasOC+=  "						<td width='20%'><font color='#0000FF'><b>$($TOCLatency)</b></font></td>"
	}
	else
	{
    $ClassHeaderCasOC = "heading10"
    $DetailCasOC+=  "						<td width='10%'><font color='#FF0000'><b>$($TOCRes)</b></font></td>"
    $DetailCasOC+=  "						<td width='20%'><font color='#FF0000'><b>$($TOCLatency)</b></font></td>"
	}
    $DetailCasOC+=  "					</tr>"
}

$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderCasOC)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test Outlook Connectivity Protocol HTTP</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Client Access Server</b></font></th>
							<th width='20%'><b>Service Endpoint</b></font></th>
	  						<th width='30%'><b>Scenario</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
	  						<th width='20%'><b>Latency</b></font></th>						
	  				</tr>
                    $($DetailCasOC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>               
   
"@
Return $Report