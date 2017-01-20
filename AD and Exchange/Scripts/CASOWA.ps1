#===================================================================
# Client Access Server - OWA Virtual Directory
#===================================================================
#write-Output "..Client Access Server - OWA Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$OWAVDS = Get-ClientAccessServer | Get-OWAVirtualDirectory | Select Server,Name,Exchange2003URL,FailbackURL,InternalUrl,ExternalUrl
$ClassHeaderOWAVD = "heading1"
    $DetailAUTOVD+=  "					<tr bgcolor='#B2BEB5'>"
    $DetailAUTOVD+=  "					<th><b>Server Name</th>"
    $DetailAUTOVD+=  "				    <th><b>Name</th>"
    $DetailAUTOVD+=  "				    <th><b>Exchange2003URL</th>"
    $DetailAUTOVD+=  "				    <th><b>FailbackURL</th>"
    $DetailAUTOVD+=  "				    <th><b>InternalUrl</th>"
    $DetailAUTOVD+=  "				    <th><b>ExternalUrl</th>"
    $DetailAUTOVD+=  "					</tr>"
 
 foreach($obj in $OABVDS)
 {
    $DetailAUTOVD+=  "					<tr>"
    $DetailAUTOVD+=  "					<td><b>$($obj.Server)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.Name)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.Exchange2003URL)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.FailbackURL)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.InternalUrl)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.ExternalUrl)</th>"
    $DetailAUTOVD+=  "					</tr>"
 }

$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderOWAVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - OWA Virtual Directory</SPAN>
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