#===================================================================
# Exchange Rollup (Edge server excluded)
#===================================================================
#write-Output "..Exchange Servers Rollup (E2K7 Only)"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$MsxServers = Get-ExchangeServer | where {$_.ServerRole -ne "Edge" -AND $_.AdminDisplayVersion.major -eq "8"} | sort Name
$ClassHeaderRollup = "heading1"
#Loop through each Exchange server that is found

if ($MsxServers -ne $NULL)
{
ForEach ($MsxServer in $MsxServers)
{
   
   	#Get Exchange server version
	$MsxVersion = $MsxServer.ExchangeVersion

	#Create "header" string for output
	$Srv = $MsxServer.Name
 
    $DetailRollup+=  "					<tr>"
    $DetailRollup+=  "					<th width='10%'><b>SERVER NAME : </b><font color='#0000FF'>$($Srv)</font></td>"

 
    
	$key = "SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\461C2B4266EDEF444B864AD6D9E5B613\Patches\"
	$type = [Microsoft.Win32.RegistryHive]::LocalMachine
	$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Srv)
	$regKey = $regKey.OpenSubKey($key)

     if ($regKey.SubKeyCount -eq 0)
    {
               $DetailRollup+=  "						<tr><td width='10%'><font color='#FF0000'><b>NO ROLLUP INSTALLED</b></font></td><tr>"
    }
    else
    {
	#Loop each of the subkeys (Patches) and gather the Installed date and Displayname of the Exchange 2007 patch
	$ErrorActionPreference = "SilentlyContinue"

	ForEach($sub in $regKey.GetSubKeyNames())
	{
		$SUBkey = $key + $Sub
		$SUBregKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Srv)
		$SUBregKey = $SUBregKey.OpenSubKey($SUBkey)

		ForEach($SubX in $SUBRegkey.GetValueNames())
		{
			# Display Installed date and Displayname of the Exchange 2007 patch
			IF ($Subx -eq "Installed")   {
				$d = $SUBRegkey.GetValue($SubX)
				$d = $d.substring(4,2) + "/" + $d.substring(6,2) + "/" + $d.substring(0,4)
			}
			IF ($Subx -eq "DisplayName") {
            $cd = $SUBRegkey.GetValue($SubX)
            $DetailRollup+=  "						<tr><td width='10%'><b>Rollup Version : <font color='#0000FF'>$($d) - $($cd)</b></font></td><tr>"
            }
		}
	}
           $DetailRollup+=  "					<tr>"
}
    $DetailRollup+=  "					</tr>"
}
	
$Report += @"
	</TABLE>
	    <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderRollup)'>
            <SPAN class=sectionTitle tabIndex=0>Exchange Servers Rollup (E2K7 Only)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
                         
	  				</tr>
                    $($DetailRollup)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>	
"@
}
else
{
$Report += @"
	</TABLE>
	    <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderRollup)'>
            <SPAN class=sectionTitle tabIndex=0>Exchange Servers Rollup (E2K7 Only)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
                         
	  				</tr>
                    No Exchange 2007 Servers Found in this Organization
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>	
"@
}
Return $Report