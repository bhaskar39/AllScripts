#===================================================================
# Test Web Services Connectivity
#===================================================================
#Write-Output "..Test Web Services Connectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$WSC = (Get-ClientAccessServer | test-webservicesconnectivity -AllowUnsecureAccess)
$ClassHeaderWSC = "heading1"
foreach($WebS in $WSC)
               {
			    $WebSCAS = $WebS.ClientAccessServer
				$WebSSite = $WebS.LocalSite
				$WebSSC = $WebS.scenario
				$WebSRes = $WebS.Result
				$WebSLatency = $WebS.Latency
				$WebSError = $WebS.Error
    $DetailWSC+=  "					<tr>"
    $DetailWSC+=  "						<td width='20%'><font color='#0000FF'><b>$($WEBSCAS)</b></font></td>"
    $DetailWSC+=  "						<td width='20%'><font color='#0000FF'><b>$($WEBSSite)</b></font></td>"
    $DetailWSC+=  "						<td width='20%'><font color='#0000FF'><b>$($WEBSSC)</b></font></td>"			
			if ($webSRes -like "Success")
    {
    $DetailWSC+=  "						<td width='10%'><font color='#0000FF'><b>$($WEBSRes)</b></font></td>"
    $DetailWSC+=  "						<td width='10%'><font color='#0000FF'><b>$($WEBSLatency)</b></font></td>"				
    $DetailWSC+=  "						<td width='10%'><font color='#0000FF'><b>$($WEBSError)</b></font></td>" 
    }
    else
    {
    $ClassHeaderWSC = "heading10"
    $DetailWSC+=  "						<td width='10%'><font color='#FF0000'><b>$($WEBSRes)</b></font></td>"
    $DetailWSC+=  "						<td width='10%'><font color='#FF0000'><b>$($WEBSLatency)</b></font></td>"			
    $DetailWSC+=  "						<td width='10%'><font color='#FF0000'><b>$($WEBSError)</b></font></td>" 
    }
    $DetailWSC+=  "					</tr>"
}

$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderWSC)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test WebServicesConnectivity</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='20%'><b>Client Access Server</b></font></th>
						<th width='20%'><b>LocalSite</b></font></th>
	  					<th width='20%'><b>Scenario</b></font></th>
	  					<th width='10%'><b>Result</b></font></th>
	  					<th width='10%'><b>Latency (ms)</b></font></th>
	  					<th width='10%'><b>Error</b></font></th>							
	  				</tr>
                    $($DetailWSC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report