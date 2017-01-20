#===================================================================
# Test OWA Connectivity
#===================================================================
#Write-Output "..Test OWA Connectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderowa = "heading1"
$OC = (Get-ClientAccessServer | test-owaconnectivity -AllowUnsecureAccess)
foreach($SOC in $OC)
               {
			    $SOCCAS = $SOC.ClientAccessServer
				$SOCMBX = $SOC.MailboxServer
				$SOCURL = $SOC.URL
				$SOCSC = $SOC.scenario
				$SOCRes = $SOC.Result
				$SOCLatency = $SOC.Latency
				$SOCError = $SOC.Error
            $Detailowa+=  "					<tr>"
			$Detailowa+=  "						<td width='20%'><font color='#0000FF'><b>$($SOCCAS)</b></font></td>"
			$Detailowa+=  "						<td width='20%'><font color='#0000FF'><b>$($SOCMBX)</b></font></td>" 
			$Detailowa+=  "						<td width='20%'><font color='#0000FF'><b>$($SOCURL)</b></font></td>"
			$Detailowa+=  "						<td width='10%'><font color='#0000FF'><b>$($SOCSC)</b></font></td>"
			if ($SOCRes -like "Success")
			{
 			$Detailowa+=  "						<td width='10%'><font color='#0000FF'><b>$($SOCRes)</b></font></td>"
			$Detailowa+=  "						<td width='10%'><font color='#0000FF'><b>$($SOCLatency)</b></font></td>" 
			$Detailowa+=  "						<td width='10%'><font color='#0000FF'><b>$($SOCError)</b></font></td>" 
			}
			else
			{
			$ClassHeaderowa = "heading10"
 			$Detailowa+=  "						<td width='10%'><font color='#FF0000'><b>$($SOCRes)</b></font></td>"
			$Detailowa+=  "						<td width='10%'><font color='#FF0000'><b>$($SOCLatency)</b></font></td>" 
			$Detailowa+=  "						<td width='10%'><font color='#FF0000'><b>$($SOCError)</b></font></td>" 			
			}
			$Detailowa+=  "					</tr>"
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderowa)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test OWAConnectivity</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Client Access Server</b></font></th>
							<th width='20%'><b>Mailbox Server</b></font></th>
	  						<th width='20%'><b>URL</b></font></th>
	  						<th width='10%'><b>Scenario</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
	  						<th width='10%'><b>Latency (ms)</b></font></th>
	  						<th width='10%'><b>Error</b></font></th>						
	  				</tr>
                    $($Detailowa)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report