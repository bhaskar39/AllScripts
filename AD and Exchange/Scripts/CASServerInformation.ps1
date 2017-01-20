#===================================================================
# Client Access Server Information
#===================================================================
#write-Output "..Client Access Server Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$CASarrays = Get-ClientAccessArray | Select name,site,fqdn,members
$ClassHeaderCASarray = "heading1"

    $DetailAUTOVD+=  "					<tr bgcolor='#B2BEB5'>"
    $DetailAUTOVD+=  "					<th><b>Name</th>"
    $DetailAUTOVD+=  "				    <th><b>Site</th>"
    $DetailAUTOVD+=  "				    <th><b>FQDN</th>"
    $DetailAUTOVD+=  "				    <th><b>Members</th>"
    $DetailAUTOVD+=  "					</tr>"
 
 foreach($obj in $CASarrays)
 {
    $DetailAUTOVD+=  "					<tr>"
    $DetailAUTOVD+=  "					<td><b>$($obj.name)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.Site)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.FQDN)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.Members)</th>"
    $DetailAUTOVD+=  "					</tr>"
 }

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderCASArray)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - Client Access Array</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
            <table border=1>
                $DetailAUTOVD
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

$casuri = Get-ClientAccessServer | Select name,AutoDiscoverServiceInternalUri,AutoDiscoverSiteScope
$ClassHeaderCASauto = "heading1"

    $DetailAUTOVD1+=  "					<tr bgcolor='#B2BEB5'>"
    $DetailAUTOVD1+=  "					<th><b>Name</th>"
    $DetailAUTOVD1+=  "				    <th><b>AutoDiscoverServiceInternalUri</th>"
    $DetailAUTOVD1+=  "				    <th><b>AutoDiscoverSiteScope</th>"
    $DetailAUTOVD1+=  "					</tr>"
 
 foreach($obj in $CASarrays)
 {
    $DetailAUTOVD1+=  "					<tr>"
    $DetailAUTOVD1+=  "					<td><b>$($obj.name)</th>"
    $DetailAUTOVD1+=  "				    <td><b>$($obj.AutoDiscoverServiceInternalUri)</th>"
    $DetailAUTOVD1+=  "				    <td><b>$($obj.AutoDiscoverSiteScope)</th>"
    $DetailAUTOVD1+=  "					</tr>"
 }

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderCASauto)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - Autodiscover</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
            <table border=1>
                $DetailAUTOVD
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              

"@
Return $Report