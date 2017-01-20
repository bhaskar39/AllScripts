#===================================================================
# Exchange Services
#===================================================================
#Write-Output "..Exchange Services"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ExchangeServerList = Get-ExchangeServer | where {$_.ServerRole -ne "Edge"} 
$ClassHeaderExch = "heading1"
foreach($Exch in $ExchangeServerList)
    {
    $ServiceHealth = Test-ServiceHealth -Server $Exch | where { $_.RequiredServicesRunning -eq $False}
    $ServerVer = $Exch.AdminDisplayVersion
    $ServerRole = $Exch.ServerRole
	$SvcRun = "All Services are Running"
    $DetailExch+=  "					<tr>"
    $DetailExch+=  "						<td width='20%'><font color='#0000FF'><b>$($Exch)</b></font></td>"
    $DetailExch+=  "						<td width='20%'><font color='#0000FF'><b>$($ServerRole)</b></font></td>" 
    $DetailExch+=  "						<td width='30%'><font color='#0000FF'><b>$($Serverver)</b></font></td>"			
foreach($Items in $ServiceHealth)
		{
	   		If($Items.ServicesNotRunning.Count -gt 0)
       		{
       		$Global:Valid = 0
                foreach($Service in $Items.ServicesNotRunning)
                {
		$ClassHeaderExch = "heading10"		
        $DetailExch+=  "						<td width='25%'><font color='#FF0000'><b>$($Service)</b></font></td><tr><td width='20%'><td width='20%'><td width='30%'>"
				}
			}
			Else
			{
        $DetailExch+=  "						<td width='25%'><font color='#0000FF'><b>$($SvcRun)</b></font></td>"
			}

		}
		$DetailExch+=  "					</tr>"
	}
$Report += @"
	</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderExch)'>
            <SPAN class=sectionTitle tabIndex=0>Exchange Services - All Exchange Versions</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
					<th width='20%'><b>Server Name</b></font></th>
					<th width='20%'><b>Server Role</b></font></th>
					<th width='30%'><b>Exchange Version</b></font></th>
					<th width='25%'><b>Exchange Services Status</b></font></th>						
	  				</tr>
                    $($DetailExch)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
Return $Report