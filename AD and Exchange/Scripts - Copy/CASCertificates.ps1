#===================================================================
# Client Access Server - Exchange Certificates
#===================================================================
#write-Output "..Client Access Server - Exchange Certificates"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$Allsrvs = Get-ExchangeServer | where{($_.AdminDisplayVersion.Major -gt "8") -AND ($_.ServerRole -ne "Edge")}
$ClassHeadercert = "heading1"
foreach ($allsrv in $allsrvs){
	$certs = Get-ExchangeCertificate -Server $allsrv
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>SERVER NAME : </b></font><font color='#000080'>$($allsrv)</font></td></th>"
	$DetailCert+=  "					</tr>"
		if($certs -eq $null)
	{
	$ClassHeadercert = "heading10"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<td width='20%'><font color='#FF0000'><b>SERVER CANNOT BE CONTACTED</b></font></td>"
	$DetailCert+=  "					</tr>"
	}
	else
	{
		foreach ($cert in $certs) {
		$certthumb = $cert.Thumbprint
		$CertDom = $cert.CertificateDomains
		$certserv = $cert.services
		$certAR = $cert.AccessRules
		$certPK = $cert.HasPrivatekey
		$certSSigned = $cert.IsSelfSigned
		$certIss = $cert.Issuer
		$certNA = $cert.NotAfter
		$certNB = $cert.NotBefore
		$certPKS = $cert.PublicKeySize
		$certRoot = $cert.RootCAType
		$certSN = $cert.SerialNumber
		$certstatus = $cert.status
		$certsubj = $cert.subject
    $DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>AccessRules : </b></font><font color='#0000FF'>$($certAR)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"
	$DetailCert+=  "					<th width='20%'><b>Certificate Domains : </b></font><font color='#0000FF'>$($certdom) </font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>HasPrivateKey : </b></font><font color='#0000FF'>$($certPK)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>IsSelfSigned : </b></font><font color='#0000FF'>$($certssigned)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>Issuer : </b></font><font color='#0000FF'>$($certIss)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>NotAfter : </b></font><font color='#0000FF'>$($certNA)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>NotBefore : </b></font><font color='#0000FF'>$($certNB)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>PublicKeySize : </b></font><font color='#0000FF'>$($certPKS)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"
	$DetailCert+=  "					<th width='20%'><b>RootCAType : </b></font><font color='#0000FF'>$($certRoot) </font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>SerialNumber : </b></font><font color='#0000FF'>$($certSN)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>Services : </b></font><font color='#0000FF'>$($certserv)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>Status : </b></font><font color='#0000FF'>$($certstatus)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>Subject : </b></font><font color='#0000FF'>$($certsubj)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>Thumbprint : </b></font><font color='#0000FF'>$($certthumb)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<th width='20%'><b>______________________________________________________________________</b></font></th>"
	$DetailCert+=  "					<tr>"	
	}
	}
	$DetailCert+=  "					<th width='20%'><b>______________________________________________________________________</b></font></th>"
	$DetailCert+=  "					<tr>"	
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeadercert)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - Exchange Certificates</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>

 		   		</tr>
                    $($Detailcert)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
"@
Return $Report