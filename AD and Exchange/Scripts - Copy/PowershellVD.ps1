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
$PWSVDS = Get-ClientAccessServer | Get-PowershellVirtualDirectory
$ClassHeaderPWSVD = "heading1"
foreach ($PWSVD in $PWSVDS){
		$PWSrv = $PWSVD.server
		$PWName = $PWSVD.name
		$PWCE = $PWSVD.CertificateAuthentication
		$PWSSL = $PWSVD.RequireSSL	
		$PWM = $PWSVD.MetabasePath
		$PWP = $PWSVD.Path		
		$PWIURL = $PWSVD.InternalURL		
		$PWEURL = $PWSVD.ExternalURL
		
    $DetailPWSVD+=  "					<tr>"
    $DetailPWSVD+=  "					<th width='10%'><b>Server : <font color='#0000FF'>$($PWSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($PWName)</font><th width='10%'>CertificateAuthentication : <font color='#0000FF'>$($PWCE)</b></font></td></th>"
    $DetailPWSVD+=  "					</tr>"
	$DetailPWSVD+=  "					<tr>"	
    $DetailPWSVD+=  "					<th width='10%'><b>RequireSSL : <font color='#0000FF'>$($PWSSL)</font><th width='10%'>MetabasePath : <font color='#0000FF'>$($PWM)</font><th width='10%'>Path : <font color='#0000FF'>$($PWP)</b></font></td></th>"	
    $DetailPWSVD+=  "					</tr>"
	$DetailPWSVD+=  "					<tr>"	
    $DetailPWSVD+=  "					<th width='10%'><b>InternalUrl : <font color='#0000FF'>$($PWIURL)</b><th width='10%'>ExternalUrl : <font color='#0000FF'>$($PWEURL)</font></td></th>"	
    $DetailPWSVD+=  "					</tr>"
	$DetailPWSVD+=  "					<tr>"	
	$DetailPWSVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"
	$DetailPWSVD+=  "					</tr>"
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
                <table>
	  			<tr>
							
 		   		</tr>
                    $($DetailPWSVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report