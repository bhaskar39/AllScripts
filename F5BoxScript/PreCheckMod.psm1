################################################################################################                                                                                              #
#AUTHOR:  Pankaj Soni
#Description:	This script is for creating a power shell module to do common pre-check activities on server 
#VERSION: 1.0
#LAST MODIFIED DATE: 22-Jun-2015
#MODIFIED BY: Pankaj Soni
################################################################################################

<#
.SYNOPSIS
    Function to test server connectivity
.DESCRIPTION
    This fucntion will test the connectivity of a server and return 0 as successful and 10 as failed
.NOTES
    Author         	: Pankaj Soni
    Prerequisite   	: PowerShell V2 over Vista and upper.
	parameters		: -Sever "Give the name of the server"
					: -logPath "Provide the complete path where the log file needs to be created or already present"
					: -logFile "Name of the log file"
					: -treatFailureAsSuccess "It will return 0-successful if the server is not reachable and 10-Failed if server is reachable"
.EXAMPLE
    $res=Check-Connection -server "TestServer1" -logPath "C:\Temp" -logFile "ConnectionLogs.log"
.EXAMPLE
    Example 2
	Check-Connection-server "TestServer1" -logPath "C:\Temp" -logFile "ConnectionLogs.log" -treatFailureAsSuccess
#>
function Check-Connection($server,$logPath,$logFile,[switch]$treatFailureAsSuccess)
{
	if (($server) -and ($logPath) -and ($logFile)) #Check for all parameters
	{
		New-Log -Dir $logPath $logFile #Creating log file
		try
		{
			$ConStatus = Test-Connection -ComputerName $server -Count 1 -ea 0 #Actual command which check the connectivity of the server.
			if (!$treatFailureAsSuccess) #Section will execute if -treatFailureAsSuccess parameter is missing and user want to get output as successful if server is reachable
			{
				if($ConStatus)
				{
					Write-Log "Connection to server: $server is successful" 0	
					Return 0
				}
				else
				{
					Write-Log ("Unable to connect to server:",$server) 2
					Return 10
				}
			}
			else #Section will execute if -treatFailureAsSuccess parameter is used and user want to get output as successful if server is not reachable
			{
				if(!$ConStatus)
				{
					Write-Log ("Server is not in use server:",$server) 0
					Return 0					
				}
				else
				{
					Write-Log "Connection to server: $server is successful Kindly check the server name and provide name which is not already in use" 2	
					Return 10
				}			
			}
			
		}
		catch [system.exception]
		{
			$ConStatus = $null
			$message = "Failed to check server health due to system exception + $_.exception"     
			Write-Log $message 2 
			Return 10			
		}
	}
	else
	{
		Write-Log "Some parameters are missing" 2
		Return 10
	}
	return 0
}


<#
.SYNOPSIS
    Function to Check if NIC is DHCP Enabled.
.DESCRIPTION
    This function will check if the DHCP is enabled or a static IP is assigened to servers NIC'
	It will return 0 if the IP setting is DHCP and 1 if it is static
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    parameters		: -serverName "Name of the server"
					: -cred "Credentials of user"
.EXAMPLE
    $IpType=Check-DHCPEnabled -serverName "testServer1" -cred $UserDetails
#>
function Check-DHCPEnabled ($serverName,$cred)
{
	#Check if try catch needed or not.
	#This can be a bug as multiple NIC's may have Static and DHCP enabled but by running this code we will get the status of last NIC as the final result.
	if  (($serverName) -and ($cred))
	{
		try
		{
			$ipType = $null
			$ip=Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $serverName #-credential $cred
			$vmIpType = $ip.dhcpenabled
			foreach ($type in $vmIpType)
			{
				if ($vmIpType -contains $False)
				{
					$ipType="Static"
					$ipTypeStatus="1"
					$ipTypeStatusDesc="IP type is Static for one or more network adapters of $serverName"
					$staticIpStatus="1"
				}
				else
				{
					$ipType="Dynamic"
					$ipTypeStatus="0"
					$ipTypeStatusDesc="IP type is Dynamic for one or more network adapters of $serverName"
					$staticIpStatus="0"
				}
			return $ipTypeStatus	
			}
		}
		catch [system.exception]
		{
			$ConStatus = $null
			$message = "Failed to check server NIC details due to system exception + $_.exception"     
			Write-Log $message 2 
			Return 10			
		}
	}
	else
	{
		Write-Log "Some parameters are missing" 2
		Return 10
	}
}


<#
.SYNOPSIS
    Function to test Multiple servers connectivity
.DESCRIPTION
    This function will check the connectivity status of multiple servers and 
	write the output in the log file. It will return 0 for Success and 
	10 in case of failuer.
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    parameters		: -servers "Name of the servers [Array]"
					: -logPath "Path of the folder where log file will be stored"
					: -logFile "Name of the log file"
.EXAMPLE
    $Res=Check-ServersConnection -servers "testserver1,testserver2" -logPath "C:\temp" -logFile "test.log"
.EXAMPLE
    $res=Check-ServersConnection -servers $serverNames -logPath "C:\temp" -logFile "test.log"
#>
Function Check-ServersConnection ($servers,$logPath,$logFile)
{
	if (($servers) -and ($logPath) -and ($logFile)) #Check for all parameters
	{
		$status=0
		New-Log -Dir $logPath $logFile #Creating log file
		try
		{
			if ($servers -is [array]) #This section will execute if function receive multiple server names in $servers
			{
				foreach($server in $servers) #Runs the loop for each server inside $servers array
				{
					$conStatus = Test-Connection -ComputerName $server -Count 1 -ea 0 #Check if server is able to connect
					if (!$conStatus) #If there is no value in $conStatus, connection to the server is failed
					{
						Write-Log "Failed to connect with server + $server"    2 
						$state=10
					}
				}
			}
			else #This section will execute if only one server name is given.
			{
				$conStatus = Test-Connection -ComputerName $server -Count 1 -ea 0
				if (!$conStatus)
				{
					Write-Log "Failed to connect with server + $server"    2 
					$state=10
				}
			}
		}
		catch [system.exception]
		{
			$ConStatus = $null
			$message = "Failed to check server health due to system exception + $_.exception"     
			Write-Log $message 2   
			return 10
		}
	}
	else
	{
		Write-Log "Some parameters are missing" 2
		Return 10
	}
	return $status
}

<#
.SYNOPSIS
    Get the status of ports and set the status if needed.
