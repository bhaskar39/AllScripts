#===================================================================
# Active Directory Information
#===================================================================
#Write-Host "..Active Directory Information"
#start-Transcript -path .\ActiveDirectory.log -append
#$error.clear()
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
#if ($error[0])
#    {
#        write-host "Unable to load Exchange 2010 Snap-in"
#    }
$adsiteall = Get-ADSite
$ClassHeaderADS = "heading1"
foreach($ADSite in $ADSiteAll){
	$ADsiteName = $adsite.Name
	$ADSiteHub = $adsite.HubSiteEnabled
	$ADSitePI = $adsite.PartnerID
	$ADSiteMPI = $adsite.MinorPartnerID

    $Detailads+=  "					<tr>"
    $Detailads+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSiteName)</b></font></td>"
    $Detailads+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSiteHub)</b></font></td>"
    $Detailads+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSitePI)</b></font></td>"
    $Detailads+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSiteMPI)</b></font></td>"
    $Detailads+=  "					</tr>"
}

$adsitelinkall = Get-ADSitelink
$ClassHeaderADSlink = "heading1"
foreach($ADSitelink in $ADSitelinkAll){
	$ADSitelinkName = $adsitelink.Name
	$ADsitelinkcost = $adsitelink.ADCost
	$adsitelinkMMS = $adsitelink.MaxMessageSize
	$adsitelinkSite = $adsitelink.Sites

    $Detailadslink+=  "					<tr>"
    $Detailadslink+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSitelinkName)</b></font></td>"
    $Detailadslink+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSitelinkcost)</b></font></td>"
    $Detailadslink+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSitelinkMMS)</b></font></td>"
    $Detailadslink+=  "						<td width='40%'><font color='#0000FF'><b>$($ADSitelinksite)</b></font></td>"
    $Detailadslink+=  "					</tr>"
}
	
$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderads)'>
            <SPAN class=sectionTitle tabIndex=0>Active Directory Information</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>ADSite Name</b></font></th>
	  						<th width='20%'><b>HubSiteEnabled</b></font></th>
	  						<th width='20%'><b>PartnerID</b></font></th>
	  						<th width='20%'><b>MinorPartnerID</b></font></th>
	  				</tr>
                    $($Detailads)
                </table>
                <table>
	  				<tr><tr>
	  						<th width='20%'><b>ADSiteLink Name</b></font></th>
	  						<th width='20%'><b>ADCost</b></font></th>
	  						<th width='20%'><b>MaxMessageSize</b></font></th>
	  						<th width='40%'><b>Sites</b></font></th>
					</tr>

                    $($Detailadslink)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>
"@
Return $Report