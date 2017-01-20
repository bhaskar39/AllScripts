#===================================================================
# Test Powershell Connectivity
#===================================================================
#Write-Output "..Powershell Connectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderpwc = "heading1"
$PWCCAS = (Get-ExchangeServer | where-object{$_.adminDisplayversion.major -eq "14" -AND $_.ServerRole -like "ClientAccess*"})
foreach($TPWC in $PWCCAS)
               {
			    $PWCSrv = $TPWC.name
				$TPWC = Test-PowershellConnectivity -ClientAccessServer $PWCSrv
				foreach($PWCY in $TPWC)
				{
				$PWCYCS = $PWCY.ClientAccessServerShortName
				$PWCYLS = $PWCY.LocalSite
				$PWCYS = $PWCY.Scenario
				$PWCYR = $PWCY.Result
				$PWCYL = $PWCY.LatencyInMillisecondsString
				$PWCYE = $PWCY.Error				
				if($PWCYR -like "Success")
				{
			$ClassHeaderpwc = "heading1"				
			$Detailpwc+=  "					<tr>"
			$Detailpwc+=  "				        <td width='15%'><font color='#0000FF'><b>$($PWCYCS)</b></font></td>"			
			$Detailpwc+=  "						<td width='10%'><font color='#0000FF'><b>$($PWCYLS)</b></font></td>"
			$Detailpwc+=  "						<td width='10%'><font color='#0000FF'><b>$($PWCYS)</b></font></td>" 
			$Detailpwc+=  "						<td width='10%'><font color='#0000FF'><b>$($PWCYR)</b></font></td>"
			$Detailpwc+=  "						<td width='10%'><font color='#0000FF'><b>$($PWCYL)</b></font></td>"
			$Detailpwc+=  "						<td width='45%'><font color='#0000FF'><b>$($PWCYE)</b></font></td>"					
				}
				else
				{
			$ClassHeaderpwc = "heading10"	
			$Detailpwc+=  "					<tr>"
			$Detailpwc+=  "				        <td width='15%'><font color='#FF0000'><b>$($PWCYCS)</b></font></td>"			
			$Detailpwc+=  "						<td width='10%'><font color='#FF0000'><b>$($PWCYLS)</b></font></td>"
			$Detailpwc+=  "						<td width='10%'><font color='#FF0000'><b>$($PWCYS)</b></font></td>" 
			$Detailpwc+=  "						<td width='10%'><font color='#FF0000'><b>$($PWCYR)</b></font></td>"
			$Detailpwc+=  "						<td width='10%'><font color='#FF0000'><b>$($PWCYL)</b></font></td>"
			$Detailpwc+=  "						<td width='45%'><font color='#FF0000'><b>$($PWCYE)</b></font></td>"	
				}
			
			}
			
			$Detailpwc+=  "					</tr>"
}


$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderpwc)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test PowershellConnectivity</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='15%'><b>Server Name</b></font></th>					
	  						<th width='10%'><b>Local Site</b></font></th>
							<th width='10%'><b>Scenario</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
							<th width='10%'><b>Latency(MS)</b></font></th>
	  						<th width='450%'><b>Error</b></font></th>
					</tr>
                    $($Detailpwc)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report