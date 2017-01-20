

	
Function Get-F5Connection($username, $password, $F5boxhostname)
{
    try
	{
		Add-PSSnapin iControlSnapIn
	    $password = ConvertTo-SecureString -String $password -AsPlainText -Force
	    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password
	    Initialize-F5.iControl -HostName $F5boxhostname -PSCredentials $cred
	    if($? -eq $true)
	    {
	        Write-Host " Successfully connected to the f5 Device"
	        #Get-f5.iControl
	        $GetF5 = Get-F5.iControl 
	        return $GetF5
	    }
	    else
	    { 
	        Return 10
			###write-log "Connectivity Failed `t $outputDesc", 2
	    }
	}		
	catch [System.exception]
	{
		$outputDesc = $_.Exception.Message
		return 1 
		###write-log "Connectivity Failed `t $outputDesc", 2
	}			
}
#------------ This property is not tested yet------
Function Persistence_created($strpersistenceProfileName, $VS_Name)
{
	try
	{
		if(($strpersistenceProfileName) -and ($VS_Name))
		{
			 $Ret_Val = New-Object -TypeName iControl.LocalLBVirtualServer
             $Persistence_Profile_List = $Ret_Val.get_persistence_profile($VS_Name)
			 if($Persistence_Profile_List -contains $strpersistenceProfileName)
			 	{ Return 0 }
			 else	
			 	{ Return 1 }
		}	
	}
	catch [System.exception]
	{
		$outputDesc = $_.Exception.Message
		return 1 
		###write-log "$outputDesc", 2
	}
}

#Call the function and check if it connected with F5 box by using below commands:
$GetF5=Get-F5Connection -username $username -password $password -F5boxhostname $F5boxhostname
if ($GetF5 -eq 10)
{
	##write-log "Unable to connect with the F5 box." 2
}


#--------Synopsis----------------------------------
#Author: Vidya Hirlekar
#Name of Function: Create_Persistence
#Number of arguements: 6
#Description: Generic function for creating any of the 5 types of persistence.
#			  Accepts arguements and creates the persistence accordingly.
#			  Assigns the values accordingly.
#Date of creation: 18-June-2015
#Expected values of arguements: If no value is to be passed, it must be assigned as "Blank"
#-----------------------------------------------------------------------------------------

Function Create_Persistence($Persistence_Name, $Cookie_Persistence_method_value, $Cookie_Name, $Cookie_Flag, $Persistence_Time, $Persistence_Time_Flag)
{
	
	try
		{
			$mode = New-Object -TypeName iControl.LocalLBPersistenceMode;
			$mode ="PERSISTENCE_MODE_COOKIE";
			$modes=(,$mode)
			if(($Persistence_Name -ne "Blank") -and ($modes))
			{
				$GetF5.LocalLBProfilePersistence.create($Persistence_Name,$modes);
			}
			# Sets the Persistence properties
			$method1 = New-Object -TypeName iControl.LocalLBProfileCookiePersistenceMethod;
			if($Cookie_Persistence_method_value -ne "Blank")
			{
				$method1.value = $Cookie_Persistence_method_value #"COOKIE_PERSISTENCE_METHOD_INSERT"; 
				$methods=(,$method1); 
			}	
			(Get-F5.iControl).LocalLBProfilePersistence.set_cookie_persistence_method($profiles,$methods); #----$Profiles and $methods is not assigned any value in the original code..
			$cookieName = New-Object -TypeName iControl.LocalLBProfileString;
			if($cookieName)
			{
				if($Cookie_Name -ne "Blank")
				{
					$cookieName.value = $Cookie_Name;
				}
				if($Cookie_Flag -ne "Blank")
				{
					$cookieName.default_flag = $Cookie_Flag
				}
				$cookieNames = (, $cookieName);
				if($Cookie_Name -ne "Blank")
				{
					$GetF5.LocalLBProfilePersistence.set_cookie_name($Cookie_Name,$cookieNames);
				}
			}
			$time = New-Object -TypeName iControl.LocalLBProfileULong;
			if($time)
			{
				if($Persistence_Time -ne "Blank")
				{
					$time.value=$Persistence_Time
				}
				if($Persistence_Time_Flag)
				{
					$time.default_flag = $Persistence_Time_Flag
				}
				$times=(,$time); 
				if($Cookie_Name -ne "Blank") 
				{
					$GetF5.LocalLBProfilePersistence.set_cookie_expiration($Cookie_Name,$times);
				}	
			}
			
			##write-log "Persistence Created.", 1
	}
	catch [System.exception]
	{
			$outputDesc = $_.Exception.Message
			return 1 
			##write-log "$outputDesc", 2
	}
}	

#--------Synopsis-------------------------------------------
#Author: Vidya Hirlekar
#Name of Function: Add_Profile_VS
#Number of arguements: 3
#Description: Generic function to Add Profile to VS for any of the 5 types of persistence.
#			  Accepts arguements and add the Profile to VS accordingly.
#			  
#Date of creation: 18-June-2015
#Expected values of arguements: If no value is to be passed, it must be assigned as "Blank"
#-----------------------------------------------------------------------------------------
	
Function Add_Profile_VS($Profile_Context_typ, $strProfileName, $VS_Name)
{
	try
	{
		$vipprofilehttp = New-Object "iControl.LocalLBVirtualServerVirtualServerProfile"
		if($Profile_Context_typ -ne "Blank")
		{
			$vipprofilehttp.profile_context = $Profile_Context_typ # Example Value ----- "PROFILE_CONTEXT_TYPE_ALL";
		}
		if($strProfileName -ne "Blank")
		{
			$vipprofilehttp.profile_name = $strProfileName #----- Input for cookie type persistence should be --- 'https';
		}
		if(($VS_Name -ne "Blank") -and ($vipprofilehttp -ne $null))
		{
			$GetF5.LocalLBVirtualServer.Add_profile($VS_Name,(,$vipprofilehttp))
		}
		##write-log "Profile Successfully added to the VS", 1
	}
	catch [system.Exception]
	{
		$outputDesc = $_.Exception.Message
		return 1 
		##write-log "$outputDesc", 2
	}
	#$GetF5.LocalLBVirtualServer.remove_profile("demo_80_vs",(,$vipprofilehttp))
}
	#-------Add Persistence to VS---------
