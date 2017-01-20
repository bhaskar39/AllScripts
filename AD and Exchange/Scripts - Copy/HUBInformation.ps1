#===================================================================
# HUB Transport Information
#===================================================================
#Write-Output "..Hub Transport Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ExchangeserverList = Get-transportServer | Get-ExchangeServer | where{($_.AdminDisplayVersion.Major -gt "8") -AND ($_.ServerRole -ne "Edge")}
$ClassHeaderQueue = "heading1"       
		foreach($ExchangeServer in $ExchangeServerList)
               {
                $QueueList = $ExchangeServer | Get-Queue
                foreach($Queue in $QueueList)
                {
				if ($Queue.identity -eq $null)
				{
	$ClassHeaderQueue = "heading10"    			
    $DetailQueue+=  "					<tr>"
    $DetailQueue+=  "					<td width='20%'><font color='#FF0000'><b>$($ExchangeServer)</b></font></td>"
    $DetailQueue+=  "					</tr>"
				}
				else
				{
				
                                  $Color = "#0000FF"
                                 if ($Queue.MessageCount -ge 250)
                                  {
                                  $ClassHeaderQueue = "heading10"
								  $Global:Valid = 0
                                  $Color = "FF0000"
                                  }
                    $QueueIdentity = $Queue.Identity
                    $QueueMessageCount = $Queue.MessageCount
                    $QueueNextHopDomain = $Queue.NextHopDomain   
    $DetailQueue+=  "					<tr>"
    $DetailQueue+=  "						<td width='20%'><font color=$($color)><b>$($ExchangeServer)</b></font></td>"
    $DetailQueue+=  "						<td width='20%'><font color=$($color)><b>$($QueueIdentity)</b></font></td>" 
	$DetailQueue+=  "						<td width='20%'><font color=$($color)><b>$($QueueMessageCount)</b></font></td>"
    $DetailQueue+=  "						<td width='20%'><font color=$($color)><b>$($QueueNextHopDomain)</b></font></td>"	
    $DetailQueue+=  "					</tr>"
				}
				}
				}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderQueue)'>
            <SPAN class=sectionTitle tabIndex=0>HUB Transport - Transport Queue Status</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Server Name</b></font></th>
							<th width='20%'><b>Queue Name</b></font></th>
	  						<th width='20%'><b>Messages Count</b></font></th>
	  						<th width='20%'><b>NextHopDomain</b></font></th>							
	  				</tr>
                    $($DetailQueue)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

$ClassHeaderTC = "heading1"
$HUBTC = Get-TransportConfig
        $HUBSRE = $hubtc.ShadowRedundancyEnabled
        $HUBSHTI = $hubtc.ShadowHeartbeatTimeoutInterval
        $HUBSHRC = $hubtc.ShadowHeartbeatRetryCount
        $HUBSMADI = $hubtc.ShadowMessageAutoDiscardInterval     
        
    $DetailTC+=  "					<tr>"
    $DetailTC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBSRE)</b></font></td>"
    $DetailTC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBSHTI)</b></font></td>" 
    $DetailTC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBSHRC)</b></font></td>"
    $DetailTC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBSMADI)</b></font></td>"      
	$DetailTC+=  "					</tr>"
        $HUBMDSD = $hubtc.MaxDumpsterSizePerDatabase
        $HUBMDT = $hubtc.MaxDumpsterTime
        $HUBMRS = $hubtc.MaxReceiveSize
        $HUBMREL = $hubtc.MaxRecipientEnvelopeLimit
        $HUBMSS = $hubtc.MaxSendSize            
        
    $DetailTCD+=  "					<tr>"
    $DetailTCD+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBMDSD)</b></font></td>"
    $DetailTCD+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBMDT)</b></font></td>" 
    $DetailTCD+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBMRS)</b></font></td>"
    $DetailTCD+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBMREL)</b></font></td>"   
    $DetailTCD+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBMSS)</b></font></td>"    
	$DetailTCD+=  "					</tr>"

