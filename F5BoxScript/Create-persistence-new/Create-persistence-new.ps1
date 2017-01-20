Function Get-Inputs()
{
	
	try
	{
		#Read all lines in the input text file
		#$Lines = Get-Content -Path $ServersListPath;

		# Finds the value that user has selected.
#		foreach ($Line in $Lines)
#		    {
#		        $LineData = "$Line".Split("`t");
#		        if($LineData[0] -eq "Persistence_Type")
#		        {
#					$Type_OF_Persistence = $LineData[1]
#					#write-log $Type_OF_Persistence, 0
					$Type_OF_Persistence = "Simple"
					return $Type_OF_Persistence
#		        }
#				
#			}
			
	}
	
	catch [System.Exception]
	{
		$outputDesc = $_.Exception.message
		#write-log "$outputDesc", 0
		return 10
	}
	
}



Function Check-Persistence($VS_Name)
{
	try
	{
		$User_Persistence_Type_selected = Get-Inputs
		if(($User_Persistence_Type_selected) -and ($User_Persistence_Type_selected -eq "Simple"))
		{
			#
			$obj_F5 = Get-F5.iControl
			$Listof_persistence = $obj_F5.LocalLBProfilePersistence.get_list()
			$vippersistence = New-Object -TypeName icontrol.LocalLBVirtualServerVirtualServerPersistence
			if($listof_persistence -contains "/Common/source_addr")
			{$vippersistence.profile_name = "source_addr"
			 $obj_F5.LocalLBVirtualServer.add_persistence_profile($VS_Name,$vippersistence)
			 if($?)
			 {
			 	$outputststus = $obj_F5.LocalLBVirtualServer.get_persistence_profile($VS_Name)
				if($outputststus)
				{return 0}
				else
			 	{return 10}
			 }	
			 else
			 {	
			 	return 10
			 }
			} 
		}

           
	}
	catch [System.exception]
	{
		$outputDesc = $_.Exception.Message
		return 10
		#write-log "$outputDesc", 10
	}
}

Check-Persistence "VSDEM3"