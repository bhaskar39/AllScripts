#===================================================================
# SetSPN - Duplicate
#===================================================================
#write-Output "..SetSPN - Duplicate"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderSetSPND = "heading1"
$SetSPNDs = SetSPN -X
	Foreach ($SetSPND in $SetSPNDs){
    $DetailSetSPND+=  "					<tr>"
    $DetailSetSPND+=  "						<td width='15%'><b><font color='#0000FF'>$($SetSPND)</b></font></td>"
    $DetailSetSPND+=  "					</tr>"
}

$Report += @"
	</TABLE>
	    <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderSetSPND)'>
            <SPAN class=sectionTitle tabIndex=0>SPN - Duplicated SPNs</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>

	  				</tr>
                    $($DetailSetSPND)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  
"@

Return $Report