#===================================================================
# Hardware information
#===================================================================
#write-Output "..Hardware Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$Allsrvs = Get-ExchangeServer | Where-Object{$_.ServerRole -ne "Edge"}
$ClassHeadercs = "heading1"
foreach ($allsrv in $allsrvs){
   $query = "Select * from Win32_pingstatus where address = '$allsrv'"
   $result = Get-WmiObject -query $query
   if ($result.protocoladdress){ 
	$Csall = Get-WmiObject -ComputerName $allsrv Win32_ComputerSystem -NameSpace "ROOT/CIMV2"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>SERVER NAME : <font color='#000080'>$($allsrv)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
		foreach ($cs in $Csall) {
		$csdom = $cs.domain
		$csManu = $cs.manufacturer
		$csModel = $cs.Model
		$csST = $cs.SystemType
		$csRole = $cs.Roles
		$csPON = $cs.PrimaryOwnerName
		$csTPM = [math]::round(($cs.TotalPhysicalMemory/ 1073741824),2)
		$csCTZ = $cs.CurrentTimeZone
		$csEDST = $cs.EnableDayLightSavingsTime
		
    $Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>Domain : </font><font color='#0000FF'>$($csdom)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"
	$Detailcs+=  "					<th width='20%'><b>Manufacturer : </font><font color='#0000FF'>$($csmanu)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>Model : </font><font color='#0000FF'>$($csModel)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>SystemType : </font><font color='#0000FF'>$($csST)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>Roles : </font><font color='#0000FF'>$($csRole)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>PrimaryOnwerName : </font><font color='#0000FF'>$($csPON)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>TotalPhysicalMemory : </font><font color='#0000FF'>$($csTPM) GB</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>CurrentTimeZone : </font><font color='#0000FF'>$($csCTZ)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>EnableDayLightSavingTime : </font><font color='#0000FF'>$($csEDST)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	}
	$Procall = Get-WmiObject -ComputerName $allsrv Win32_Processor -NameSpace "ROOT/CIMV2"
		foreach ($Proc in $Procall) {
		$Procver = $Proc.caption
		$ProcName = $Proc.Name
		$ProcNOC = $Proc.NumberOfCores
		$ProcNOLP = $Proc.NumberOfLogicalProcessors
    $Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>Caption : </font><font color='#0000FF'>$($Procver)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"
	$Detailcs+=  "					<th width='20%'><b>Name : </font><font color='#0000FF'>$($Procname)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"
	$Detailcs+=  "					<th width='20%'><b>NumberOfCores : </font><font color='#0000FF'>$($ProcNOC)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>NumberOfLogicalProcessors : </font><font color='#0000FF'>$($ProcNOLP)</b></font></td></th>"
}
	$Biosall = Get-WmiObject -ComputerName $allsrv Win32_Bios -NameSpace "ROOT/CIMV2"
		foreach ($Bios in $Biosall) {
		$biosver = $bios.Version
		$biosdesc = $bios.Description
		$biosManu = $bios.manufacturer
		$biosName = $bios.Name
		$biosSN = $bios.SerialNumber
		$biosLang = $bios.listofLanguages
    $Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>BIOS Version : </font><font color='#0000FF'>$($biosver)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"
	$Detailcs+=  "					<th width='20%'><b>Description : </font><font color='#0000FF'>$($biosdesc)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"
	$Detailcs+=  "					<th width='20%'><b>Manufacturer : </font><font color='#0000FF'>$($biosmanu)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>Name : </font><font color='#0000FF'>$($biosName)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>SerialNumber : </font><font color='#0000FF'>$($biosSN)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>ListOfLanguages : </font><font color='#0000FF'>$($biosLang)</b></font></td></th>"
}

	$Detailcs+=  "					</tr>"	
	$Detailcs+=  "					<th width='20%'><b>______________________________________________________________________</b></font></th>"
	$Detailcs+=  "					<tr>"
}
   else
    {
    $ClassHeadercs = "heading10"
    $Detailcs+=  "					<tr>"
    $Detailcs+=  "					<th width='20%'><b>SERVER NAME : <font color='#FF0000'>$($allsrv)</b></font></td></th>"
    $Detailcs+=  "					</tr>"
    }

}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeadercs)'>
            <SPAN class=sectionTitle tabIndex=0>Hardware Informations (Bios, System, Processor)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>

 		   		</tr>
                $($Detailcs)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>
"@
Return $Report