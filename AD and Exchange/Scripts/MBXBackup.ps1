#===================================================================
# Mailbox Server - Backup
#===================================================================
# write-Output "..Mailbox Server - Backup"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderMBXBK = "heading1"
$MBXBKList = Get-MailboxDatabase -Status | where {$_.Recovery -eq $False -AND $_.ReplicationType -ne "Remote"} | sort Server
foreach ($MBXBK in $MBXBKList)
        {
            $MBXBKServer = $MBXBK.Server
            $MBXBKLastFullBackup = $MBXBK.LastFullBackup
            $MBXBKIdentity  = $MBXBK.Identity
			$MBXBKLastIB = $MBXBK.LastIncrementalBackup
			$MBXBKLastDB = $MBXBK.LastDifferentialBackup
			$MBXBKLastCB = $MBXBK.LastCopyBackup
    $DetailMBXBK+=  "					<tr>"
    $DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKServer)</b></font></td>"
    $DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKIdentity)</b></font></td>"
    $DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKLastIB)</b></font></td>"
    $DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKLastDB)</b></font></td>"
    $DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKLastCB)</b></font></td>"	
    if($MBXBKLastFullBackup -eq $null)
    {
    $ClassHeaderMBXBK = "heading10"       
	$DetailMBXBK+=  "					<td width='15%'><font color='#FF0000'><b>Never Backuped</b></font></td>"
    $Global:Valid = 0
    }
    else
    {
	$DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKLastFullBackup)</b></font></td>"
	
              if($MBXBKLastFullBackup -gt (Get-Date).adddays(-1))
               {
			   $DetailMBXBK+=  "			<td width='10%'><font color='#0000FF'><b>Valid</b></font></td>"
			   }
               else
               {
                    if($MBXBKLastFullBackup -gt (Get-Date).adddays(-2))
                    {
					$ClassHeaderMBXBK = "heading10" 					 
					$DetailMBXBK+=  "						<td width='10%'><font color='#FF9900'><b>One Day Old</b></font></td>"                       
                    $Global:Valid = 0
                    }
                    else
                    {
					$ClassHeaderMBXBK = "heading10"  
					$DetailMBXBK+=  "						<td width='10%'><font color='#FF0000'><b>More Than 2 Days</b></font></td>"                          
                    $Global:Valid = 0
                    }
                }
    }
				$DetailMBXBK+=  "					</tr>"  
	}

foreach ($MBXBK in $MBXBKList)
        {
            $MBXBKServer = $MBXBK.Server
            $MBXBKSLastFB = $MBXBK.SnapshotLastFullBackup
            $MBXBKIdentity  = $MBXBK.Identity
			$MBXBKSLastIB = $MBXBK.SnapshotLastIncrementalBackup
			$MBXBKSLastDB = $MBXBK.SnapshotLastDifferentialBackup
			$MBXBKSLastCB = $MBXBK.SnapshotLastCopyBackup
    $DetailMBXBKS+=  "					<tr>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKServer)</b></font></td>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKIdentity)</b></font></td>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKSLastIB)</b></font></td>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKSLastDB)</b></font></td>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKSLastCB)</b></font></td>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKSLastFB)</b></font></td>"
	$DetailMBXBKS+=  "					</tr>"  	
}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderMBXBK)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox Server - Databases Backup Status</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='15%'><b>Server Name</b></font></th>
							<th width='15%'><b>Database Name</b></font></th>
	  						<th width='15%'><b>LastIncrementalBackup</b></font></th>
	  						<th width='15%'><b>LastDifferentialBackup</b></font></th>
	  						<th width='15%'><b>LastCopyBackup</b></font></th>							
	  						<th width='15%'><b>LastFullBackup</b></font></th>							
	  						<th width='10%'><b>Backup Validity</b></font></th>					
	  				</tr>
                    $($DetailMBXBK)
                </table>
               <table>
	  				<tr>
	  						<br><th width='15%'><b>Server Name</b></font></th>
							<th width='15%'><b>Database Name</b></font></th>
	  						<th width='15%'><b>SnapshotLastIncrementalBackup</b></font></th>
	  						<th width='15%'><b>SnapshotLastDifferentialBackup</b></font></th>
	  						<th width='15%'><b>SnapshotLastCopyBackup</b></font></th>							
	  						<th width='15%'><b>SnapshotLastFullBackup</b></font></th>							
	  				</tr>
                    $($DetailMBXBKS)
                </table>				
            </div>
        </div>
        <div class='filler'></div>
    </div>                     
"@
Return $Report