$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderTC)'>
            <SPAN class=sectionTitle tabIndex=0>HUB Transport - Transport Config</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='20%'><b>ShadowRedundancyEnabled</b></font></th>
	  					<th width='20%'><b>ShadowHeartbeatTimeoutInterval</b></font></th>
	  					<th width='20%'><b>ShadowHeartbeatRetryCount</b></font></th>
	  					<th width='20%'><b>ShadowMessageAutoDiscardInterval </b></font></th>							
	  				</tr>
                    $($DetailTC)
                </table>
                <table>
	  				<tr>
	  						<br><th width='20%'><b>MaxDumpsterSizePerDatabase</b></font></th>
							<th width='20%'><b>MaxDumpsterTime</b></font></th>
							<th width='20%'><b>MaxReceiveSize</b></font></th>
							<th width='20%'><b>MaxRecipientEnvelopeLimit</b></font></th>
							<th width='20%'><b>MaxSendSize</b></font></th>
 		   		</tr>
                    $($DetailTCD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
"@

$ClassHeaderSC = "heading1"
$HUBSends = Get-SendConnector
foreach($HUBSend in $HUBSends){
        $HUBI = $hubsend.Identity
        $HUBAS = $hubsend.AddressSpaces
        $HUBHMSI = $hubsend.HomeMtaServerId
        $HUBSTS = $hubsend.SourceTransportServers
        $HUBMMS = $hubsend.MaxMessageSize     
        $HUBP = $hubsend.Port
        $HUBEnab = $hubsend.Enabled       
    $DetailSC+=  "					<tr>"
    $DetailSC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBI)</b></font></td>"
    $DetailSC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBAS)</b></font></td>" 
    $DetailSC+=  "						<td width='10%'><font color='#0000FF'><b>$($HUBHMSI)</b></font></td>"
    $DetailSC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBSTS)</b></font></td>"      
    $DetailSC+=  "						<td width='10%'><font color='#0000FF'><b>$($HUBMMS)</b></font></td>" 
    $DetailSC+=  "						<td width='10%'><font color='#0000FF'><b>$($HUBP)</b></font></td>" 
    $DetailSC+=  "						<td width='10%'><font color='#0000FF'><b>$($HUBEnab)</b></font></td>"     
	$DetailSC+=  "					</tr>"
    }
$HUBReces = get-ReceiveConnector
foreach($HUBRece in $HUBReces){    
        $HUBRI = $hubRece.Identity
        $HUBRBind = $hubRece.Bindings
        $HUBMRS = $hubRece.Server
        $HUBRMMS = $hubRece.MaxMessageSize
        $HUBREnab = $hubRece.Enabled         
    $Detail+=  "					<tr>"
    $DetailRC+=  "						<td width='45%'><font color='#0000FF'><b>$($HUBRI)</b></font></td>"
    $DetailRC+=  "						<td width='15%'><font color='#0000FF'><b>$($HUBRBind)</b></font></td>" 
    $DetailRC+=  "						<td width='15%'><font color='#0000FF'><b>$($HUBMRS)</b></font></td>"
    $DetailRC+=  "						<td width='15%'><font color='#0000FF'><b>$($HUBRMMS)</b></font></td>"   
    $DetailRC+=  "						<td width='10%'><font color='#0000FF'><b>$($HUBREnab)</b></font></td>"    
	$DetailRC+=  "					</tr>"
}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderSC)'>
            <SPAN class=sectionTitle tabIndex=0>HUB Transport - Connectors settings</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
                        <td width='20%'><b>SEND CONNECTORS</b></font></td><tr>                   
	  					<th width='20%'><b>Identity</b></font></th>
	  					<th width='20%'><b>AddressSpaces</b></font></th>
	  					<th width='10%'><b>HomeMtaServerId</b></font></th>
	  					<th width='20%'><b>SourceTransportServers</b></font></th>
	  					<th width='10%'><b>MaxMessageSize</b></font></th>	
	  					<th width='10%'><b>Port</b></font></th>	
	  					<th width='10%'><b>Enabled</b></font></th>	                                                							
	  				</tr>
                    $($DetailSC)
                </table>
                <table>
	  				<tr>
                        <td width='45%'><b>RECEIVE CONNECTORS</b></font></td><tr>
               		   <br><th width='45%'><b>Identity</b></font></th>
					   <th width='15%'><b>Binding</b></font></th>
					   <th width='15%'><b>Server</b></font></th>
					   <th width='15%'><b>MaxMessageSize</b></font></th>
					   <th width='10%'><b>Enabled</b></font></th>
 		   		</tr>
                    $($DetailRC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
"@
Return $Report