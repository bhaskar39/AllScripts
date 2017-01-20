#===================================================================
# Database Availability Group - Backup
#===================================================================
#write-Output "..Database Availability Group - Backup"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderDb = "heading1"
$DbList = Get-MailboxDatabase -Status | where {$_.Recovery -eq $False -AND $_.ReplicationType -eq "Remote"} | sort Server
foreach ($Db in $DbList)
        {
            $DbServer = $Db.Server
            $DbLastFullBackup = $Db.LastFullBackup
            $DbIdentity  = $Db.Identity
			$DbLastIB = $Db.LastIncrementalBackup
			$DbLastDB = $Db.LastDifferentialBackup
			$DbLastCB = $Db.LastCopyBackup
 #           $FreeSpaceinDB = "{0:N2}" -f ($DB.AvailableNewMailboxSpace.ToBytes() / 1MB)
 #           $DbSize = "{0:N2}" -f ($DB.DatabaseSize.ToBytes() / 1GB)
    $DetailDb+=  "					<tr>"
    $DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbServer)</b></font></td>"
    $DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbIdentity)</b></font></td>"
    $DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbLastIB)</b></font></td>"
    $DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbLastDB)</b></font></td>"
    $DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbLastCB)</b></font></td>"	
    if($DbLastFullBackup -eq $null)
    {
    $ClassHeaderDb = "heading10"       
	$DetailDb+=  "					<td width='15%'><font color='#FF0000'><b>Never Backuped</b></font></td>"
    $Global:Valid = 0
    }
    else
    {
	$DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbLastFullBackup)</b></font></td>"
	
              if($DbLastFullBackup -gt (Get-Date).adddays(-1))
               {
			   $DetailDb+=  "			<td width='10%'><font color='#0000FF'><b>Valid</b></font></td>"
			   }
               else
               {
                    if($DbLastFullBackup -gt (Get-Date).adddays(-2))
                    {
					$ClassHeaderDb = "heading10" 					 
					$DetailDb+=  "						<td width='10%'><font color='#FF9900'><b>One Day Old</b></font></td>"                       
                    $Global:Valid = 0
                    }
                    else
                    {
					$ClassHeaderDb = "heading10"  
					$DetailDb+=  "						<td width='10%'><font color='#FF0000'><b>More Than 2 Days</b></font></td>"                          
                    $Global:Valid = 0
                    }
                }
    }
				$DetailDb+=  "					</tr>"  
	}

foreach ($Db in $DbList)
        {
            $DbServer = $Db.Server
            $DbSLastFB = $Db.SnapshotLastFullBackup
            $DbIdentity  = $Db.Identity
			$DbSLastIB = $Db.SnapshotLastIncrementalBackup
			$DbSLastDB = $Db.SnapshotLastDifferentialBackup
			$DbSLastCB = $Db.SnapshotLastCopyBackup

    $DetailSDb+=  "					<tr>"
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbServer)</b></font></td>"
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbIdentity)</b></font></td>"
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbSLastIB)</b></font></td>"
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbSLastDB)</b></font></td>"
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbSLastCB)</b></font></td>"	
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbSLastFB)</b></font></td>"	
    $DetailSDb+=  "						<td width='10%'><font color='#0000FF'><b> </b></font></td>"		
	$DetailSDb+=  "					</tr>" 	
}	
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderDb)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Databases Backup Status</SPAN>
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
                    $($DetailDb)
                </table>
               <table>
	  				<tr>
	  						<br><th width='15%'><b>Server Name</b></font></th>
							<th width='15%'><b>Database Name</b></font></th>
	  						<th width='15%'><b>SnapshotLastIncrementalBackup</b></font></th>
	  						<th width='15%'><b>SnapshotLastDifferentialBackup</b></font></th>
	  						<th width='15%'><b>SnapshotLastCopyBackup</b></font></th>							
	  						<th width='15%'><b>SnapshotLastFullBackup</b></font></th>	
	  						<th width='10%'><b> </b></font></th>								
	  				</tr>
                    $($DetailSDb)
                </table>				
            </div>
        </div>
        <div class='filler'></div>
    </div>                     
"@
Return $Report