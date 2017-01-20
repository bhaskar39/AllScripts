	workflow KCT0000382_NON_EFL_VIP
	{
		param(
			[Parameter (Mandatory=$true)] [string]$rfcNumber,		#Ticket number from ITSM
			[Parameter (Mandatory=$true)] [string]$ProcessID,		#
			[Parameter (Mandatory=$true)] [string]$serverName,		#Nodes which need to be added to VIP
			[Parameter (Mandatory=$true)] [string]$DataCenterName, 	#DC where the change has to be done
			[Parameter (Mandatory=$true)] [string]$Ports,			#List of Port Number to be allowed
			[Parameter (Mandatory=$true)] [string]$FQDN,			#Required FQDN of the VIP
			[Parameter (Mandatory=$true)] [string]$VIPName,			#VIP Name
			[Parameter (Mandatory=$true)] [string]$Loadbal,			#Type of Load Balancing method
			[Parameter (Mandatory=$true)] [bool]$Persistance,		#Required Value of persistence it can be Default (True) or Customized (False)
			[Parameter (Mandatory=$true)] [string]$ExtenMon,		#Required Health monitor type
			[Parameter (Mandatory=$true)] [string]$VIPOwnsecGrp,	#Name of security group which needed to add to myvip's portal
			[Parameter (Mandatory=$true)] [string]$VIPOwnAlias,		#Name of owner alias  which needed to add to myvip's portal
			[Parameter (Mandatory=$true)] [string]$LTMName,			#Details of the F5box
			[Parameter (Mandatory=$true)] [string]$FreeVIPIP,		#Free VIP IP required to create the VIP
			[Parameter (Mandatory=$true)] [string]$SNATFreeIP,		#Free SNAT pool IP required to create the SNAT Pool
			[Parameter (Mandatory=$true)] [string]$userName, 
			[Parameter (Mandatory=$true)] [string]$passWord,
			[Parameter (Mandatory=$true)] [string]$eMailID,
			[Parameter (Mandatory=$true)] [string]$ITSM_Tkt
		)
		
		################# Set Job Lock #################

	    $JobCount = Get-AutomationVariable -Name "StaticIPJobLock"
	    $JobCount++
	    Set-AutomationVariable -Name "StaticIPJobLock" -Value $JobCount

	    #################################Global Common Inputs #########################################
		$Count= 0 + $Count
	    $retCode = 1
	    $KCTNumber = "KCT382"
	    $ChangeTicketNumber = "$RFCnumber".split("@")[0];
	    $RoutingAlias = "fareast\v-ansees";
	 	#   $ActivityModPath = "D:\SelfService\ACTIVITY LOGGER\StandardLogging.psm1"
	    
	    #$FastRFCSQLServer = "CY1STTOOLSSQL01"
	    $FastRFCSQLServer = "AZCUISMSQLUAT1A"
	    $FastRFCDBName = "FastRFC"

	    $dbServer = "TK5STPRDVM01"
	    $dbName = "Orchestrator_Logging"
	    $TableName = "Standard_Logging_SelfService"

	    $errorDesc = "No_Error"
	    $activityStatus = "Completed"

	    $SMAConn = Get-AutomationConnection -Name 'SCPTTSMA'
	    $Username = $SMAConn.UserName
	    $Password = $SMAConn.UserPassword
	    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force 
	    $Cred = New-Object System.Management.Automation.PSCredential($Username,$SecurePassword)
		
		$rfcNumber="$using:rfcNumber"
		$ProcessID="$using:ProcessID"
		$serverName="$using:serverName"
		$DataCenterName="$using:DataCenterName"
		$Ports="$using:Ports"
		$FQDN="$using:FQDN"
		$VIPName="$using:VIPName"
		$Loadbal="$using:Loadbal"
		$Persistance="$using:Persistance"
		$ExtenMon="$using:ExtenMon"
		$VIPOwnsecGrp="$using:VIPOwnsecGrp"
		$VIPOwnAlias="$using:VIPOwnAlias"
		$LTMName="$using:LTMName"
		$FreeVIPIP="$using:FreeVIPIP"
		$SNATFreeIP="$using:SNATFreeIP"
		$serverName="$using:serverName"
		$userName="$using:userName"
		$password="$using:password"
		$ITSM_Tkt="$using:ITSM_Tkt"
		$password = Get-password $password
		$mailId="$using:emailId"
		$fromMailId = "stgco@microsoft.com"
		$ccMailId = "v-sabhut@microsoft.com,v-bhde@microsoft.com,v-hasa@microsoft.com,v-ansess@microsoft.com"
		#"v-aneram@microsoft.com,v-ansee@microsoft.com,v-bvara@microsoft.com,v-kagore@microsoft.com,v-praved@microsoft.com,v-saidev@microsoft.com,v-samitm@microsoft.com,v-siabbi@microsoft.com,v-smrv@microsoft.com,v-sugs@microsoft.com,v-subhoo@microsoft.com,gcocomm@microsoft.com,v-sribol@microsoft.com,v-vimun@microsoft.com"
		$bccMailId ="v-pason@microsoft.com", "v-vihirl@microsoft.com" 
		#"v-smrv@microsoft.com"
		$inputValidationLogPath = "D:\Log" #"D:\Log\NON_EFL_VIP\$processID\$rfcNumber\$serverName\" 
		$inputValidationLogFile = "Input Validation.log"
		$attachment_logPath = $inputValidationLogPath + "\" + $inputValidationLogFile
		$outputStatus = 0			# The value of Output status should be 0 if it is non Zero value then an error occur and action need to be taken.
		$IPType = $NULL 			# 0 in case of DHCP and 1 in case of Static IP.
		$VIPFQDN = $VIPName + "." + $FQD
		################################### ACTIVITY LOGGER VARIABLES ##################################################
			
		$dbServerName = "co1gcoprdsmms01" # Names to be verified
		$dbName = "GCONG"
		$processID = "$using:ProcessID"
		$accountName = "$userName"
		$errorStatus = "No Error"


		######################################### #################################################
		$date = Get-Date -Format dd-MMM-yyyy   
		$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
		$cred = New-Object System.Management.Automation.PSCredential($userName,$securePassword)
		### First Inline Script       
	    try
	    {
	   	$WriteOut = InlineScript {
   
		    ##################IMPORTING MODULE 
		    import-module "D:\KCT0000382\LOGGER.psm1" 			#Importing logger module Later need to be change to correct path
			import-Module "D:\KCT0000382\PreCheckMod.psm1"
			Import-Module "D:\KCT0000382\F5Functions.psm1"
			Import-Module "D:\KCT0000382\Create-VIP.psm1"
			Import-Module "D:\KCT0000382\CreatePersistenceProfile.psm1"
			Import-Module "D:\KCT0000382\Create-DNS-A-record.psm1"
			Import-Module "D:\KCT0000382\SelfService\ACTIVITY LOGGER\StandardLogging.psm1"
			Import-module "D:\Automation Key\AutomationKeyPS.dll" # Used for authentication purpose [encryption and decryption]
		}	
	    	######################################## INPUTS ################################################################
			
	    }
	   
	   	catch
	   	{
	   
	   	}
		################################ Log Runbook Status ###########################################
    
    	try
    	{
        	$WriteOut = InlineScript
			{   
            	$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "0 - Start" "VIP-Creation" "$Using:VMName" "redmond\stpatcha" "" ""
        	}
    	}
    	catch
    	{
        	$WriteOut = InlineScript
			{  
            	$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "3 - Failure" "VIP-Creation" "$Using:VMName" "redmond\stpatcha" "" ""
        	}
    	}
	

		#Importing ITSM Module
		try
		{
			[System.AppDomain]::CurrentDomain.SetData("APP_CONFIG_FILE","D:\VM_Blade_FNR\VM\ITSM\ITSM\app.config")
			Import-Module "D:\ITSM\ITSM\obj\Debug\ITSM.dll"
			$ticket = Acknowledge-Ticket "$RFCNumber"
			$message = "Ticket picked up successfully by Orchestrator"
			$result = "Pass"
		}
		catch [System.exception]
		{
			$outputStatus = 1
			$message= $Error[0].Exception.Message.ToString().Replace("'","")
			$GCO_Error = "Error" 
			$result= "Fail"   
		}
		#########################################ITSM TICKET PICKUP ENDS####################################################

		######################################### INPUT VALIDATION - SCRIPT ############################################
		
		#New-Log $inputValidationLogPath  $inputValidationLogFile
		$date = Get-Date -Format dd-MMM-yyyy   
		$activityName = "Input Validation"
		$description = "Verifying and validating the user inputs"
		$errorStatus = "No Error"
		#Checking the mandatory fields are not empty.
		If (($serverName) -and ($rfcNumber)-and ($DataCenterName) -and($Ports) -and ($FQDN) -and($Loadbal) -and ($VIPOwnsecGrp) -and ($VIPOwnAlias) -and ($LTMName) -and ($FreeVIPIP) -and ($SNATFreeIP))
		{
			$outputDesc =  "All inputs are available"
			$outputStatus = "0"
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "1 - Input Validation" "Input entered for Node Name : $serverName 0" "$Using:VMName" "redmond\stpatcha" "" ""
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "1 - Input Validation" "Input entered for Data Centre Name : $DataCenterName 0" "$Using:VMName" "redmond\stpatcha" "" ""
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "1 - Input Validation" "Input entered for User name  : $userName" "$Using:VMName 0" "redmond\stpatcha" "" ""
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "1 - Input Validation" "Input entered for password  : ************* 0" "$Using:VMName" "redmond\stpatcha" "" ""
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "1 - Input Validation" "$outputDesc 0" "$Using:VMName" "redmond\stpatcha" "" ""
		}
		else
		{
			$outputDesc = "One or More inputs are Missing"
			$outputStatus = "10"
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "1 - Input Validation" "VM name  : $serverName 0" "$Using:VMName" "redmond\stpatcha" "" ""
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "1 - Input Validation" "VMM name  : $vmmName 0" "$Using:VMName" "redmond\stpatcha" "" ""
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "1 - Input Validation" "Username  : $userName 0" "$Using:VMName" "redmond\stpatcha" "" ""
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "1 - Input Validation" "$outputDesc 2" "$Using:VMName" "redmond\stpatcha" "" ""	
			Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus 10 -StatusDesc "KCT Failure" -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
			return
		}
		
		If ($outputStatus -eq "0")
		{ 
			$outputDesc = "Input Validation is Successful"
			$status = "Completed"
			$message = "Input Validation is Successful"
			Write-ActivityLog "$dbServerName"ù "$dbName"ù "$processID"  "$serverName"ù "$activityName" "$description" "$status"ù "$accountName" "$errorStatus" "$message"
		}
		######################################### Pre check - SCRIPT ############################################
		################################### Check Ping status of servers ####################################
		if ((Check-ServersConnection -server $serverName -logPath $inputValidationLogPath -logFile $inputValidationLogFile) -eq 10)
		{
			$outputStatus=10 
			$outputDesc = "One of the server is not reachable, kindly see the logs for more details"
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "2 - Check Server Reachability" "$outputDesc 2" "$Using:VMName" "redmond\stpatcha" "" ""
			Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus 10 -StatusDesc "KCT Failure" -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
			return
		}			
		################################### Check server IP Type#######################################
		$flag=0
		foreach ($server in $serverName)
		{
			$IPType=Check-DHCPEnabled -serverName $server,-cred $cred #Pass the server name and Credentials to this function and it will return 0 if the IP is DTCP or 1 in case of Static IP
			If ($IPType -eq 0)
			{
				$outputDesc = "IP type is Dynamic for one or more network adapters of $serverName" 
				$outputStatus = 10
				$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "$outputDesc" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
				$flag=10
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus 10 -StatusDesc "KCT Failure" -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
				return
			}
			else
			{
				$outputDesc = "IP type is Static for one or more network adapters of $serverName"
				$outputStatus=0
				$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "$outputDesc" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
			}
		}

		
		################################### Check if NLB is installed #######################################
		$flag=0
		foreach ($server in $serverName)
		{
			$outputStatus=Check-NLBStatus -Username $userName -Password $Password -serverName $server -logPath $inputValidationLogPath -logFile $inputValidationLogFile 
			if ($outputStatus -eq 10)
			{
				$flag = 10
			}
		}
		if ($flag -eq 10)
		{
			$outputDesc="One or more servers has NLB installed on them. See logs for more details"
			$outputStatus=10
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "$outputDesc" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
			Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus 10 -StatusDesc "KCT Failure" -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
			return
		}
		################################### Check if SQL is installed #######################################
		#Continue if SQL reporting service is installed.
		$flag=0
		foreach ($server in $serverName)
		{
			$outputStatus=Test-SQLInstalled -serverName $server -domainName $domainName -logPath $inputValidationLogPath -logFile $inputValidationLogFile #Calling SQL installation check function from PreCheckMod to Check if the server have SQL installed, it will return 0 as false and 1 as true
			if ($outputStatus -eq 10)
			{
				$flag = 10
			}
		}
		if ($flag -eq 10)
		{
			$outputDesc="One or more servers has SQL installed on them. See logs for more details"
			$outputStatus=10
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "$outputDesc" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
			Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus 10 -StatusDesc "KCT Failure" -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
			return
		}			
		
		######################################Check FQDN Connectivity########################################
		$outputStatus=Check-Connection -server $vipfqdn -logPath $inputValidationLogPath -logFile $inputValidationLogFile -treatFailureAsSuccess
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "5 - Check FQDN Connectivity" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
		if($outputStatus -eq 10)
			{
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus 10 -StatusDesc "KCT Failure" -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
				return
			}
		################################### Ping Check to VIP ###############################################
		$outputStatus=Check-Connection -server $VIPName -logPath $inputValidationLogPath -logFile $inputValidationLogFile  -treatFailureAsSuccess #Calling CheckConnection function from PreCheckMod to Check if the server is on-line 
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "6 - Ping Check to VIP" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
		if($outputStatus -eq 10)
			{
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus 10 -StatusDesc "KCT Failure" -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
				return
			}
		#################################Getting servers IP details #########################################
		$serverIPs = Get-IPAddress($servers)
		#################################Check port open status of servers ##################################
		$flag = 0
		foreach ($server in $serverName)
		{
			$outputStatus=Update-PortState -ComputerName $server -ports $Ports -VIPName $VIPName -logPath $logPath -logFile $logFile
			if ($outputStatus -ne 0)
			{
				$flag=10
			}
		}
		if ($flag -eq 10)
		{
			$outputDesc = "One or more servers has connectivity issue or the port is not opened. See logs for more details"
			$outputStatus = 10
			$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "$outputDesc" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
			Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus 10 -StatusDesc "KCT Failure" -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
			return
		}			
		################################### Server Data centre check ########################################
		if ($serverName -is [system.array])
		{
			$datacenter = $serverName[0].Substring(0,3)
			foreach ($server in $serverName)
			{
				if (!$server.StartsWith($datacenter))
				{
					$outputStatus=10
					$outputDesc = "Server: $server belongs to different data center"
					$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "$outputDesc" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
					Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus 10 -StatusDesc "KCT Failure" -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
					return
				}
			}
		}
		if (outputStatus -eq 0)
		{
			$outputStatus= Test-FQDN($VM_Blade_array,$logPath,$logFile)
		}
		################################### VIP IP Check ####################################################
		$outputStatus=Check-Connection -server $FreeVIPIP -logPath $inputValidationLogPath -logFile $inputValidationLogFile -treatFailureAsSuccess
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "7 - VIP IP Check" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
		$outputDesc = "VIP IP Check"
		if($outputStatus -eq 10)
		{
			Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
			return
		}
		
		################################### SNAT IP Check ###################################################
		$outputStatus=Check-Connection -server $SNATFreeIP -logPath $inputValidationLogPath -logFile $inputValidationLogFile -treatFailureAsSuccess
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "8 - SNAT IP Check" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""		
		$outputDesc = "SNAT IP Check"
		if($outputStatus -eq 10)
		{
			Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
			return
		}
		$outputDesc = "Pre-Check Successfully completed"
		Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Pre-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Success" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
		
		######################################Main Execution ################################################	
		
		
		
		################################### Create SNAT Pool ################################################
		$outputStatus=Create-SNATPool -vipfqdn $vipfqdn -snatIP $snatIP -userName $username - passWord $password -F5boxhostname $F5boxhostname
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "9 - SNAT IP Creation status" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
		$outputDesc = "SNAT Pool Creation"
		if($outputStatus -eq 10)
		{
			$outputDesc = "Error in SNAT Pool Creation"
			Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Performing Change" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
		}
		
		################################### Check Health Monitor Type #######################################
		#If Customized is selected then 
		if ($ExtenMon -eq "Customizes")
			{
			######################## Customized Health Monitor #######################
				$outputStatus=Create-HealthMonitor -templateName $templateName -templateType $templateType -templateInterval $templateInterval -templateTimeOut $templateTimeOut -userName $username -passWord $password -F5boxhostname $F5boxhostname
				$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "10 - Health Monitor Check" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
				$outputDesc = "Customized Health Monitor"
				if($outputStatus -eq 10)
					{	
						Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Performing Change" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
						return
					}
				Else
					{
						##############################Create VIP Pool ################################
						$outputStatus = Create-VIPPool $vipName $port $ips $lbMethod $monitoringEnabled $userName $passWord $F5boxhostname $logfilepath $LogfileName
						$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "10 - Health Monitor Check" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
						$outputDesc = "VIP Pool Created"
						if($outputStatus -eq 10)
								{
									Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Performing Change" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
									return
								}
					
					}
				
		########################## Check pool status #############################
		$outputStatus=Check-VIPName -VIPName $VIPName -LogFilePath $inputValidationLogPath -LogFileName $inputValidationLogFile)
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "11 - Pool Status Check" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
		$outputDesc = "Pool Status"
		if($outputStatus -eq 10)
			{	
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Performing Change" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputDesc -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
				return
			}
				
		################################### Persistence Profile #############################################
		######################## Create Persistence Profile######################
		$outputStatus = Create-Persistence -Persistence_Name $Persistence_Name -Cookie_Persistence_method_value $Cookie_Persistence_method_value -Cookie_Name $Cookie_Name -Cookie_Flag $Cookie_Flag -Persistence_Time $Persistence_Time -Persistence_Time_Flag $Persistence_Time_Flag
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "3 - Check Persistence status" "$Persistence_Status" "$Using:VMName" "redmond\stpatcha" "" ""
		$outputDesc = "Create PErsistence Profile"
		if($outputStatus -eq 10)
			{	
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Performing Change" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
				return
			}
		
	    ##############################Create VIP (VS)################################
				
		$VIP_status = Create-VIP -vip_Addr $vip_Addr -VS_Name $VS_Name -VS_Port $VS_Port -wildmask $wildmask -def_Pool_name $def_Pool_name -resource_Type $resource_Type
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "4 - Check VIP Creation status" "$VIP_status" "$Using:VMName" "redmond\stpatcha" "" ""
		$outputDesc = "Create VS"
		if($outputStatus -eq 10)
			{
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Performing Change" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
				return
			}
		########################## Verify VIP (VS)creation #############################
		$outputStatus = Check-ServersConnection -server $serverName -logPath $inputValidationLogPath -logFile $inputValidationLogFile
		$outputDesc = "One of the server is not reachable, kindly see the logs for more details"
		
		if($outputStatus -eq 10)
			{
				$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "Verify VIP Creation $outputdesc" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Performing Change" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
				return
			}
		
		################################### Adding route to all servers ######################################
		######################################################################################################
		$outputDesc = "This is to confirm that Execution of KCT0000382 was Successful."
		Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Performing Change" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Success" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
		####################################### Post Check Begin ################################################### 
		
		
		################################### Ping Check to VIP ###############################################
		$outputStatus=Check-Connection -server $VIPName -logPath $inputValidationLogPath -logFile $inputValidationLogFile  #Calling CheckConnection function from PreCheckMod to Check if the server is on-line 				
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "Ping VIP IP Check" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
		$outputDesc = "Ping check to VIP"
		if($outputStatus -eq 10)
			{
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Post-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
			 	return
			}
		################################### VIP IP Check ####################################################
		$outputStatus = Check-Connection -server $FreeVIPIP -logPath $inputValidationLogPath -logFile $inputValidationLogFile
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "Free VIP IP Check" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
		$outputDesc = "VIP IP Check"
		if($outputStatus -eq 10)
			{
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Post-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
			 	return
			}
		
		###############################Check port open status of VIP server #################################

		$outputStatus = Check-VIPPortStatus -VIPName $VIPName -Ports $Ports -logPath $inputValidationLogPath -logFile $inputValidationLogFile
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "Port open status of VIP Check" "$outputStatus" "$Using:VMName" "redmond\stpatcha" "" ""
		$outputDesc = "Check port open status of VIP server"
		if($outputStatus -eq 10)
			{
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Post-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
			 	return
			}
		################################### Performance post check ###########################################
		################################### Save and Syncing the configurations###############################
		################################### Creating DNS A record ######################
		
		$DNS_A_Record_Status = Create-DNSARecord -A_Record_Name $A_Record_Name -IPV4_Addr $IPV4_Addr -S_Name $S_Name -Zone_Name $Zone_Name
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "5 - Check DNS A Record status" "$DNS_A_Record_Status" "$Using:VMName" "redmond\stpatcha" "" "" 
		$outputDesc = "Create DNS Record"
		if($outputStatus -eq 10)
			{
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Post-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
			 	return
			}
		$outputDesc = "This is to confirm that Post check of KCT0000382 was seuccessful"
		Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Post-Check" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Success" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
		################################### Add the VIP Details to MyVIP Portal###############################
	   
	    ################################# CLOSE RFC SCRIPT ###################################################
	   
		#$ChangeTicketNumber="CMTESTRFC1234"
		$RoutingAlias="Fareast\v-ansess"
		$KCTNumber="KCT00000382"
      	### D:\SelfService\CloseRFC\RFCAckApplication.exe - Close RFC Module which need to copied to this location
		if($OutputStatus -eq 0)
		{
			try
			{
				$CloseRFC = InlineScript{
				D:\SelfService\CloseRFC\RFCAckApplication.exe "$using:ChangeTicketNumber" "$using:RoutingAlias" "$using:KCTNumber"}
			}
			catch{}
        }
	    "OutputStatus:$OutputStatus"
        "StatusDesc : $StatusDesc"
		
		################# Release Job Lock #################
		
        $JobCount = Get-AutomationVariable -Name "StaticIPJobLock"
    	$JobCount--
    	Set-AutomationVariable -Name "StaticIPJobLock" -Value $JobCount
    
       
		
   }
	 
}
	