#===================================================================
# Client Access Server - OAB Virtual Directory
#===================================================================
#write-Output "..Client Access Server - OAB Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$OABVDS = Get-ClientAccessServer | Get-OABVirtualDirectory | Select Server,Name,InternalURL,InternalAuthenticationMethods,ExternalURL,ExternalAuthenticationMethods
$ClassHeaderOABVD = "heading1"

    $DetailAUTOVD+=  "					<tr bgcolor='#B2BEB5'>"
    $DetailAUTOVD+=  "					<th><b>Server Name</th>"
    $DetailAUTOVD+=  "				    <th><b>Name</th>"
    $DetailAUTOVD+=  "				    <th><b>InternalURL</th>"
    $DetailAUTOVD+=  "				    <th><b>InternalAuthenticationMethods</th>"
    $DetailAUTOVD+=  "				    <th><b>ExternalURL</th>"
    $DetailAUTOVD+=  "				    <th><b>ExternalAuthenticationMethods</th>"
    $DetailAUTOVD+=  "					</tr>"
 
 foreach($obj in $OABVDS)
 {
    $DetailAUTOVD+=  "					<tr>"
    $DetailAUTOVD+=  "					<td><b>$($obj.Server)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.Name)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.InternalURL)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.InternalAuthenticationMethods)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.ExternalURL)</th>"
    $DetailAUTOVD+=  "				    <td><b>$($obj.ExternalAuthenticationMethods)</th>"
    $DetailAUTOVD+=  "					</tr>"
 }

$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderOABVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - OAB Virtual Directory</SPAN>
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