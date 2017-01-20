#===================================================================
# Database Availability Group - DatabaseCopy
#===================================================================
#write-Output "..Database Availability Group - DatabaseCopy"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderDatabase = "heading1"

$MDCSCSS = get-mailboxserver | where-object{$_.AdminDisplayVersion.major -eq "14" -AND $_.DatabaseAvailabilityGroup -ne $null} | Get-MailboxDatabaseCopyStatus -ConnectionStatus | ?{$_.activecopy -eq "True"}
$ClassHeaderConstatus = "heading1"
foreach($MDCSCS in $MDCSCSS)
{
		$MDCSN = $MDCSCS.Name
		$MDCSStatus = $MDCSCS.Status
		$MDCSDC = $MDCSCS.ActiveDatabaseCopy
		$MDCSAS = $MDCSCS.ActivationSuspended
		$MDCSOC = $MDCSCS.OutgoingConnections
	$DetailConstatus+=  "						<tr>"
    $DetailConstatus+=  "						<td width='25%'><font color='#0000FF'><b>$($MDCSN)</b></font></td>"	
    $DetailConstatus+=  "						<td width='15%'><font color='#0000FF'><b>$($MDCSStatus)</b></font></td>"	
    $DetailConstatus+=  "						<td width='15%'><font color='#0000FF'><b>$($MDCSDC)</b></font></td>"	
    $DetailConstatus+=  "						<td width='15%'><font color='#0000FF'><b>$($MDCSAS)</b></font></td>"	
    $DetailConstatus+=  "						<td width='30%'><font color='#0000FF'><b>$($MDCSOC)</b></font></td>"	
    $DetailConstatus+=  "						</tr>"
}
$MailboxDatabasesList = (Get-MailboxDatabase -status | where-object{$_.ReplicationType -eq "Remote"} | sort Name | Get-MailboxDatabaseCopyStatus)
 foreach($Database in $MailboxDatabasesList)
               {
                $Server = $Database.MailboxServer
                $DBName = $Database.DatabaseName
				$index = $Database.ContentIndexState
                $CopyQueueLength = $Database.CopyQueueLength
                $ReplayQueueLength = $Database.ReplayQueueLength
                $ActiveCopy = $Database.ActiveCopy.ToString()
                $ResultStatus = $Database.Status.ToString()
                if($CopyQueueLength -lt 10)
                           {
                       $Color2 = "#0000FF"
                           }
                else
                           {
                       $ClassHeaderDatabase = "heading10"
		       $Color2 = "#FF9900"
                           }
 
                if($ReplayQueueLength -lt 1)
                           {
                       $Color3 = "#0000FF"
                           }
                else
                           {
                       $ClassHeaderDatabase = "heading10"
		       $Color3 = "#FF9900"
                           }
    
                if(($ResultStatus -eq "Mounted") -or ($ResultStatus -eq "Healthy"))
                   {
                      $Color1 = "#0000FF"
                           }
                else
                           {
                      $ClassHeaderDatabase = "heading10"
		      $Global:Valid = 0
                      $Color1 = "#FF0000"
                           } 
             if($index -eq "Healthy")
                   {
                      $Color4 = "#0000FF"
                           }
                else
                           {
                      $ClassHeaderDatabase = "heading10"
					  $Global:Valid = 0
                      $Color4 = "#FF0000"
                           }      						   
 
            #$Error = $Database.Error
	$DetailDatabase+=" 					<tr>"
	$DetailDatabase+="  				<td width='20%'><font color='#0000FF'><b>$($server)</b></font></td>"
	$DetailDatabase+="					<td width='20%'><font color='#0000FF'><b>$($DBName)</b></font></td>"
	$DetailDatabase+="					<td width='15%'><font color='#0000FF'><b>$($ActiveCopy)</b></font></td>"
	$DetailDatabase+="					<td width='15%'><font color=$($Color1)><b>$($ResultStatus)</b></font></td>"
	$DetailDatabase+="					<td width='15%'><font color=$($Color2)><b>$($CopyQueueLength)</b></font></td>"
	$DetailDatabase+="					<td width='15%'><font color=$($Color3)><b>$($ReplayQueueLength)</b></font></td>"
	$DetailDatabase+="					<td width='15%'><font color=$($Color4)><b>$($index)</b></font></td>"
	$DetailDatabase+=" 					</tr>"
								}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderDatabase)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Mailbox Database Copy Status</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
			<table>
	  				<tr>
	  						<th width='25%'><b>Name</b></font></th>
							<th width='15%'><b>Status</b></font></th>
							<th width='15%'><b>ActiveDatabaseCopy</b></font></th>
							<th width='15%'><b>ActivationSuspended</b></font></th>
							<th width='30%'><b>OutgoingConnections</b></font></th>
					</tr>
             $($DetailConStatus)
             </table>
             <table>
	  				<tr>
	  						<br><th width='20%'><b>Server Name</b></font></th>
							<th width='20%'><b>Database Name</b></font></th>
	  						<th width='15%'><b>Active Copy</b></font></th>
	  						<th width='15%'><b>State</b></font></th>
							<th width='10%'><b>Copy Queue Length</b></font></th>
	  						<th width='10%'><b>Replay Queue Length</b></font></th>	
	  						<th width='10%'><b>Content Index State</b></font></th>						
	  				</tr>
                    $($DetailDatabase)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
Return $Report