.DESCRIPTION
    This fucntion will check the status of open ports on given list of servers
	if it found all the ports in open state then it will return 0 else it will 
	first try to create the rule to open the ports and if it succeed then it will
	return 0 or else it will return 10 as failuer
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    parameters		: -ComputerName "Name of the servers"
					: -Ports "List of ports which needs to be checked"
					: -VIPName "Name of the VIP which we will add as prefix in port rule name"
					: -logPath "Path of the folder where log file will be stored"
					: -logFile "Name of the log file"

.EXAMPLE
    $Res=Get-PortState -ComputerName $Servers -Ports "80" -VIPName "testVIP" -logPath "C:\temp" -logFile "test.log"
#>
Function Update-PortState ($ComputerName, $Ports,$VIPName,$logPath,$logFile)
{
	if (($ComputerName) -and (Ports) -and ($VIPName) -and ($logPath) -and ($logFile)) #Check for all parameters
	{
		try
		{
			New-Log -Dir $logPath $logFile
			$flag=0
			foreach ($Computer in $ComputerName) 
			{
				foreach ($Port in $Ports) 
				{
					# Create a Net.Sockets.TcpClient object to use for
					# checking for open TCP ports.
					$Socket = New-Object Net.Sockets.TcpClient
					# Suppress error messages
					$ErrorActionPreference = 'SilentlyContinue'
					# Try to connect
					$Socket.Connect($Computer, $Port)
					# Make error messages visible again
					$ErrorActionPreference = 'Continue'
					# Determine if we are connected.
					if ($Socket.Connected) 
					{
						Write-Log "${Computer}: Port $Port is open" 0
						$Socket.Close()
					}
					else 
					{
						Write-Log "${Computer}: Port $Port is closed or filtered" 1 
						$RuleName=$VIPName + "_" + $Port
						#Create new inbound rule and opening port in the firewall 
						$Res=Invoke-command -ComputerName $computer {
							param($rName,$pNumber) 
							netsh advfirewall firewall add rule name="$rName" dir=in action=allow protocol=TCP localport="$pNumber"  
						} -argumentlist $ruleName,$port
						#Checking if the port got created or not.
						if ($res -eq "OK.")
						{	
							Write-Log "${Computer}: Port $Port InBound rule created " 0
							#Creating new outbound rule for firewall
							$Res=Invoke-command -ComputerName $computer {
								param($rName,$pNumber) 
								netsh advfirewall firewall add rule name="$rName" dir=out action=allow protocol=TCP localport="$pNumber"
							} -argumentlist $ruleName,$port
							if ($res -eq "OK.")
							{
								Write-Log "${Computer}: Port $Port OutBound rule created " 0
							}
							else
							{
								Write-Log "${Computer}: Port $Port OutBound rule failed " 2
								$flag=10
							}
						}
						else
						{
							Write-Log "${Computer}: Port $Port inbound rule failed " 2
							$flag=10
						}
					}
				# Apparently resetting the variable between iterations is necessary.
				$Socket = $null
				}
			}
		}
		catch [system.exception]
		{
			$ConStatus = $null
			$message = "Failed to check server health due to system exception + $_.exception"     
			Write-Log $message 2   
			return 10
		}
	}
	else
	{
		Write-Log "Some parameters are missing" 2
		Return 10
	}
	return $flag
}
<#
.SYNOPSIS
    Get IP address of servers
.DESCRIPTION
    Will fatch the IP address of the servers and return the server name along with IP address
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    Parameters		: -ComputerName "Name of the servers in an Array""

.EXAMPLE
    $ServerIPs=Get-IPAddress -ComputerName "server1,server2,server3"
#>
Function Get-IPAddress($ComputerName)            
{
	foreach ($Computer in $ComputerName) 
	{
		if(Test-Connection -ComputerName $Computer -Count 1 -ea 0) #Check if the connection with the server is successful
		{
			$Networks = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer | ? {$_.IPEnabled} #Fetch the server network details
			foreach ($Network in $Networks) 
			{
				$IPAddress  = $Network.IpAddress[0] #Get the IP address of server
				#$SubnetMask  = $Network.IPSubnet[0]
				#$DefaultGateway = $Network.DefaultIPGateway
				#$DNSServers  = $Network.DNSServerSearchOrder
				#$MACAddress  = $Network.MACAddress
				$OutputObj  = New-Object -Type PSObject
				$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper() #Add the computer name
				$OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress #Add the server IP address
				#$OutputObj | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $SubnetMask
				#$OutputObj | Add-Member -MemberType NoteProperty -Name Gateway -Value $DefaultGateway
				#$OutputObj | Add-Member -MemberType NoteProperty -Name IsDHCPEnabled -Value $IsDHCPEnabled
				#$OutputObj | Add-Member -MemberType NoteProperty -Name DNSServers -Value $DNSServers
				#$OutputObj | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MACAddress
				$OutputObj
			}
		}
	}
	Return $OutputObj
} 

<#
.SYNOPSIS
    Get the name of the domain
.DESCRIPTION
    It will check the name of the server is in Corp, Extranet domain and return
	the name of the domain
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    parameters		: -FQDN "Fully qualified domain name of the server"
					: -logPath "Path of the folder where log file will be stored"
					: -logFile "Name of the log file"

.EXAMPLE
    $domainName= Get-ServerDomain -FQDN "Northamerica.corp.microsoft.com" -logPath "C:\temp" -logFile "test.log"
.EXAMPLE
    Example 2
#>
Function Get-ServerDomain($FQDN,$logPath,$logFile)
{
	try
	{
		New-Log -Dir $logPath $logFile #Create log file if it is not already created.
		$domain=$FQDN.Split(".")
		#checking the domain name using switch.
		switch ($domain[1])
		{
			"corp" {
					write-log "Server is in Corp domain" 0
					return "Corp"
					}
			"extranet" {
						Write-Log "Server is in extranet domain" 0
						return "Extranet"
						}
			default {
					Write-Log "Server is in unknown domain" 2
					return 10}
		}
	}
	catch [System.exception]
    {
		$outputDesc = $_.Exception.Message
		write-log "Failed to check server domain due to system exception + $_.exception" 2
		return 10
    }
}

<#
.SYNOPSIS
    Test if all the servers in same domain
.DESCRIPTION
    It will test if all the servers are in same domain or not it will return
	0 as successful 1 or 10 and failuer
.NOTES
    Author          : Vidya Hirlekar
    Prerequisite    : PowerShell V2 over Vista and upper.
    Parameters		: -VM_Blade_array "Name of the servers as an array"
					: -logPath "Path of the folder where log file will be stored"
					: -logFile "Name of the log file"	