<#
	
#--------Synopsis----------------------------------
#Author: Vidya Hirlekar
#Name of Function: Add_Persistence_VS
#Number of arguements: 2
#Description: Generic function to Add Persistence to VS for any of the 5 types of persistence.
#			  Accepts arguements and add the PErsistence to VS accordingly.
#			  
#Date of creation: 18-June-2015
#Expected values of arguements: If no value is to be passed, it must be assigned as "Blank"
#-----------------------------------------------------------------------------------------
#>

Function Add_Persistence_VS($strpersistenceProfileName, $VS_Name)
{
	try
	{
		$vippersistence = New-object -TypeName iControlLocalLBVirtualServerVirtualServerPersistence;
		if($strpersistenceProfileName -ne "Blank")
		{
			$vippersistence.profile_name = $strpersistenceProfileName # Example value --- "source_addr"
		}	
		$vippersistence.default_profile = $null
		if(($VS_Name -ne "Blank") -and ($vippersistence))
		{
			$GetF5.LocalLBVirtualServer.add_persistence_profile($VS_Name,$vippersistence)
		}
		##write-log "Persistence Successfully added to the VS", 1
	}
	catch [System.Exception]
	{
		$outputDesc = $_.Exception.Message
		return 1 
		##write-log "$outputDesc", 2
	}
}

$Type_OF_Persistence = "Simple" #-------------- Comes as User IP.
switch ($Type_OF_Persistence) #----------- This is user input variable

{
    Simple  {
				$strpersistenceProfileName = "source_addr"
				If(Persistence_created($strpersistenceProfileName) -ne $null)
				{
					$Persistence_Name = 
					$Cookie_Persistence_method_value =
					$Cookie_Name =
					$Persistence_Time =
					$Persistence_Time_Flag =
					Create_Persistence $Persistence_Name $Cookie_Persistence_method_value $Cookie_Name $Persistence_Time $Persistence_Time_Flag      # Call the function
					
					$Profile_Context_typ =
					$strProfileName = 
					$VS_Name = 
					Add_Profile_VS $Profile_Context_typ $strProfileName $VS_Name
					Add_Persistence_VS $strpersistenceProfileName, $VS_Name
					break
				}
				
		    }
	Cookie[Active] 
			{
				If(Persistence_created -eq $false)
				{	
					$strProfileName = "https"
					$Profile_Context_typ =
					$strProfileName = 
					$VS_Name = 
					Add_Profile_VS $Profile_Context_typ $strProfileName $VS_Name
					$Persistence_Name = 
					$Cookie_Persistence_method_value =
					$Cookie_Name =
					$Persistence_Time =
					$Persistence_Time_Flag =
					Create_Persistence $Persistence_Name $Cookie_Persistence_method_value $Cookie_Name $Persistence_Time $Persistence_Time_Flag      # Call the function
					$strpersistenceProfileName = "Cookie"
					Add_Persistence_VS $strpersistenceProfileName, $VS_Name
					break
					#--------------------------------------------------------
				}		
				
		    }
    HTTP/SSL
			{
				If(Persistence_created -eq $false)
				{
					$Persistence_Name = 
					$Cookie_Persistence_method_value =
					$Cookie_Name =
					$Persistence_Time =
					$Persistence_Time_Flag =
					Create_Persistence $Persistence_Name $Cookie_Persistence_method_value $Cookie_Name $Persistence_Time $Persistence_Time_Flag      # Call the function
					$strpersistenceProfileName = "HTTP/SSL"
					$Profile_Context_typ =
					$strProfileName = 
					$VS_Name = 
					Add_Profile_VS $Profile_Context_typ $strProfileName $VS_Name
					Add_Persistence_VS $strpersistenceProfileName, $VS_Name
					break
				}	
		    }
    RDP 	{
				If(Persistence_created -eq $false)
				{
					$Persistence_Name = 
					$Cookie_Persistence_method_value =
					$Cookie_Name =
					$Persistence_Time =
					$Persistence_Time_Flag =
					Create_Persistence $Persistence_Name $Cookie_Persistence_method_value $Cookie_Name $Persistence_Time $Persistence_Time_Flag      # Call the function
					$strpersistenceProfileName = "Microsoft RDP"
					$Profile_Context_typ =
					$strProfileName = 
					$VS_Name = 
					Add_Profile_VS $Profile_Context_typ $strProfileName $VS_Name
					Add_Persistence_VS $strpersistenceProfileName, $VS_Name
					break
				}
		    }
    Persistence_across_services 
			{
				If(Persistence_created -eq $false)
				{
					$Persistence_Name = 
					$Cookie_Persistence_method_value =
					$Cookie_Name =
					$Persistence_Time =
					$Persistence_Time_Flag =
					Create_Persistence $Persistence_Name $Cookie_Persistence_method_value $Cookie_Name $Persistence_Time $Persistence_Time_Flag      # Call the function
					$strpersistenceProfileName = "Across Services"
					$Profile_Context_typ =
					$strProfileName = 
					$VS_Name = 
					Add_Profile_VS $Profile_Context_typ $strProfileName $VS_Name
					Add_Persistence_VS $strpersistenceProfileName, $VS_Name
					break
				}
		    }
			
	None
			{
				break
		    }
			
}			
		