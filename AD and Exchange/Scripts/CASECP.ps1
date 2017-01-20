#===================================================================
# Client Access Server - ECP Virtual Directory
#===================================================================
#write-Output "..Client Access Server - ECP Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ECPVDS = Get-ClientAccessServer | Get-ECPVirtualDirectory | Select Server,Name,InternalURL,InternalAuthenticationMethods,ExternalURL,ExternalAuthenticationMethods
$ClassHeaderECPVD = "heading1"

    $DetailECPVD+=  "<tr bgcolor='#B2BEB5'>"
    $DetailECPVD+=  "<th><b>Server Name</th>"
    $DetailECPVD+=  "<th><b>Name</th>"
    $DetailECPVD+=  "<th><b>InternalURL</th>"
    $DetailECPVD+=  "<th><b>InternalAuthenticationMethods</th>"
    $DetailECPVD+=  "<th><b>ExternalURL</th>"
    $DetailECPVD+=  "<th><b>ExternalAuthenticationMethods</th>"
    $DetailECPVD+=  "</tr>"	
foreach($ec in $ECPVDS)
{
    $DetailECPVD+=  "<tr>"
    $DetailECPVD+=  "<td><b>$($ec.Server)</td>"
    $DetailECPVD+=  "<td><b>$($ec.Name)</td>"
    $DetailECPVD+=  "<td><b>$($ec.InternalURL)</td>"
    $DetailECPVD+=  "<td><b>$($ec.InternalAuthenticationMethods)</td>"
    $DetailECPVD+=  "<td><b>$($ec.ExternalURL)</td>"
    $DetailECPVD+=  "<td><b>$($ec.ExternalAuthenticationMethods)</td>"
    $DetailECPVD+=  "</tr>"	
}
$Report += @"
	</TABLE>
    <div class='container'>
        <div class='$($ClassHeaderECPVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - ECP Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table border=1>
                    $DetailECPVD
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report