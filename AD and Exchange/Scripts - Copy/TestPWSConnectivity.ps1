#===================================================================
# Test PowershellConnectivity
#===================================================================
#write-Output "..Test PowershellConnectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$PWSs = get-clientAccessServer | Test-PowershellConnectivity
foreach ($PWS in $PWSs){
$ClassHeaderPWSH = "heading1"
			   	$PWSCas = $PWS.ClientAccessServer
                $PWSLS = $PWS.LocalSite
				$PWSS = $PWS.Scenario
				$PWSRes = $PWS.Result
				$PWSLatency = $PWS.Latency
				$PWSErr = $PWS.Error
				
    $DetailPWSH+=  "					<tr>"
    $DetailPWSH+=  "						<td width='20%'><font color='#0000FF'><b>$($PWSCAS)</b></font></td>"
    $DetailPWSH+=  "						<td width='20%'><font color='#0000FF'><b>$($PWSLS)</b></font></td>"
    $DetailPWSH+=  "						<td width='10%'><font color='#0000FF'><b>$($PWSS)</b></font></td>"
	if ($PWSRes -like "Success")
	{
    $ClassHeaderPWSH = "heading1"	
    $DetailPWSH+=  "						<td width='10%'><font color='#0000FF'><b>$($PWSRes)</b></font></td>"
    $DetailPWSH+=  "						<td width='10%'><font color='#0000FF'><b>$($PWSLatency)</b></font></td>"
    $DetailPWSH+=  "						<td width='30%'><font color='#0000FF'><b>$($PWSErr)</b></font></td>"	
	}
	else
	{
    $ClassHeaderPWSH = "heading10"
    $DetailPWSH+=  "						<td width='10%'><font color='#FF0000'><b>$($PWSRes)</b></font></td>"
    $DetailPWSH+=  "						<td width='10%'><font color='#FF0000'><b>$($PWSLatency)</b></font></td>"
    $DetailPWSH+=  "						<td width='30%'><font color='#FF0000'><b>$($PWSErr)</b></font></td>"	
	}
    $DetailPWSH+=  "					</tr>"
}

$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderPWSH)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test PowershellConnectivity</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Client Access Server</b></font></th>
							<th width='20%'><b>Service Endpoint</b></font></th>
	  						<th width='10%'><b>Scenario</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
	  						<th width='10%'><b>Latency</b></font></th>	
	  						<th width='30%'><b>Error</b></font></th>							
	  				</tr>
                    $($DetailPWSH)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>               
   
"@
Return $Report