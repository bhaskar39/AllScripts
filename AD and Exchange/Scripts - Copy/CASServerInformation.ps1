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
$CASarrays = Get-ClientAccessArray
$ClassHeaderCASarray = "heading1"
foreach($CASarray in $CASarrays) 
{
		$name = $CASArray.name
		$site = $CASArray.site
		$fqdn = $CASArray.fqdn
		$memb = $CASArray.members
    $DetailCASArray+=  "					<tr>"
    $DetailCASArray+=  "						<td width='15%'><font color='#0000FF'><b>$($name)</b></font></td>"
    $DetailCASArray+=  "						<td width='25%'><font color='#0000FF'><b>$($site)</b></font></td>"
    $DetailCASArray+=  "						<td width='20%'><font color='#0000FF'><b>$($fqdn)</b></font></td>"
    $DetailCASArray+=  "						<td width='20%'><font color='#0000FF'><b>$($memb)</b></font></td>"	
    $DetailCASArray+=  "					</tr>"
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
                <table>
	  				<tr>
	  						<th width='15%'><b>Name</b></font></th>
							<th width='25%'><b>Site</b></font></th>
	  						<th width='20%'><b>FQDN</b></font></th>
	  						<th width='20%'><b>Members</b></font></th>							
	  				</tr>
                    $($DetailCASArray)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

$casuri = Get-ClientAccessServer
$ClassHeaderCASauto = "heading1"
		Foreach ($cas in $casuri)
		{
    $DetailCASAuto+=  "					<tr>"
    $DetailCASAuto+=  "						<td width='20%'><font color='#0000FF'><b>$($cas.name)</b></font></td>"
    $DetailCASAuto+=  "						<td width='40%'><font color='#0000FF'><b>$($cas.AutoDiscoverServiceInternalUri)</b></font></td>"
    $DetailCASAuto+=  "						<td width='20%'><font color='#0000FF'><b>$($cas.AutoDiscoverSiteScope)</b></font></td>"	
    $DetailCASAuto+=  "						<td width='20%'><font color='#0000FF'></font></td>"    
    $DetailCASAuto+=  "					</tr>"
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
                <table>
	  				<tr>
	  					<th width='20%'><b>Server Name</b></font></th>
	  					<th width='40%'><b>AutoDiscoverServiceInternalUri</b></font></th>
						<th width='20%'><b>AutoDiscoverSiteScope</b></font></th>
                        <td width='20%'><font color='#0000FF'></font></td>						
	  				</tr>
                    $($DetailCASauto)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              

"@
Return $Report