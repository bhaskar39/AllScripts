#===================================================================
# Test Mailflow
#===================================================================
#Write-Output "..Test Mailflow"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$DB = (Get-MailboxDatabase -Status | Foreach{$_.MountedOnServer})
$ClassHeaderflow = "heading1"
 foreach($DBFlow in $DB)
             {
			    $Flow = $DBFlow | test-Mailflow
                $TMFR = $flow.TestMailflowresult
				$MLT = $flow.MessageLatencyTime
				$IRT = $flow.IsRemoteTest
				$IV = $flow.IsValid
            $Detailflow+=  "					<tr>"
			if ($TMFR -like "Success")
			{
			$ClassHeaderflow = "heading1"			
			$Detailflow+=  "						<td width='20%'><font color='#0000FF'><b>$($DbFlow)</b></font></td>"
			$Detailflow+=  "						<td width='20%'><font color='#0000FF'><b>$($TMFR)</b></font></td>" 
			$Detailflow+=  "						<td width='20%'><font color='#0000FF'><b>$($MLT)</b></font></td>"
			$Detailflow+=  "						<td width='20%'><font color='#0000FF'><b>$($IRT)</b></font></td>" 
			$Detailflow+=  "						<td width='15%'><font color='#0000FF'><b>$($IV)</b></font></td>"
			}
			else
			{
			$ClassHeaderflow = "heading10"
			$Detailflow+=  "						<td width='20%'><font color='#FF0000'><b>$($DbFlow)</b></font></td>"			
			$Detailflow+=  "						<td width='20%'><font color='#FF0000'><b>$($TMFR)</b></font></td>" 
			$Detailflow+=  "						<td width='20%'><font color='#FF0000'><b>$($MLT)</b></font></td>"
			$Detailflow+=  "						<td width='20%'><font color='#FF0000'><b>$($IRT)</b></font></td>" 
			$Detailflow+=  "						<td width='15%'><font color='#FF0000'><b>$($IV)</b></font></td>"		
			}

    $Detailflow+=  "					</tr>"
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderflow)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test Mailflow</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Server Name</b></font></th>
							<th width='20%'><b>TestMailflowResult</b></font></th>
	  						<th width='20%'><b>MessageLatencyTime</b></font></th>
	  						<th width='20%'><b>IsRemoteTest</b></font></th>
	  						<th width='15%'><b>IsValid</b></font></th>					
	  				</tr>
                    $($Detailflow)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
Return $Report