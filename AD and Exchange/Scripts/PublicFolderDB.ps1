#===================================================================
# Public Folder Database
#===================================================================
#write-Output "..Public Folder Database"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$PFDall = Get-ExchangeServer |where-object{$_.serverrole -eq "none" -OR $_.serverrole -like "*mailbox*"} | Get-PublicFolderDatabase -Status | where-Object{$_.PublicFolderHierarchy -eq "Public Folders"}

$ClassHeaderPFD = "heading1"
foreach ($PFD in $PFDall){
		$PFSrv = $PFD.server
		$PFName = $PFD.name
		$PFMIS = $PFD.MaxItemSize
		$PFPPQ = $PFD.ProhibitPostQuota
		$PFRMS = $PFD.ReplicationMessageSize
		$PFUCRSL = $PFD.UseCustomReferralServerList		
		$PFCRSL = $PFD.CustomReferralServerList
		$PFAG = $PFD.AdministrativeGroup
		$PFAP = $PFD.ActivationPreference
		$PFDBS = $PFD.DatabaseSize
		$PFANMS = $PFD.AvailableNewMailboxSpace
		$PFLFB = $PFD.LastFullBackup
		$PFDIR = $PFD.DeletedItemRetention
		
    $DetailPFD+=  "					<tr>"
    $DetailPFD+=  "					<th width='10%'><b>Server : <font color='#0000FF'>$($PFSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($PFName)</font><th width='10%'>MaxItemSize : <font color='#0000FF'>$($PFMIS)</b></font></td></th>"
    $DetailPFD+=  "					</tr>"
	$DetailPFD+=  "					<tr>"	
    $DetailPFD+=  "					<th width='10%'><b>ProhibitPostQuota : <font color='#0000FF'>$($PFPPQ)</font><th width='10%'>ReplicationMessageSize : <font color='#0000FF'>$($PFRMS)</font><th width='10%'>UseCustomReferralServerList : <font color='#0000FF'>$($PFUCRSL)</b></font></td></th>"	
    $DetailPFD+=  "					</tr>"
	$DetailPFD+=  "					<tr>"	
    $DetailPFD+=  "					<th width='10%'><b>CustomReferralServerList : <font color='#0000FF'>$($PFCRSL)</font><th width='10%'>DeletedItemRetention : <font color='#0000FF'>$($PFDIR)</font><th width='10%'>ActivationPreference : <font color='#0000FF'>$($PFAP)</b></font></td></th>"	
    $DetailPFD+=  "					</tr>"
	$DetailPFD+=  "					<tr>"	
    $DetailPFD+=  "					<th width='10%'><b>DatabaseSize : <font color='#0000FF'>$($PFDBS)</font><th width='10%'>AvailableNewMailboxSpace : <font color='#0000FF'>$($PFANMS)</font><th width='10%'>LastFullBackup : <font color='#0000FF'>$($PFLFB)</b></font></td></th>"	
    $DetailPFD+=  "					</tr>"
	$DetailPFD+=  "					<tr>"	
    $DetailPFD+=  "					<th width='30%'><b>AdministrativeGroup : <font color='#0000FF'>$($PFAG)</b></font></td></th>"	
    $DetailPFD+=  "					</tr>"	
	$DetailPFD+=  "					<tr>"	
	$DetailPFD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"
	$DetailPFD+=  "					</tr>"
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderPFD)'>
            <SPAN class=sectionTitle tabIndex=0>Public Folder Databases</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>

 		   		    </tr>
                    $($DetailPFD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report