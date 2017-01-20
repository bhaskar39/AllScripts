#===================================================================
# Test MAPI Connectivity - Mailbox and Public Folder Databases
#===================================================================
#Write-Output "..Test MAPI Connectivity - Mailbox and Public Folder Databases"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$MAPIMBX = (Get-MAilboxDatabase | Test-MAPIConnectivity)
$ClassHeaderMC = "heading1"
foreach($MC in $MAPIMBX)
               {
			    $MCMBX = $MC.Server
				$MCDB = $MC.Database
				$MCRes = $MC.Result
				$MCLatency = $MC.Latency
				$MCError = $MC.Error
    $DetailMC+=  "					<tr>"
    $DetailMC+=  "						<td width='20%'><font color='#0000FF'><b>$($MCMBX)</b></font></td>"
    $DetailMC+=  "						<td width='30%'><font color='#0000FF'><b>$($MCDB)</b></font></td>"  
	if ($MCRes -like "Success")
	{
        $ClassHeaderMC = "heading1"	
        $DetailMC+=  "						<td width='10%'><font color='#0000FF'><b>$($MCRes)</b></font></td>"
        $DetailMC+=  "						<td width='20%'><font color='#0000FF'><b>$($MCLatency)</b></font></td>" 			
        $DetailMC+=  "						<td width='20%'><font color='#0000FF'><b>$($MCError)</b></font></td>"
    }
    else
    {
        $ClassHeaderMC = "heading10"
        $DetailMC+=  "						<td width='10%'><font color='#FF0000'><b>$($MCRes)</b></font></td>"
        $DetailMC+=  "						<td width='20%'><font color='#FF0000'><b>$($MCLatency)</b></font></td>" 			
        $DetailMC+=  "						<td width='20%'><font color='#FF0000'><b>$($MCError)</b></font></td>" 
    }
    $DetailMC+=  "					</tr>"
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderMC)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test MAPIConnectivity - Mailbox Database</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Mailbox Server</b></font></th>
	  						<th width='30%'><b>Database Name</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
	  						<th width='20%'><b>Latency (ms)</b></font></th>							
	  						<th width='20%'><b>Error</b></font></th>								
	  				</tr>
                    $($DetailMC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
 
$MAPIPF = (Get-PublicFolderDatabase | Test-MAPIConnectivity)
$ClassHeaderMCPF = "heading1"
foreach($MCPF in $MAPIPF)
               {
			    $MCPFS = $MCPF.Server
				$MCDBPF = $MCPF.Database
				$MCPFRes = $MCPF.Result
				$MCPFLatency = $MCPF.Latency
				$MCPFError = $MCPF.Error
    $DetailMCPF+=  "					<tr>"
    $DetailMCPF+=  "						<td width='20%'><font color='#0000FF'><b>$($MCPFS)</b></font></td>"
    $DetailMCPF+=  "						<td width='20%'><font color='#0000FF'><b>$($MCDBPF)</b></font></td>"  
	if ($MCPFRes -like "Success")
	{
        $DetailMCPF+=  "						<td width='10%'><font color='#0000FF'><b>$($MCPFRes)</b></font></td>"
        $DetailMCPF+=  "						<td width='10%'><font color='#0000FF'><b>$($MCPFLatency)</b></font></td>"			
        $DetailMCPF+=  "						<td width='10%'><font color='#0000FF'><b>$($MCPFError)</b></font></td>"
    }
    else
    {
        $ClassHeaderMCPF = "heading10"
        $DetailMCPF+=  "						<td width='10%'><font color='#FF0000'><b>$($MCPFRes)</b></font></td>"
        $DetailMCPF+=  "						<td width='10%'><font color='#FF0000'><b>$($MCPFLatency)</b></font></td>"			
        $DetailMCPF+=  "						<td width='10%'><font color='#FF0000'><b>$($MCPFError)</b></font></td>" 
    }
    $DetailMCPF+=  "					</tr>"
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderMCPF)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test MAPIConnectivity - Public Folder Database</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Mailbox Server</b></font></th>
	  						<th width='20%'><b>Database Name</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
	  						<th width='10%'><b>Latency (ms)</b></font></th>							
	  						<th width='10%'><b>Error</b></font></th>								
	  				</tr>
                    $($DetailMCPF)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
Return $Report