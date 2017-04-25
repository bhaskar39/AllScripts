##getting database name from commandline args
[String]$SQLDBName = $args[0]
###############################Connecting MAP Local database and executing query ######################################
Function Get_Conn
{
param([String]$SqlQuery)
	Try
	{
		$SQLServer = "localhost" #use Server\Instance for named SQL instances! 
		#write-host "database name from input args: "$SQLDBName
		#"Map_SampleDB"
		$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"

		$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
		$SqlCmd.CommandText = $SqlQuery
		$SqlCmd.Connection = $SqlConnection

		$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
		$SqlAdapter.SelectCommand = $SqlCmd

		$DataSet = New-Object System.Data.DataSet
		$SqlAdapter.Fill($DataSet)
		$SqlConnection.Close()
		Return $DataSet
	}
	Catch 
	{
		$ErrorMessage = $_.Exception.Message
		$ErrorMessage = "Exception in Get_Conn Function:		"+$ErrorMessage
		write-host $ErrorMessage
 	}
}
###########################Executing query for getting device_number based on deviceName############################
Function Run_Query
{
param([String]$qry)

	Try
	{
		##Calling get_conn function for executing query and getting result set
		$DataSet = Get_Conn $qry
		#write-host "output value : "$DataSet.Tables[0]
		$getData = @{}
		##reading data from resultset...
		foreach ($Row in $DataSet.Tables[0].rows)
		{ 
			foreach ($column in $DataSet.Tables[0].columns)
			{ 
				$getData[$([String]$column).ToLower()] = $([String]$($Row.($column)))
			}	
		}
		return $getData
	}
	Catch 
	{
		$ErrorMessage = $_.Exception.Message
		$ErrorMessage = "Exception in Run_Query Function:		"+$ErrorMessage
		write-host $ErrorMessage
		$getData = @{}
		##if we didnt get any result then we need to place empty string 
		$getData.DeviceNumber = ""
		return $getData
 	}
}
###################################Executing vmware_inventory query and preparing result list###############################
Function Exec_vmware_inventory
{
param([String]$getDbQry)

	Try
	{
		##Calling get_conn function for executing query and getting result set
		#write-host "qry : "$getDbQry
		$DataSet = Get_Conn "$getDbQry"
		#write-host "column count : "$DataSet.Tables[0].columns.count
		#write-host "row count : "$DataSet.Tables[0].rows.count
		$getDbList = @()
		##reading data from result set
		foreach ($Row in $DataSet.Tables[0].rows)
		{ 
			$getData = @{}
			foreach ($column in $DataSet.Tables[0].columns)
			{ 
				##preparing dict as dynamic way..
				$getData[$([String]$column).ToLower()] = $([String]$($Row.($column)))
			}
			##preparing result list
			$getDbList += $getData
		}
		return $getDbList
	}
	Catch 
	{
		$ErrorMessage = $_.Exception.Message
		$ErrorMessage = "Exception in Exec_vmware_inventory Function:		"+$ErrorMessage
		write-host $ErrorMessage
 	}
}
#############################Executing assessment_inventory query and getting resultset###################################
Function Exec_assessment_inventory
{
param([String]$getDbQry)

	Try
	{
		##Calling get_conn function for executing query and getting result set
		$DataSet = Get_Conn $getDbQry
		#write-host "column count : "$DataSet.Tables[0].columns.count
		#write-host "row count : "$DataSet.Tables[0].rows.count	  
		$getDbList = @()
		foreach ($Row in $DataSet.Tables[0].rows)
		{ 
			$getData = @{}
			foreach ($column in $DataSet.Tables[0].columns)
			{ 
				if([String]$column -eq "computer_name")
				{
					#calling runquery function for getting device number--------------------------------------------
					$inputQry = "select DeviceNumber from AllDevices_Assessment.HardwareInventoryCoreView where ComputerName = '"+$([String]$($Row.("computer_name")))+"'"
					$result = Run_Query "$inputQry"
					[string]$device_number = $result.DeviceNumber
					#write-host "devicenumber : "$device_number
					$getData['devicenumber'] = $device_number
					#-------------------------------------------------------------------------------------
				}
				$getData[$([String]$column).ToLower()] = $([String]$($Row.($column)))
			}
			$getDbList += $getData
		}
		return $getDbList
	}
	Catch 
	{
		$ErrorMessage = $_.Exception.Message
		$ErrorMessage = "Exception in Exec_assessment_inventory Function:		"+$ErrorMessage
		write-host $ErrorMessage
 	}
}
##############################Executing Metrics summary query and executing result set####################################
Function Exec_metricSummary
{
param([String]$getDbQry)
	
	Try
	{
		$DataSet = Get_Conn $getDbQry
		#write-host "column count : "$DataSet.Tables[0].columns.count
		#write-host "row count : "$DataSet.Tables[0].rows.count		  
		$getDbList = @()
		$getData = @{}
		foreach ($Row in $DataSet.Tables[0].rows)
		{ 
			$getData['ComputerName'] = $([String]$($Row.("Machine Name")))
			#calling runquery function for getting device number--------------------------------------------
			$inputQry = "select DeviceNumber from AllDevices_Assessment.HardwareInventoryCoreView where ComputerName = '"+$([String]$($Row.("Machine Name")))+"'"
			$result = Run_Query "$inputQry"
			$device_number = $result.DeviceNumber
			#write-host "devicenumber : "$device_number
			$getData['devicenumber'] = $device_number
			#-------------------------------------------------------------------------------------
			$getData['CurrentOperatingSystem'] = $([String]$($Row.("Operating System")))
			$getData['Cpu'] = $([String]$($Row.("CPU")))	
			$getData['CPUSpeed'] = $([String]$($Row.("CPU Speed (GHz")))
			$getData['NumberOfCores'] = $([String]$($Row.("Cores")))
			$getData['MaximumCpuUtilization'] = $([String]$($Row.("Maximum CPU Utilization (%)")))
			$getData['CpuUtilization95thPercentile'] = $([String]$($Row.("95th Percentile CPU Utilization (%)")))
			$getData['SystemMemory'] = $([String]$($Row.("Memory (MB)")))	
			$getData['AverageMemoryUtilizationInGB'] = $([String]$($Row.("Average Memory Utilization (GB)")))
			$getData['MaximumMemoryUtilizationInGB'] = $([String]$($Row.("Maximum Memory Utilization (GB)")))
			$getData['MemoryUtilizationInGB95thPercentile'] = $([String]$($Row.("95th Percentile Memory Utilization (GB)")))
			$getData['AverageDiskIOPS'] = $([String]$($Row.("Average Disk IOPS")))
			$getData['MaximumDiskIOPS'] = $([String]$($Row.("Maximum Disk IOPS")))
			$getData['DiskIOPS95thPercentile'] = $([String]$($Row.("95th Percentile Disk IOPS")))
			$getData['AverageDiskWritesPerSec'] = $([String]$($Row.("Avg Disk Writes/sec")))
			$getData['MaximumDiskWritesPerSec'] = $([String]$($Row.("Max Disk Writes/sec")))
			$getData['DiskWritesPerSec95thPercentile'] = $([String]$($Row.("95th Percentile Disk Writes/sec")))
			$getData['AverageDiskReadsPerSec'] = $([String]$($Row.("Avg Disk Reads/sec")))
			$getData['MaximumDiskReadsPerSec'] = $([String]$($Row.("Max Disk Reads/sec")))
			$getData['DiskReadsPerSec95thPercentile'] = $([String]$($Row.("95th Percentile Disk Reads/sec")))
			$getData['AverageNetworkUtilizationInMBps'] = $([String]$($Row.("Average Network Utilization (MB/s)")))
			$getData['MaximumNetworkUtilizationInMBps'] = $([String]$($Row.("Maximum Network Utilization (MB/s)")))
			$getData['NetworkUtilizationInMBps95thPercentile'] = $([String]$($Row.("95th Percentile Network Utilization (MB/s)")))
			$getData['AverageNetworkByesSendPerSecInMBps'] = $([String]$($Row.("Avg Network Bytes Sent (MB/s)")))
			$getData['MaximumNetworkByesSendPerSecInMBps'] = $([String]$($Row.("Max Network Bytes Sent (MB/s)")))
			$getData['NetworkBytesRecvPerSecInMBpsPercentile'] = $([String]$($Row.("95th Percentile Network Bytes Received (MB/s)")))
			$getData['DiskDrive'] = $([String]$($Row.("Disk Drive")))
			$getData['DiskDriveSize'] = $([String]$($Row.("Disk Drive Size (GB)")))
			$getData['AverageDiskSpaceUtilizationInGB'] = $([String]$($Row.("Average Disk Space Utilization (GB)")))
			$getData['MaximumDiskSpaceUtilizationInGB'] = $([String]$($Row.("Maximum Disk Space Utilization (GB)")))
			$getData['DiskSpaceUtilizationInGB95thPercentile'] = $([String]$($Row.("95th Percentile Disk Space Utilization (GB)")))
			$getData['AverageDiskQueueLength'] = $([String]$($Row.("Avg Disk Queue Length")))	
			$getData['MaximumDiskQueueLength'] = $([String]$($Row.("Max Disk Queue Length")))
			$getData['DiskQueueLengthPercentile'] = $([String]$($Row.("95th Percentile Disk Queue Length")))
			$getData['AverageDiskReadQueueLength'] = $([String]$($Row.("Avg Disk Read Queue Length")))
			$getData['MaximumDiskReadQueueLength'] = $([String]$($Row.("Max Disk Read Queue Length")))
			$getData['DiskReadQueueLengthPercentile'] = $([String]$($Row.("95th Percentile Disk Read Queue Length")))
			$getData['AverageDiskWriteQueueLength'] = $([String]$($Row.("Avg Disk Write Queue Length")))
			$getData['MaximumDiskWriteQueueLength'] = $([String]$($Row.("Max Disk Write Queue Length")))
			$getData['DiskWriteQueueLengthPercentile'] = $([String]$($Row.("95th Percentile Disk Write Queue Length")))
			$getData['AverageDiskBytesSec'] = $([String]$($Row.("Avg Disk Bytes/sec")))
			$getData['MaximumDiskBytesSec'] = $([String]$($Row.("Max Disk Bytes/sec")))
			$getData['DiskBytesSecPercentile'] = $([String]$($Row.("95th Percentile Disk Bytes/sec"))) 
			$getDbList += $getData
		}
		return $getDbList
	}
	Catch 
	{
		$ErrorMessage = $_.Exception.Message
		$ErrorMessage = "Exception in Exec_metricSummary Function:		"+$ErrorMessage
		write-host $ErrorMessage
 	}
}
##############################preparing query for vmware_inventory and calling function############################
Try
{
	$getDbQry = "select * from [VMware_Inventory].[Host]"
	$vmware_inventory_list = Exec_vmware_inventory "$getDbQry"
	write-host $($vmware_inventory_list | convertto-json | out-string)

}
Catch 
{
	$ErrorMessage = $_.Exception.Message
	$ErrorMessage = "Exception in ne_onpremise_vmware_inventory:		"+$ErrorMessage
	write-host $ErrorMessage
}
########################Preparing qry for assessment_inventory and calling executing function######################
Try
{
	$getDbQry = "SELECT [ComputerName] as computer_name
		  ,[WMIStatus] as wmi_status
		  ,[SSHStatus] as ssh_status
		  ,[ComputerModel] as computer_model
		  ,[CurrentOperatingSystem] as os
		  ,[ServicePackLevel] as service_pack_level
		  ,[OsArchitecture] as os_architecture
		  ,[CpuArchitecture] as cpu_architecture
		  ,[ActiveNetworkAdapter] as active_network_adapter
		  ,[IPAddress] as ip_address
		  ,[DNSServer] as dns_server
		  ,[SubnetMask] as subnet_mask
		  ,[IPGateway] as ip_gateway
		  ,[RegisteredUserName] as registered_username
		  ,[Domain/Workgroup] as domain_workgroup
		  ,[NumberOfProcessors] as number_of_processors
		  ,[NumberOfCores] as number_of_cores
		  ,[Cpu] as cpu
		  ,[SystemMemory] as system_memory
		 ,[DiskDrive] as disk_drive
		  ,[DiskDriveSize] as disk_drive_size
		  ,[BIOsManufacturer] as bios_manufacturer
		  ,[MachineType] as machine_type
			 ,(Select [WinServer_Reporting].[GetServerRoleStr](sra.RoleId,'')) as role_name
	  FROM [AllDevices_Assessment].[HardwareInventoryView] Hwiv
	  left join [WinServer_Assessment].[ServerRoleAssessment] sra
	  on Hwiv.DeviceNumber = sra.DeviceNumber"

	$assessment_inventory_list = Exec_assessment_inventory "$getDbQry"
	
	write-host $($assessment_inventory_list | convertto-json | out-string)
}
Catch 
{
	$ErrorMessage = $_.Exception.Message
	$ErrorMessage = "Exception in ne_assessment_inventory_additional :		"+$ErrorMessage
	write-host $ErrorMessage
}

############################Preparing qry for PlacementMetricsSummary and calling executing function#######################

Try
{
	$getDbQry = "exec Perf_Reporting.PlacementMetricsSummary null"

	$metricSummary_list = Exec_metricSummary "$getDbQry"
	write-host $($metricSummary_list | convertto-json | out-string)
}
Catch 
{
	$ErrorMessage = $_.Exception.Message
	$ErrorMessage = "Exception in ne_onpremise_placementmetricssummary :		"+$ErrorMessage
	write-host $ErrorMessage
}
###################################################################################################

##preparing final jsonfile for uploading to diva

$finalJson = @{}
##adding key - values pairs to finaljson dict
$finalJson.vmware_inventory = $vmware_inventory_list
$finalJson.inventory_additional = $assessment_inventory_list
$finalJson.metricSummery = $metricSummary_list
##converting final dict to json string
$finalJson | convertto-json | out-file "assessment_sample.json"