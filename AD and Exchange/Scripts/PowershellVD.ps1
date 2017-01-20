#===================================================================
# Client Access Server - Powershell Virtual Directory
#===================================================================
#write-Output "..Powershell Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$PWSVDS = Get-ClientAccessServer | Get-PowershellVirtualDirectory | Select server,name,CertificateAuthentication,RequireSSL,MetabasePath,Path,InternalURL,ExternalURL
$ClassHeaderPWSVD = "heading1"
    $DetailAUTOVD+=  "					<tr bgcolor='#B2BEB5'>"
    $DetailAUTOVD+=  "					<th><b>Server Name</th>"
    $DetailAUTOVD+=  "				    <th><b>Name</th>"
    $DetailAUTOVD+=  "				    <th><b>CertificateAuthentication</th>"
    $DetailAUTOVD+=  "				    <th><b>RequireSSL</th>"
    $DetailAUTOVD+=  "				    <th><b>MetabasePath</th>"
    $DetailAUTOVD+=  "				    <th><b>Path</th>"
    $DetailAUTOVD+=  "				    <th><b>InternalURL</th>"
    $DetailAUTOVD+=  "				    <th><b>ExternalURL</th>"
    $DetailAUTOVD+=  "					</tr>"
 
 foreach($obj in $PWSVDS)
 {
    $DetailAUTOVD+=  "					<tr>"
    $DetailAUTOVD+=  "					<td><b>$($obj.Server)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.Name)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.CertificateAuthentication)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.RequireSSL)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.MetabasePath)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.Path)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.InternalURL)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.ExternalURL)</th>"
    $DetailAUTOVD+=  "					</tr>"
 }

$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderPWSVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - Powershell Virtual Directory</SPAN>
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