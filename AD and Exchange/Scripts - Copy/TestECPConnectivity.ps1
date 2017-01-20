#===================================================================
# Test ECP Connectivity
#===================================================================	 
#Write-Output "..Test ECP Connectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ECPC = (Get-ClientAccessServer | Test-ecpconnectivity)
$ClassHeaderECP = "heading1"
foreach($ECP in $ECPC)
{
    $ECPCAS = $ECP.ClientAccessServer
    $ECPSite = $ECP.LocalSite
    $ECPSC = $ECP.scenario
    $ECPRes = $ECP.Result
    $ECPLatency = $ECP.Latency
    $ECPError = $ECP.Error
    $DetailECP+=  "					<tr>"
    $DetailECP+=  "						<td width='20%'><font color='#0000FF'><b>$($ECPCAS)</b></font></td>"
    $DetailECP+=  "						<td width='20%'><font color='#0000FF'><b>$($ECPSite)</b></font></td>" 
    $DetailECP+=  "						<td width='20%'><font color='#0000FF'><b>$($ECPSC)</b></font></td>"			
    if ($ECPRes -like "Success")
    {
        $ClassHeaderECP = "heading1"	
        $DetailECP+=  "						<td width='10%'><font color='#0000FF'><b>$($ECPRes)</b></font></td>"
        $DetailECP+=  "						<td width='10%'><font color='#0000FF'><b>$($ECPLatency)</b></font></td>"			
        $DetailECP+=  "						<td width='10%'><font color='#0000FF'><b>$($ECPError)</b></font></td>" 
    }
    else
    {
        $ClassHeaderECP = "heading10"
        $DetailECP+=  "						<td width='10%'><font color='#FF0000'><b>$($ECPRes)</b></font></td>"
        $DetailECP+=  "						<td width='10%'><font color='#FF0000'><b>$($ECPLatency)</b></font></td>"			
        $DetailECP+=  "						<td width='10%'><font color='#FF0000'><b>$($ECPError)</b></font></td>" 
    }
    $DetailECP+=  "					</tr>"
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderECP)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test ECPConnectivity</SPAN>
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
                    $($DetailECP)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
Return $Report