.EXAMPLE
    $outputStatus= Test-FQDN -VM_Blade_array $serverName -logPath $inputValidationLogPath -logFile $inputValidationLogFile
#>
Function Test-FQDN($VM_Blade_array,$logPath,$logFile)
{
      	New-Log -Dir $logPath $logFile #Create log file if not already created.
		$counter = 0
		$DNmatch_True = $false
		$DNmatch_False = $false
		$VM_Blade_Array | foreach-object {
		try
        {
			#foreach-object will process every VM/Blade here
			$VM_Blade = $_
			$FQDN_Status = [System.Net.Dns]::GetHostByName($VM_Blade)  | FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() }
			if($FQDN_Status)
				{
					if($counter -eq 0)
						{
							$DN = $FQDN_Status.Substring(($FQDN_Status.Split('.')[0].trim().length+1)).ToUpper()
							$counter = $counter + 1
							$VM_Blade_match = $VM_Blade
							write-log "$VM_Blade_match",0
						}
					elseif($counter -eq 1)
						{
							$DNN = $FQDN_Status.Substring(($FQDN_Status.Split('.')[0].trim().length+1)).ToUpper()
							# Checks for Domain Name[DN] match
							if($DN -eq $DNN)
								{
									$DNmatch_True = $true
									$VM_Blade_match = $VM_Blade
								}
							# Else not matching VMs/ Blades are saved here in Nomatch.	
							Else
								{
									$DNmatch_False = $True
									$VM_Blade_Nomatch = "`t $VM_Blade_Nomatch" + $VM_Blade
								}
							if($DNmatch_False)
								{
									return 10
									write-log "$VM_Blade_Nomatch",2 
								}
							elseif($DNmatch_True)
								{
									return 0	
									write-log "$VM_Blade_match", 0
								}
						}									
				}	
			else
				{
					return 1
					write-log "FQDN could not be found", 2
				}            				
        }
        catch [System.exception]
        {
			$outputDesc = $_.Exception.Message
			return 1 
			write-log "$VM_Blade `t $outputDesc", 2
        }  
	}
}

<#
.SYNOPSIS
    Send email message with the details of the log file attached.
.DESCRIPTION
    This function will send email to the receipts passed in parameters about the current status of the KCT
	It will also attache the log file with the email so users can have detail information about the status.
	It will return 0 for success and 10 for failuer
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    Parameters		: 	-rfcNumber		:	Refrance number
						-triggerBy		:	Who triggered the function
						-ActivityName	:	Name of the Activity
						-ActionName		:	Name of the action
						-ActionValue	:	Value given to that action
						-itsmpickup		:	ITSM ticket number
						-OutputStatus	:	The output status of overall script execution
						-StatusDesc		:	Discription of the status
						-result			:	Result of the execution
						-toAddress		:	Email addresses which we need to enter in TO field
						-ccAddress		:	Carbon copy addresses
						-bccAddress		:	Blank carbon copy addresses
						-mailUserName	:	User name by which email need to be sent
						-mailpassWord	:	Password of user
						-fromAddress	:	Email address from which this email will be sent. Make sure that mailUserName has
											the rights to send email from this email ID.
						-attachment		:	Path of the log file which need to be attached with the email.
.EXAMPLE
    Send-EmailMessage -rfcNumber "TST101" -triggerBy "KCT" -ActivityName "Test" -ActionName "Test KCT" -ActionValue 0 -itsmpickup "IT345" -OutputStatus 0 -StatusDesc "KCT success" -result "Success" -toAddress "testTo@microsoft.com" -ccAddress "testCc@microsoft.com" -bccAddress "testBcc@microsoft.com" -mailUserName "fareast\testuser" -mailpassWord "TestPass" -fromAddress "testfrom@microsoft.com" -attachment "c:\temp\log.txt" -KCTNumber "KCT00382" -KCTDiscription "VIP Creation"
