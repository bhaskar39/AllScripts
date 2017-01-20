$outputStatus = Create-Persistence -Persistence_Name $Persistence_Name -Cookie_Persistence_method_value $Cookie_Persistence_method_value -Cookie_Name $Cookie_Name -Cookie_Flag $Cookie_Flag -Persistence_Time $Persistence_Time -Persistence_Time_Flag $Persistence_Time_Flag
		$activityLog = Write-ActivityLog "$Using:dbServer" "$Using:dbName" "$Using:TableName" "New" "$Using:RFCNumber" "3 - Check Persistence status" "$Persistence_Status" "$Using:VMName" "redmond\stpatcha" "" ""
		$outputDesc = "Create PErsistence Profile"
		if($outputStatus -eq 10)
			{	
				Send-EmailMessage -rfcNumber $rfcNumber -triggerBy "KCT0000382" -ActivityName "Performing Change" -ActionName "No EFL VIP" -ActionValue 10 -itsmpickup $ITSM_Tkt -OutputStatus $outputStatus -StatusDesc $outputDesc -result "Failure" -toAddress $mailId -ccAddress $ccMailId -bccAddress $bccMailId -mailUserName "fareast\mailadmin" -mailpassWord "mailpass" -fromAddress $fromMailId -attachment $attachment_logPath
				return
			}