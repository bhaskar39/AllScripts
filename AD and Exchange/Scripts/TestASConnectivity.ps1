#===================================================================
# Test ActiveSync Connectivity
#===================================================================
#Write-Output "..Test ActiveSync Connectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ASC = (Get-ClientAccessServer | Test-activesyncconnectivity -trustanySSLCertificate)
$ClassHeaderASC = "heading1"
foreach($Sync in $ASC)
               {
			    $SyncCAS = $sync.ClientAccessServer
				$syncSite = $sync.LocalSite
				$syncSC = $sync.scenario
				$syncRes = $sync.Result
				$syncLatency = $sync.Latency
				$syncError = $sync.Error
    $DetailASC+=  "					<tr>"
    $DetailASC+=  "						<td width='20%'><font color='#0000FF'><b>$($syncCAS)</b></font></td>"
    $DetailASC+=  "						<td width='20%'><font color='#0000FF'><b>$($syncSite)</b></font></td>"
    $DetailASC+=  "						<td width='20%'><font color='#0000FF'><b>$($syncSC)</b></font></td>"			
    if ($syncRes -like "Success")
    {
    $ClassHeaderASC = "heading1"	
    $DetailASC+=  "						<td width='10%'><font color='#0000FF'><b>$($syncRes)</b></font></td>"
    $DetailASC+=  "						<td width='10%'><font color='#0000FF'><b>$($syncLatency)</b></font></td>"				
    $DetailASC+=  "						<td width='10%'><font color='#0000FF'><b>$($syncError)</b></font></td>" 
    }
    else
    {
    $ClassHeaderASC = "heading10"
    $DetailASC+=  "						<td width='10%'><font color='#FF0000'><b>$($syncRes)</b></font></td>"
    $DetailASC+=  "						<td width='10%'><font color='#FF0000'><b>$($syncLatency)</b></font></td>"			
    $DetailASC+=  "						<td width='10%'><font color='#FF0000'><b>$($syncError)</b></font></td>" 
    }
    $DetailASC+=  "					</tr>"
}

$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderASC)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test ActiveSyncConnectivity</SPAN>
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
                    $($DetailASC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report