#>
Function Send-EmailMessage
{
	[CmdletBinding()]
    Param (
		[parameter(Mandatory=$true)]
		[string]$rfcNumber,
		[parameter(Mandatory=$true)][string]$triggerBy,
		[parameter(Mandatory=$true)][string]$ActivityName,
		[parameter(Mandatory=$true)][string]$ActionName,
		[parameter(Mandatory=$true)][string]$ActionValue,
		[parameter(Mandatory=$true)][string]$itsmpickup,
		[parameter(Mandatory=$true)][int]$OutputStatus,
		[parameter(Mandatory=$true)][string]$StatusDesc,
		[parameter(Mandatory=$true)][string]$result,
		[parameter(Mandatory=$true)][string]$toAddress,
		[parameter(Mandatory=$true)][string]$ccAddress,
		[parameter(Mandatory=$true)][string]$bccAddress,
		[parameter(Mandatory=$true)][string]$mailUserName,
		[parameter(Mandatory=$true)][string]$mailpassWord,
		[parameter(Mandatory=$true)][string]$fromAddress = "v-pason@microsoft.com",#"statsup@microsoft.com",
		[parameter(Mandatory=$true)][string]$attachment,
		[parameter(Mandatory=$true)][string]$KCTNumber,
		[parameter(Mandatory=$true)][string]$KCTDiscription
		)
	if($outputStatus -eq 0)
	{
		$date = Get-Date -Format dd-MMM-yyyy
		$body = 
		"<!-- SUCCESS MAIL Template -->
					<html>
						<head>
							<style id='Test1_2148_Styles'>
							<!--table
								{mso-displayed-decimal-separator:'\.';
								mso-displayed-thousand-separator:'\,';}
								.font52148
								{color:white;
								font-size:11.0pt;
								font-weight:700;
								font-style:normal;
								text-decoration:none;
								font-family:Calibri, sans-serif;
								mso-font-charset:0;}
								.font62148
								{color:#404040;
								font-size:11.0pt;
								font-weight:700;
								font-style:normal;
								text-decoration:none;
								font-family:Calibri, sans-serif;
								mso-font-charset:0;}
								.font72148
								{color:#3A3838;
								font-size:11.0pt;
								font-weight:700;
								font-style:normal;
								text-decoration:none;
								font-family:Calibri, sans-serif;
								mso-font-charset:0;}
								.xl652148
								{padding-top:1px;
								padding-right:1px;
								padding-left:1px;
								mso-ignore:padding;
								color:black;
								font-size:11.0pt;
								font-weight:400;
								font-style:normal;
								text-decoration:none;
								font-family:Calibri, sans-serif;
								mso-font-charset:0;
								mso-number-format:General;
								text-align:general;
								vertical-align:bottom;
								background:white;
								mso-pattern:black none;
								white-space:nowrap;}
								.xl662148
								{padding-top:1px;
								padding-right:1px;
								padding-left:1px;
								mso-ignore:padding;
								color:white;
								font-size:36.0pt;
								font-weight:400;
								font-style:normal;
								text-decoration:none;
								font-family:Calibri, sans-serif;
								mso-font-charset:0;
								mso-number-format:General;
								text-align:center;
								vertical-align:bottom;
								background:#757171;
								mso-pattern:black none;
								white-space:nowrap;}
								.xl672148
								{padding-top:1px;
								padding-right:1px;
								padding-left:1px;
								mso-ignore:padding;
								color:white;
								font-size:12.0pt;
								font-weight:700;
								font-style:normal;
								text-decoration:none;
								font-family:Calibri, sans-serif;
								mso-font-charset:0;
								mso-number-format:General;
								text-align:center;
								vertical-align:middle;
								background:#00B0F0;
								mso-pattern:black none;
								white-space:nowrap;}
								.xl682148
								{padding-top:1px;
								padding-right:1px;
								padding-left:1px;
								mso-ignore:padding;
								color:white;
								font-size:11.0pt;
								font-weight:700;
								font-style:normal;
								text-decoration:none;
								font-family:Calibri, sans-serif;
								mso-font-charset:0;
								mso-number-format:General;
								text-align:center;
								vertical-align:top;
								background:#00B0F0;
								mso-pattern:black none;
								white-space:nowrap;}
								.xl692148
								{padding-top:1px;
								padding-right:1px;
								padding-left:1px;
								mso-ignore:padding;
								color:#262626;
								font-size:11.0pt;
								font-weight:400;
								font-style:normal;
								text-decoration:none;
								font-family:Calibri, sans-serif;
								mso-font-charset:0;
								mso-number-format:General;
								text-align:general;
								vertical-align:bottom;
								background:white;
								mso-pattern:black none;
								white-space:nowrap;}
								.xl702148
								{padding-top:1px;
								padding-right:1px;
								padding-left:1px;
								mso-ignore:padding;
								color:white;
								font-size:22.0pt;
								font-weight:700;
								font-style:normal;
								text-decoration:none;
								font-family:Calibri, sans-serif;
								mso-font-charset:0;
								mso-number-format:General;
								text-align:center;
								vertical-align:bottom;
								background:#00B0F0;
								mso-pattern:black none;
								white-space:nowrap;}
								.xl762148
								{padding-top:1px;
								padding-right:1px;
								padding-left:1px;
								mso-ignore:padding;
								color:#3A3838;
								font-size:14.0pt;
								font-weight:700;
								font-style:normal;
								text-decoration:none;
								font-family:Calibri, sans-serif;
								mso-font-charset:0;
								mso-number-format:General;
								text-align:center;
								vertical-align:middle;
								background:#92D050;
								mso-pattern:black none;
								white-space:nowrap;}
								-->
							</style>
						</head>
						<body>
							<div id='Test1_2148' align=left>
								<table border=0 cellpadding=0 cellspacing=0 width=653 class=xl652148 style='border-collapse:collapse;table-layout:fixed;width:490pt'>
									<col class=xl652148 width=75 style='mso-width-source:userset;mso-width-alt:2742;width:56pt'>
									<col class=xl652148 width=64 span=4 style='width:48pt'>
									<col class=xl652148 width=66 style='mso-width-source:userset;mso-width-alt:2413;width:50pt'>
									<col class=xl652148 width=64 span=4 style='width:48pt'>
									<tr height=35 style='mso-height-source:userset;height:26.25pt'>
										<td rowspan=2 height=56 class=xl662148 width=75 style='height:42.0pt;width:56pt'>IT</td>
										<td colspan=5 class=xl702148 width=322 style='width:242pt'>SDO-Service Transition<span style='mso-spacerun:yes'></span></td>
										<td colspan=4 class=xl762148 width=256 style='width:192pt'>$KCTDiscription</td>
									</tr>
									<tr height=21 style='height:15.75pt'>
										<td colspan=5 height=21 class=xl682148 style='height:15.75pt'><font
											class='font62148'>Change</font><font class='font52148'> IT , </font><font
											class='font62148'>Configure</font><font class='font52148'> IT , </font><font
											class='font62148'>Release</font><font class='font52148'> IT</font>
										</td>
										<td colspan=4 class=xl672148>$KCTNumber</td>
									</tr>
									
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl652148 colspan=10 style='height:15.0pt'><span style='mso-spacerun:yes'></span><font class='font72148'> <br> <br> Dear User, </font></td>
									</tr>
									
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl692148 colspan=10 style='height:15.0pt'><span style='mso-spacerun:yes'></span> Thanks for raising a RFC# $rfcNumber to implement: $KCTDiscription</td>
									</tr>
									 <tr height=20 style='height:15.0pt'>
										<td height=20 class=xl692148 colspan=10 style='height:15.0pt'><span style='mso-spacerun:yes'></span>Please find the below details.</td>
									</tr>
								</table>
							</div>
						</body>
					</html>

					<html>
						<head>
							<style id='Test1_16935_Styles'>
								<!--table
								{mso-displayed-decimal-separator:'\.';
								mso-displayed-thousand-separator:'\,';}
								.xl6516935
									{padding-top:1px;
									padding-right:1px;
									padding-left:20px;
									mso-ignore:padding;
									color:black;
									font-size:11.0pt;
									font-weight:400;
									font-style:normal;
									text-decoration:none;
									font-family:Calibri, sans-serif;
									mso-font-charset:0;
									mso-number-format:General;
									text-align:general;
									vertical-align:bottom;
									background:white;
									mso-pattern:black none;
									white-space:nowrap;}
									.xl6616935
									{padding-top:1px;
									padding-right:1px;
									padding-left:2px;
									mso-ignore:padding;
									color:black;
									font-size:11.0pt;
									font-weight:400;
									font-style:normal;
									text-decoration:none;
									font-family:Calibri, sans-serif;
									mso-font-charset:0;
									mso-number-format:General;
									text-align:general;
									vertical-align:bottom;
									border:.5pt solid #404040;
									background:white;
									mso-pattern:black none;
									white-space:nowrap;}
								-->
							</style>
						</head>
						<body>
							<div id='Test1_16935' align=left>
								<table border=0 cellpadding=0 cellspacing=0 width=416 class=xl6516935 style='border-collapse:collapses;width:312pt'>
									<col class=xl6516935 width=156 style='mso-width-source:userset;mso-width-alt:5705;width:117pt'>
									<col class=xl6516935 width=260 style='mso-width-source:userset;mso-width-alt:9508;width:195pt'>
									<tr height=20 style='height:15.0pt'> </tr>                                
									<tr height=20 style='height:15.0pt' align=left>
										<td height=20 class=xl6616935 width=156 style='height:15.0pt;width:117pt'>RFC NUMBER<span style='mso-spacerun:yes'></span></td>
										<td class=xl6616935 width=260 style='border-left:none;width:195pt'>&nbsp;$rfcNumber</td>
								   </tr>
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>ACTIVITY NAME</td>
										<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$ActivityName</td>
									</tr>
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>ACTION NAME</td>
										<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$ActionName</td>
									</tr>
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>ACTION VALUE</td>
										<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$ActionValue</td>
									</tr>
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>ITSM TICKET UP</td>
										<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$itsmpickup</td>
									</tr>
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>OUTPUT DESCRIPTION</td>
										<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$StatusDesc</td>
									</tr>
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>TRIGGER BY</td>
										<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$triggerBy</td>
									</tr>
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl692148 colspan=10 style='height:15.0pt'><span style='mso-spacerun:yes'></span>Please refer attachment for more Details.</td>
									</tr>
								</table>
							</div>
						</body>
					</html>

					<html>
						<head>
							<style id='Test1_23168_Styles'>
								<!--table
								{mso-displayed-decimal-separator:'\.';
								mso-displayed-thousand-separator:'\,';}
								.font523168
									{color:white;
									font-size:11.0pt;
									font-weight:700;
									font-style:normal;
									text-decoration:none;
									font-family:Calibri, sans-serif;
									mso-font-charset:0;}
									.font623168
									{color:#404040;
									font-size:11.0pt;
									font-weight:700;
									font-style:normal;
									text-decoration:none;
									font-family:Calibri, sans-serif;
									mso-font-charset:0;}
									.font723168
									{color:#3A3838;
									font-size:11.0pt;
									font-weight:700;
									font-style:normal;
									text-decoration:none;
									font-family:Calibri, sans-serif;
									mso-font-charset:0;}
									.xl6523168
									{padding-top:1px;
									padding-right:1px;
									padding-left:1px;
									mso-ignore:padding;
									color:black;
									font-size:11.0pt;
									font-weight:400;
									font-style:normal;
									text-decoration:none;
									font-family:Calibri, sans-serif;
									mso-font-charset:0;
									mso-number-format:General;
									text-align:general;
									vertical-align:bottom;
									background:white;
									mso-pattern:black none;
									white-space:nowrap;}
									.xl7223168
									{padding-top:1px;
									padding-right:1px;
									padding-left:1px;
									mso-ignore:padding;
									color:#0563C1;
									font-size:11.0pt;
									font-weight:400;
									font-style:normal;
									text-decoration:underline;
									text-underline-style:single;
									font-family:Calibri, sans-serif;
									mso-font-charset:0;
									mso-number-format:General;
									text-align:general;
									vertical-align:bottom;
									background:white;
									mso-pattern:black none;
									white-space:nowrap;}
								   .xl7323168
									{padding-top:1px;
									padding-right:1px;
									padding-left:1px;
									mso-ignore:padding;
									color:#3A3838;
									font-size:11.0pt;
									font-weight:400;
									font-style:normal;
									text-decoration:none;
									font-family:Calibri, sans-serif;
									mso-font-charset:0;
									mso-number-format:General;
									text-align:general;
									vertical-align:bottom;
									background:white;
									mso-pattern:black none;
									white-space:nowrap;}
									.xl7423168
									{padding-top:1px;
									padding-right:1px;
									padding-left:1px;
									mso-ignore:padding;
									color:#3A3838;
									font-size:12.0pt;
									font-weight:700;
									font-style:normal;
									text-decoration:none;
									font-family:Calibri, sans-serif;
									mso-font-charset:0;
									mso-number-format:General;
									text-align:general;
									vertical-align:bottom;
									background:white;
									mso-pattern:black none;
									white-space:nowrap;}
									.xl7523168
									{padding-top:1px;
									padding-right:1px;
									padding-left:1px;
									mso-ignore:padding;
									color:#00B0F0;
									font-size:16.0pt;
									font-weight:400;
									font-style:normal;
									text-decoration:none;
									font-family:Calibri, sans-serif;
									mso-font-charset:0;
									mso-number-format:General;
									text-align:general;
									vertical-align:bottom;
									background:white;
									mso-pattern:black none;
									white-space:nowrap;}
								-->
							</style>
						</head>
						<body>
							<div id='Test1_23168' align=left>
								<table border=0 cellpadding=0 cellspacing=0 width=653 class=xl6523168 style='border-collapse:collapse;table-layout:fixed;width:490pt'>
									<tr height=20 style='height:15.0pt'> </tr>
									<tr height=21 style='height:15.75pt'>
										<td height=21 class=xl7423168 colspan=2 style='height:15.75pt'>Thanks &amp; Regards</td>
									</tr>
									<tr height=31 style='height:23.25pt'>
										<td height=31 class=xl7523168 colspan=3 style='height:23.25pt'>Automation Team</td>
									</tr>
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl7323168 colspan=2 style='height:15.0pt'>Service Transition</td>
									</tr>
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl7223168 colspan=3 style='height:15.0pt'><a href='mailto:statsup@microsoft.com'>statsup@microsoft.com</a></td>
									</tr>
								</table>
							</div>
						</body>
					</html>"
	}
	else
	{
		$body = 
				"<!-- FAILED MAIL Template -->
				<html>
					<head>
						<style id='Test1_2148_Styles'>
							<!--table
							{mso-displayed-decimal-separator:'\.';
							mso-displayed-thousand-separator:'\,';}
							.font52148
							{color:white;
							font-size:11.0pt;
							font-weight:700;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;}
							.font62148
							{color:#404040;
							font-size:11.0pt;
							font-weight:700;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;}
							.font72148
							{color:#3A3838;
							font-size:11.0pt;
							font-weight:700;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;}
							.xl652148
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:black;
							font-size:11.0pt;
							font-weight:400;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:general;
							vertical-align:bottom;
							background:white;
							mso-pattern:black none;
							white-space:nowrap;}
							.xl662148
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:white;
							font-size:36.0pt;
							font-weight:400;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:center;
							vertical-align:bottom;
							background:#757171;
							mso-pattern:black none;
							white-space:nowrap;}
							.xl672148
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:white;
							font-size:12.0pt;
							font-weight:700;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:center;
							vertical-align:middle;
							background:#00B0F0;
							mso-pattern:black none;
							white-space:nowrap;}
							.xl682148
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:white;
							font-size:11.0pt;
							font-weight:700;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:center;
							vertical-align:top;
							background:#00B0F0;
							mso-pattern:black none;
							white-space:nowrap;}
							.xl692148
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:#262626;
							font-size:11.0pt;
							font-weight:400;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:general;
							vertical-align:bottom;
							background:white;
							mso-pattern:black none;
							white-space:nowrap;}
							.xl702148
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:white;
							font-size:22.0pt;
							font-weight:700;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:center;
							vertical-align:bottom;
							background:#00B0F0;
							mso-pattern:black none;
							white-space:nowrap;}
							.xl762148
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:#FFC000;
							font-size:14.0pt;
							font-weight:700;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:center;
							vertical-align:middle;
							background:#C00000;
							mso-pattern:black none;
							white-space:nowrap;}
							-->
						</style>
					</head>
					<body>
						<div id='Test1_2148' align=left>
							<table border=0 cellpadding=0 cellspacing=0 width=653 class=xl652148 style='border-collapse:collapse;table-layout:fixed;width:490pt'>
								<col class=xl652148 width=75 style='mso-width-source:userset;mso-width-alt:2742;width:56pt'>
								<col class=xl652148 width=64 span=4 style='width:48pt'>
								<col class=xl652148 width=66 style='mso-width-source:userset;mso-width-alt:2413;width:50pt'>
								<col class=xl652148 width=64 span=4 style='width:48pt'>
								<tr height=35 style='mso-height-source:userset;height:26.25pt'>
									<td rowspan=2 height=56 class=xl662148 width=75 style='height:42.0pt;width:56pt'>IT</td>
									<td colspan=5 class=xl702148 width=322 style='width:242pt'>SDO-Service Transition<span style='mso-spacerun:yes'></span></td>
									<td colspan=4 class=xl762148 width=256 style='width:192pt'>$KCTDiscription</td>
								</tr>
								<tr height=21 style='height:15.75pt'>
									<td colspan=5 height=21 class=xl682148 style='height:15.75pt'><font
									class='font62148'>Change</font><font class='font52148'> IT , </font><font
									class='font62148'>Configure</font><font class='font52148'> IT , </font><font
									class='font62148'>Release</font><font class='font52148'> IT</font>
									</td>
									<td colspan=4 class=xl672148>KCT NO : $KCTNumber</td>
								</tr>
								<tr height=20 style='height:15.0pt'>
									<td height=20 class=xl692148 colspan=10 style='height:15.0pt'><span style='mso-spacerun:yes'></span></td>
								</tr>
								<tr height=20 style='height:15.0pt'>
									<td height=20 class=xl692148 colspan=10 style='height:15.0pt'><span style='mso-spacerun:yes'></span><b>Dear User,<b></td>
								</tr>
								<tr height=20 style='height:15.0pt'>
									<td height=20 class=xl692148 colspan=10 style='height:15.0pt'><span style='mso-spacerun:yes'></span>Thanks for raising a RFC# $rfcNumber to implement: $KCTDiscription</td>
								</tr>
								<tr height=20 style='height:15.0pt'>
									<td height=20 class=xl692148 colspan=10 style='height:15.0pt'><span style='mso-spacerun:yes'></span>Please find the below details.</td>
								</tr>
							</table>
						</div>
					</body>
				</html>
				<html>
					<head>
						<style id='Test1_16935_Styles'>
							<!--table
							{mso-displayed-decimal-separator:'\.';
							mso-displayed-thousand-separator:'\,';}
							.xl6516935
							{padding-top:1px;
							padding-right:1px;
							padding-left:20px;
							mso-ignore:padding;
							color:black;
							font-size:11.0pt;
							font-weight:400;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:general;
							vertical-align:bottom;
							background:white;
							mso-pattern:black none;
							white-space:nowrap;}
							.xl6616935
							{padding-top:1px;
							padding-right:1px;
							padding-left:2px;
							mso-ignore:padding;
							color:black;
							font-size:11.0pt;
							font-weight:400;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:general;
							vertical-align:bottom;
							border:.5pt solid #404040;
							background:white;
							mso-pattern:black none;
							white-space:nowrap;}
							-->
						</style>
					</head>
					<body>
						<div id='Test1_16935' align=left>
							<table border=0 cellpadding=0 cellspacing=0 width=416 class=xl6516935 style='border-collapse:collapses;width:312pt'>
								<col class=xl6516935 width=156 style='mso-width-source:userset;mso-width-alt:5705;width:117pt'>
								<col class=xl6516935 width=260 style='mso-width-source:userset;mso-width-alt:9508;width:195pt'>
								<tr height=20 style='height:15.0pt'> </tr>
								<tr height=20 style='height:15.0pt' align=left>
									<td height=20 class=xl6616935 width=156 style='height:15.0pt;width:117pt'>RFC NUMBER<span style='mso-spacerun:yes'></span></td>
									<td class=xl6616935 width=260 style='border-left:none;width:195pt'>&nbsp;$rfcNumber</td>
								</tr>
								<tr height=20 style='height:15.0pt'>
									<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>ACTIVITY NAME</td>
									<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$ActivityName</td>
								</tr>
								<tr height=20 style='height:15.0pt'>
									<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>ACTION NAME</td>
									<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$ActionName</td>
								</tr>
								<tr height=20 style='height:15.0pt'>
									<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>ACTION VALUE</td>
									<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$ActionValue</td>
								</tr>
								<tr height=20 style='height:15.0pt'>
									<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>ITSM TICKET UP</td>
									<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$itsmpickup</td>
								</tr>
								<tr height=20 style='height:15.0pt'>
									<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>REASON FOR FAILURE</td>
									<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$StatusDesc</td>
								</tr>
								<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl6616935 style='height:15.0pt;border-top:none'>TRIGGER BY</td>
										<td class=xl6616935 style='border-top:none;border-left:none'>&nbsp;$triggerBy</td>
								</tr>
							</table>
						</div>
					</body>
				</html>
				<html>
					<head>
						<style id='Test1_23168_Styles'>
							<!--table
							{mso-displayed-decimal-separator:'\.';
							mso-displayed-thousand-separator:'\,';}
							.font523168
							{color:white;
							font-size:11.0pt;
							font-weight:700;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;}
							.font623168
							{color:#404040;
							font-size:11.0pt;
							font-weight:700;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;}
							.font723168
							{color:#3A3838;
							font-size:11.0pt;
							font-weight:700;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
						   mso-font-charset:0;}
							.xl6523168
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:black;
							font-size:11.0pt;
							font-weight:400;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:general;
							vertical-align:bottom;
							background:white;
							mso-pattern:black none;
							white-space:nowrap;}
							.xl7223168
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:#0563C1;
							font-size:11.0pt;
							font-weight:400;
							font-style:normal;
							text-decoration:underline;
							text-underline-style:single;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:general;
							vertical-align:bottom;
							background:white;
							mso-pattern:black none;
							white-space:nowrap;}
							.xl7323168
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:#3A3838;
							font-size:11.0pt;
							font-weight:400;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:general;
							vertical-align:bottom;
							background:white;
							mso-pattern:black none;
							white-space:nowrap;}
							.xl7423168
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:#3A3838;
							font-size:12.0pt;
							font-weight:700;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:general;
							vertical-align:bottom;
							background:white;
							mso-pattern:black none;
							white-space:nowrap;}
						   .xl7523168
							{padding-top:1px;
							padding-right:1px;
							padding-left:1px;
							mso-ignore:padding;
							color:#00B0F0;
							font-size:16.0pt;
							font-weight:400;
							font-style:normal;
							text-decoration:none;
							font-family:Calibri, sans-serif;
							mso-font-charset:0;
							mso-number-format:General;
							text-align:general;
							vertical-align:bottom;
							background:white;
							mso-pattern:black none;
							white-space:nowrap;}
				-->
						</style>
					</head>
					<body>
						<div id='Test1_23168' align=left>
							<table border=0 cellpadding=0 cellspacing=0 width=653 class=xl6523168 style='border-collapse:collapse;table-layout:fixed;width:490pt'>
								<tr height=20 style='height:15.0pt'> </tr>
									<tr height=21 style='height:15.75pt'>
										<td height=21 class=xl7423168 colspan=2 style='height:15.75pt'>Thanks &amp; Regards</td>
									</tr>
									<tr height=31 style='height:23.25pt'>
										<td height=31 class=xl7523168 colspan=3 style='height:23.25pt'>Automation Team</td>
									</tr>
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl7323168 colspan=2 style='height:15.0pt'>Service Transition</td>
									</tr>
									<tr height=20 style='height:15.0pt'>
										<td height=20 class=xl7223168 colspan=3 style='height:15.0pt'><a href='mailto:statsup@microsoft.com'>statsup@microsoft.com</a></td>
									</tr>
							</table>
						</div>
					</body>
				</html>"
	}
				$Subject = "KCT $KCTNumber for $KCTDiscription summery"
				$smtpserver = "smtphost.redmond.corp.microsoft.com" 
				$message = new-object System.Net.Mail.MailMessage 
				$message.From = $fromaddress 
				$message.To.Add($toaddress)
				$message.CC.Add($CCaddress) 
				$message.Bcc.Add($bccaddress) 
				$message.IsBodyHtml = $True 
				$message.Subject = $Subject 
				$message.body = $body 
				$attach = new-object Net.Mail.Attachment($attachment) 
				$message.Attachments.Add($attach)
				$smtp = new-object Net.Mail.SmtpClient($smtpserver) 
				$smtp.Credentials = New-Object System.Net.NetworkCredential("$mailUserName", "$mailpassWord") 
				$smtp.Send($message)
				if($?)
				{
					Return 0
				}
				else
				{
					return 10
				}
}
<#
.SYNOPSIS
    Will check if the SQL is installed on server or not.
