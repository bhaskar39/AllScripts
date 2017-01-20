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
	$certs = Get-ExchangeCertificate -Server $allsrv -ErrorAction SilentlyContinue
	$DetailCert+=  "<tr bgcolor='#B2BEB5'>"	
	$DetailCert+=  "<th width='20%'><b>SERVER NAME </b></th><td><font color='#000080'>$($allsrv)</font></td>"
	$DetailCert+=  "</tr>"
		if($certs -eq $null)
	{
	$ClassHeadercert = "heading10"
	$DetailCert+=  "<tr>"	
	$DetailCert+=  "<th></th><td width='20%'><font color='#FF0000'><b>SERVER CANNOT BE CONTACTED</b></font></td>"
	$DetailCert+=  "</tr>"
	}
	else
	{
		foreach ($cert in $certs) 
		{
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
			
			#$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>AccessRules </b></th><td><font color='#0000FF'>$($certAR)</font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"
			$DetailCert+=  "					<th width='20%'><b>Certificate Domains </b></th><td><font color='#0000FF'>$($certdom) </font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>HasPrivateKey </b></th><td><font color='#0000FF'>$($certPK)</font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>IsSelfSigned </b></th><td><font color='#0000FF'>$($certssigned)</font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>Issuer </b></th><td><font color='#0000FF'>$($certIss)</font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>NotAfter </b></th><td><font color='#0000FF'>$($certNA)</font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>NotBefore </b></th><td><font color='#0000FF'>$($certNB)</font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>PublicKeySize </b></th><td><font color='#0000FF'>$($certPKS)</font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"
			$DetailCert+=  "					<th width='20%'><b>RootCAType </b></th><td><font color='#0000FF'>$($certRoot) </font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>SerialNumber </b></th><td><font color='#0000FF'>$($certSN)</font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>Services </b></th><td><font color='#0000FF'>$($certserv)</font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>Status </b></th><td><font color='#0000FF'>$($certstatus)</font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>Subject </b></th><td><font color='#0000FF'>$($certsubj)</font></td>"
			$DetailCert+=  "					</tr>"
			$DetailCert+=  "					<tr>"	
			$DetailCert+=  "					<th width='20%'><b>Thumbprint </b></th><td><font color='#0000FF'>$($certthumb)</font></td>"
			$DetailCert+=  "					</tr>"
		#	$DetailCert+=  "					<th width='20%'><b>______________________________________________________________________</b></font></th>"
		#	$DetailCert+=  "					<tr>"	
		}
	}
	#$DetailCert+=  "					<th width='20%'><b>______________________________________________________________________</b></font></th>"
	#$DetailCert+=  "					<tr>"	
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
                <table border=1>
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