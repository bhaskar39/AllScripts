#===================================================================
# SetSPN - Viewing
#===================================================================
#write-Output "..SetSPN - Viewing"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderSetSPN = "heading1"
$AllSrvs = Get-Exchangeserver | Where-Object{$_.ServerRole -ne "Edge"}
foreach ($AllSrv in $AllSrvs){
    $DetailSetSPN+=  "					<tr>"
	$DetailSetSPN+=  "				    <th width='15%'><b>__________________________________<font color='#000080'>$($AllSrv)____________________________________</b></font></th>"
	$SetSPNs = SetSPN -l $AllSrv
	Foreach ($SetSPN in $SetSPNs){
	if ($SetSPN -ne $null)
	{
	$ClassHeaderSetSPN = "heading1"
    $DetailSetSPN+=  "					<tr>"
    $DetailSetSPN+=  "						<td width='15%'><b><font color='#0000FF'>$($SetSPN)</b></font></td>"
    $DetailSetSPN+=  "					</tr>"
	}
	else
	{
	$ClassHeaderSetSPN = "heading10"
	$DetailSetSPN+=  "					<tr>"
    $DetailSetSPN+=  "						<td width='15%'><b><font color='#FF0000'>Could not find account $($AllSrv)</b></font></td>"
    $DetailSetSPN+=  "					</tr>"
	}
}	
}

$Report += @"
	</TABLE>
	    <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderSetSPN)'>
            <SPAN class=sectionTitle tabIndex=0>SPN - Viewing SPNs</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>

	  				</tr>
                    $($DetailSetSPN)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  
"@

Return $Report