.DESCRIPTION
    This funntion will check if SQL is installed on the server or not. It will rerutn 0 if SQL server is not installed on server
	or if SQL is installed but not running and SQL reporting service is running state.
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    Parameters		: -$serverName Name of the server on which SQL need to be checked.
					  -domainName Servers domain name
					  -logPath Path of the folder in which log file needs to be stored.
					  -logFile Name of the log file

.EXAMPLE
    $res = Test-SQLInstalled -serverName "testsrv1" -domainName "fareast.corp.microsoft.com" -logPath "c:\logs" -logFile "testlog.log"

#>
Function Test-SQLInstalled ($serverName,$domainName,$logPath,$logFile) 
{
	if (($serverName) -and ($domainName) -and ($logPath) -and ($logFile)) #Check for all parameters
	{
		try
		{
			New-Log -Dir $logPath $logFile #Create log file if needed.
			$serverNameStr = "$serverName"
			$hostName = "$serverName.$domainName"
			if (($hostName -eq "$serverNameStr.partners.extranet.microsoft.com") -or ($hostName -eq "$serverNameStr.parttest.extranettest.microsoft.com"))
			{
				$sqlInstallationCheck=invoke-command -computername $hostName -scriptblock {
				$softwares=Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall |  ForEach-object { (Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_).DisplayName } 
				if($softwares)
				{
					$sql=$softwares -match "Microsoft sql server" 
					$sqlTest=$sql -match "Setup"
					if($sqlTest -ne "")            
					{
						$outputStatus = 1
					}
					else
					{
						$outputStatus = 0
					}
				}
				else
				{
					$outputStatus = 10
				}
				$outputStatus
				} -argumentlist $serverNameStr -EA Stop
			}
			else
			{
				$sqlInstallationCheck=invoke-command -computername $serverNameStr -scriptblock {
				$softwares=Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall |  ForEach-object { (Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_).DisplayName } 
				if($softwares)
				{
					$sql=$softwares -match "Microsoft sql server" 
					$sqlTest=$sql -match "Setup"
					if($sqlTest -ne "")            
					{
						$outputStatus = 1
					}
					else
					{
						$outputStatus = 0
					}
				}
				else
				{
					$outputStatus = 10
				}
				$outputStatus
				} -argumentlist $serverNameStr -EA Stop
			}
			if($sqlInstallationCheck -eq 1)            
			{
				$outputStatus = 1
				$outputDesc = "SQL is installed on the server"
				write-log "$outputDesc" 0
				
			}
			elseif($sqlInstallationCheck -eq "0")
			{
				$outputStatus = 0
				$outputDesc = "SQL is not installed on the server" 
				write-log "$outputDesc" 0
			}
			else
			{
				$outputStatus = 1
				$outputDesc = "Unable to check sql installed or not due to system error"
				write-log "$outputDesc" 2
			}
		}
		catch [system.exception]
		{
			$message = "Failed to check SQL installation status on server due to system exception + $_.exception"     
			Write-Log $message 2 
			Return 10			
		}
	}
	else
	{
		Write-Log "Some parameters are missing" 2
		Return 10
	}
	
	if ($outputStatus -eq 1)
	{
		$SQLServices = Get-WmiObject -ComputerName $serverNameStr win32_service | where {$_.name -like "MSSQL*" -and $_.name -notlike "*SQLEXPRESS" -and $_.name -notlike "*MSSQLFDLauncher*" -and $_.name -notlike "*OLAPService*" -and  $_.name -notlike "*##SSEE" -and $_.name -notlike "*ADHelper*" -and $_.name –notlike "*##WID*"}  -ErrorAction Stop
		if($SQLServices -ne $null)
		{
			if($SQLServices -is [System.Array])
			{
				$ServicesCount = $SQLServices.count;
				for($i = 0;$i -lt $ServicesCount;$i++)
				{
					if($SQLServices[$i].State -ne "Running")
					{
						$ServiceFlag = 0;
					}
					else
					{
						$ServiceFlag = 1;
						break;
					}
				}
				if($ServiceFlag -eq 1)
				{
					$Message += "SQL services are in a running state on server: $serverNameStr"
					Write-Log $message 2 
					$RunFlag = 1;
					$SQLFlag = 1;
				}
				else
				{
					$Message += "SQL services are not in a running state on server: $serverNameStr"
					Write-Log $message 0
					$RunFlag = -1;
					$SQLFlag = 0;
					$ServiceFlag = 0
				}
			}	
			else
			{
				if($SQLServices.State -eq "Running")
				{
					$Message += "SQL services are in a running state on server: $serverNameStr"
					Write-Log $message 2 
					$RunFlag = 1;
					$SQLFlag = 1;
				}
				else
				{
					$Message += "SQL services are not in a running state on server: $serverNameStr"
					Write-Log $message 0
					$ServiceFlag = 0
				}
			}
		}
		If ($ServiceFlag -eq 0)
		{
			$ReportServices = Get-WMIObject -ComputerName $serverNameStr -Class "Win32_Service" | Where {$_.Name -like "*ReportServer*"}
			$ReportServiceFlag=0
			if($ReportServices -ne $null)
			{
				if($ReportServices -is [System.Array])
				{
					$ReportServicesCount = $ReportServices.count;
					for($i = 0;$i -lt $ReportServicesCount;$i++)
					{
						if($ReportServices[$i].State -ne "Running")
						{
							$ReportServiceFlag = 1;
							break;
						}	
					}
					if($ReportServiceFlag -eq 0)
					{
						$Message = "SSRS service(s) are in a running state on server :$serverNameStr"
						Write-Log $message 0
						$ReportServiceFlag=0
					}
					else
					{
						$Message = "SSIS service(s) are not in a running state on server : $serverNameStr"
						$ReportServiceFlag=1
						Write-Log $message 1

					}
				}
				else
				{
					if($ReportServices.State -eq "Running")
					{
						$Message = "SSRS service(s) are in a running state on server :$serverNameStr"
						$ReportServiceFlag=0
						Write-Log $message 0
					}
					else
					{
						$Message = "SSIS service(s) are not in a running state on server : $serverNameStr"
						$ReportServiceFlag=1
						Write-Log $message 1
					}
				} 
			}
		}
		if (($ReportServiceFlag -eq 0) -and ($ServiceFlag -eq 0))
		{
			$Message = "SSRS service(s) are in a running state on server :$serverNameStr but SQL is not in running state"
			Write-Log $message 0
			$outputStatus = 0
		}
		elseif(($ReportServiceFlag -eq 1) -and ($ServiceFlag -eq 0))
		{
			$Message = "Nithter SSRS service(s) nor SQL is in running state on server :$serverNameStr"
			Write-Log $message 1
			$outputStatus=0
		}
		else
		{
			$Message = "Both SSRS service(s) and SQL is in running state on server :$serverNameStr"
			Write-Log $message 2
			$outputStatus = 10
		}    
	}

return $outputStatus
}

