#===================================================================
# Mailbox Server - OfflineAddressBook
#===================================================================
#write-Output "..OfflineAddressBook"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$OABS = Get-OfflineAddressBook
$ClassHeaderOAB = "heading1"
foreach ($OAB in $OABS){
		$OBSrv = $OAB.server
		$OBName = $OAB.Name		
		$OBAL = $OAB.AddressLists
		$OBVer = $OAB.Versions
		$OBID = $OAB.IsDefault		
		$OBPFD = $OAB.PublicFolderDatabase
		$OBPFDE = $OAB.PublicFolderDistributionEnabled
		$OBVD = $OAB.VirtualDirectories		
		
    $DetailOAB+=  "					<tr>"
    $DetailOAB+=  "					<th width='10%'>Server Name : <font color='#0000FF'>$($OBSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($OBName)</font><th width='10%'>AddressLists : <font color='#0000FF'>$($OBAL)</font></td></th>"
    $DetailOAB+=  "					</tr>"
    $DetailOAB+=  "					<tr>"
    $DetailOAB+=  "					<th width='10%'>Versions : <font color='#0000FF'>$($OBVer)</font><th width='10%'>IsDefaut : <font color='#0000FF'>$($OBID)</font><th width='10%'>PublicFolderDatabase : <font color='#0000FF'>$($OBPFD)</font></td></th>"
    $DetailOAB+=  "					</tr>"
    $DetailOAB+=  "					<tr>"
    $DetailOAB+=  "					<th width='10%'>PublicFolderDistributionEnabled : <font color='#0000FF'>$($OBPFDE)</font><th width='10%'>VirtualDirectories : <font color='#0000FF'>$($OBVD)</font></td></th>"
    $DetailOAB+=  "					</tr>"
    $DetailOAB+=  "					<tr>"
	$DetailOAB+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailOAB+=  "					</tr>"	
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderOAB)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox server - Offline Address Book</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
							
 		   		</tr>
                    $($DetailOAB)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report