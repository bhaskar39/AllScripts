#===================================================================
# Test Outlook Web Services
#===================================================================
#Write-Output "..Outlook Web Services"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderows = "heading1"
$OWSCAS = (Get-ExchangeServer | where{$_.adminDisplayversion.major -eq "14" -AND $_.ServerRole -like "ClientAccess*"})
foreach($TOWS in $OWSCAS)
               {
			    $OWSSrv = $TOWS.name
				$TOWS = Test-OutlookWebServices -ClientAccessServer $OWSSrv
				foreach($OWebS in $TOWS)
				{
				$OWebsID = $OWebs.ID
				$OWebsType = $OWebs.Type
				$OWebsMSG = $OWebs.Message
				if($OWebsType -eq "Error")
				{
			$ClassHeaderows = "heading10"	
			$Detailows+=  "					<tr>"
			$Detailows+=  "				        <td width='15%'><font color='#FF0000'><b>$($OWSSrv)</b></font></td>"			
			$Detailows+=  "						<td width='5%'><font color='#FF0000'><b>$($OWebsID)</b></font></td>"
			$Detailows+=  "						<td width='10%'><font color='#FF0000'><b>$($OWebsType)</b></font></td>" 
			$Detailows+=  "						<td width='70%'><font color='#FF0000'><b>$($OWebsMSG)</b></font></td>"
				}
				else
				{
			$ClassHeaderows = "heading1"					
            $Detailows+=  "					<tr>"
			$Detailows+=  "				        <td width='15%'><font color='#0000FF'><b>$($OWSSrv)</b></font></td>"			
			$Detailows+=  "						<td width='5%'><font color='#0000FF'><b>$($OWebsID)</b></font></td>"
			$Detailows+=  "						<td width='10%'><font color='#0000FF'><b>$($OWebsType)</b></font></td>" 
			$Detailows+=  "						<td width='70%'><font color='#0000FF'><b>$($OWebsMSG)</b></font></td>"
				}
			
			}
            $Detailows+=  "					<tr>"				
			$Detailows+=  "					<th width='100%'><b>____________________________________________________________________________________________________________________________________________</b></font></th>"				
			$Detailows+=  "					</tr>"
}


$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderows)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test Outlook WebServices</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='15%'><b>Server Name</b></font></th>					
	  						<th width='5%'><b>ID</b></font></th>
							<th width='10%'><b>Type</b></font></th>
	  						<th width='70%'><b>Message</b></font></th>
	  				</tr>
                    $($Detailows)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report