<#
.SYNOPSIS
    Check if NLB is installed on server or not.
.DESCRIPTION
    This funtion will check if NLB feature is installed on server or not. It will return 0 if it is not installed
	and 10 if NLB is installed on server or function is unable to check its status.
.NOTES
    Author          : Pankaj Soni
    Prerequisite    : PowerShell V2 over Vista and upper.
    Parameters		: -Username		User name of the user having access on server with admin rights.
					  -Password		Password of the user
					  -serverName	Name of the server on which NLB is need to be tested.
					  -logPath Path of the folder in which log file needs to be stored.
					  -logFile Name of the log file

.EXAMPLE
    Check-NLBStatus -userName "fareast\testuser" -password "abcd" -logPath "c:\logs" -logFile "testlog.log"

#>
Function Check-NLBStatus($serverName,$userName,$password,$logPath,$logFile)
{
	if (($Username) -and ($Password) -and ($serverName) -and ($logPath) -and ($logFile))
	{
		New-Log -Dir $logPath $logFile #Check and create log file if needed.
		try
		{
			$pass = ConvertTo-SecureString -AsPlainText $Password -Force
			$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass
						$nlb_status=Invoke-Command -ComputerName $serverName -ScriptBlock {param ($test) import-module servermanager; Get-WindowsFeature -Name NLB} -Args $serverName -credential $Cred
			#$nlb_state=$nlb_status.InstallState
			if ($nlb_status.Installed)#$nlb_state -eq 'Installed')
			{
				Write-Log "The server $serverName has NLB installed " 2
				return 10
			}
			else
			{
				Write-Log "The Server $serverName is available but NLB is not installed" 0
				return 0
			}
		}
		catch [system.exception]
		{
			$message = "Failed to check NLB installation status on server due to system exception + $_.exception"     
			Write-Log $message 2 
			Return 10			
		}
	}
	else
	{
		Write-Log "Some parameters are missing" 2
		Return 10
	}	
}



########### Exporting all functions as power shell cmdlet ####################

Export-ModuleMember -Function * -Alias *

