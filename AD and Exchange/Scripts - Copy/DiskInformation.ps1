#===================================================================
# Disk Report Information
#===================================================================
#Write-Output "..Logical Disk & MountPoint Report Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ALLSRVLIST = get-exchangeserver | Where-Object{$_.ServerRole -ne "Edge"}
$ClassHeaderObjDisk = "heading1"
foreach ($SRVLIST in $allSRVLIST){
   $query = "Select * from Win32_pingstatus where address = '$SRVLIST'"
   $result = Get-WmiObject -query $query
   if ($result.protocoladdress){ 
foreach ($SRV in $SRVLIST)
 {
     $DetailObjDisk+=  "					<tr>"
     $DetailObjDisk+=  "					<th width='20%'><b>SERVER NAME : <font color='#0000FF'>$($srv)</b></font></th>"
 $colDisks = Get-WmiObject -computer $srv win32_volume | Where-object {$_.DriveLetter -ne $null -OR $_.Capacity -ne $null -AND $_.FileSystem -like "NTFS"} | sort-object Caption
Foreach ($objDisk in $colDisks)
	{

    $DetailObjDisk+=  "					<tr>"
    $DetailObjDisk+=  "						<td width='20%'><font color='#0000FF'><b>$($objDisk.Label)</b></font></td>"
    $DetailObjDisk+=  "						<td width='10%'><font color='#0000FF'><b>$($objDisk.Caption)</b></font></td>"
	$DetailObjDisk+=  "						<td width='20%'><font color='#0000FF'><b>$($objDisk.FileSystem)</b></font></td>"
	$disksize = [math]::round(($objDisk.Capacity/ 1073741824),2) 
	$DetailObjDisk+=  "						<td width='15%'><font color='#0000FF'><b>$disksize GB</b></font></td>"
	$freespace = [math]::round(($objDisk.FreeSpace / 1073741824),2)	
	$DetailObjDisk+=  " 						<td width='15%'><font color='#0000FF'><b>$Freespace GB</b></font></td>"
	if ($disksize -eq 0){
		$ClassHeaderObjDisk = "heading10"
		$percFreespace = "0"
			}
	Else{
		$percFreespace=[math]::round(((($objDisk.FreeSpace / 1073741824)/($objdisk.Capacity / 1073741824)) * 100),0)		
		}
		if ($percFreespace -lt "20")
		{
		$ClassHeaderObjDisk = "heading10"
		$DetailObjDisk+=  "						<td width='15%'><font color='#FF0000'><b>$percFreespace%</b></font></td>"
		}
		else {
		$DetailObjDisk+=  "						<td width='15%'><font color='#0000FF'><b>$percFreespace%</b></font></td>"
		}

	}
    $DetailObjDisk+=  "					<td width='15%'><font color='#FF0000'> </font></td>"
    $DetailObjDisk+=  "					</tr>"
}
}
   else
    {
    $ClassHeaderObjDisk = "heading10"
    $DetailObjDisk+=  "					<tr>"
    $DetailObjDisk+=  "					<th width='20%'><b>SERVER NAME : <font color='#FF0000'>$($SRVLIST)</b></font></td></th>"
    $DetailObjDisk+=  "					</tr>"
    }	
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderObjDisk)'>
            <SPAN class=sectionTitle tabIndex=0>Logical Disk & MountPoint Report</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
					<tr>
							<th width='20%'><b>Label</b></font></th>
	  						<th width='10%'><b>Drive Letter</b></font></th>
	  						<th width='20%'><b>File System</b></font></th>
	  						<th width='15%'><b>Disk Size</b></font></th>
	  						<th width='15%'><b>Disk Free Space</b></font></th>
	  						<th width='15%'><b>% Free Space</b></font></th>						
	  				</tr>
                    $($DetailObjDisk)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>    

"@
Return $Report