<#
    .SYNOPSIS
    The script is to fetch the inventory information from MAP Tool database

    .DESCRIPTION
    The script is to fetch the inventory information from MAP Tool database

    .PARAMETER SQLDBName
    MAP Tool database name from where the inventory information can be fetched
    	
	.EXAMPLE
	C:\Generate_JsonInput.ps1 -SQLDBName master
#>
Param
(
    [Parameter(Mandatory=$true)]
    [string]$SQLDBName
)

Begin
{
    # Creating a timestamp for log file creation
    [DateTime]$LogFileTime = Get-Date
    $FileTimeStamp = $LogFileTime.ToString("dd-MMM-yyyy_HHmmss")
    $LogFileName = "$($MyInvocation.MyCommand.Name.Replace('.ps1',''))-$FileTimeStamp.log"
    $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
    $LogFilePath = "$PSScriptRoot\$LogFileName"
    $script:ExceptionCodes = New-Object System.Collections.ArrayList
    
    ################################ Function to create and update log file #############################################
    Function Write-LogFile
    {
        Param
        (
            [String]$LogText, 
            [Switch]$Overwrite = $false
        )

        $FilePath = $LogFilePath
        [DateTime]$LogTime = Get-Date
        $TimeStamp = $LogTime.ToString("dd-MMM-yyyy hh:mm:ss tt")
        $InputLine = "[$TimeStamp] : $LogText"

        If($FilePath -like "*.???")
        { $CheckPath = Split-Path $FilePath; }
        Else
        { $CheckPath = $FilePath }

        If(Test-Path -Path $CheckPath -ErrorAction SilentlyContinue)
        {
            # Correct path Now check if it is a File or Folder
            ($IsFolder = (Get-Item $FilePath -ErrorAction SilentlyContinue) -is [System.IO.DirectoryInfo]) | Out-Null
            If($IsFolder)
            {
                If($FilePath.EndsWith("\")) { $FilePath = $FilePath.TrimEnd(1) }
                $FilePath = "$FilePath\Log_$($LogTime.ToString('dd-MMM-yyyy_hh.mm.ss')).log"
            }
        }
        Else
        {
            Try
            {
                If(-not($FilePath -like "*.???"))
                {
                    If($FilePath.EndsWith("\")) { $FilePath = $FilePath.TrimEnd(1) }
                    $FilePath = "$FilePath\Log_$($LogTime.ToString('dd-MMM-yyyy_HH.mm.ss')).log"
                    (New-Item -Path $FilePath -ItemType File -Force -ErrorAction Stop) | Out-Null
                }
                Else
                {
                    (New-Item -Path $CheckPath -ItemType Directory -Force -ErrorAction Stop) | Out-Null
                }
            }
            Catch
            { 
                "Error creating output folder for Log file $(Split-Path $FilePath).`n$($Error[0].Exception.Message)"
            }
        }

        If($Overwrite)
        {
            $InputLine | Out-File -FilePath $FilePath -Force
        }
        Else
        {
            $InputLine | Out-File -FilePath $FilePath -Force -Append
        }
    }

    ###############################Connecting MAP Local database and executing query ######################################
    Function Get-Conn
    {
        Param
        (
            [String]$SqlQuery
        )

	    Try
	    {
            # SQL Server default instance.Use Server\Instance for named SQL instances! 
		    #$SQLServer = "(localdb)\maptoolkit" 
            $SQLServer = "localhost" 
    
            # Praparing the connection string
		    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		    $SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"
            
            # Making mutiple tries to create SQL Database connection incase of failures
            $RetryCount = 0
            while($RetryCount -lt 3)
            {
                try
                {
                    # trying to open SQL Connection. If no exception then break out of loop
                    #Write-LogFile -LogText "Tryining to open the SQL Connection"
                    $SqlConnection.Open()
                    break
                }
                catch
                {
                    $RetryCount += 1
                    continue
                }
            }

            # Checking if the connection is opened after multiple trials to Open SQL connection
            if($SqlConnection.State -eq 'Open')
            {
                # Preparing the SQL Command object
		        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
		        $SqlCmd.CommandText = $SqlQuery
		        $SqlCmd.Connection = $SqlConnection

                # Preparing the Data adapter to fill the dataset
		        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
		        $SqlAdapter.SelectCommand = $SqlCmd

                # Preparing the dataset object to hold data
		        $DataSet = New-Object System.Data.DataSet
		        $SqlAdapter.Fill($DataSet) | Out-Null
                # close the connection
		        $SqlConnection.Close() 
		        Return $DataSet
            }
            else
            {
                Write-LogFile -LogText "Unable to open the SQL Connection even after multiple trials. Error message: $($Error[0].Exception.Message)"
                Write-Host "Unable to open the SQL Connection even after multiple trials. Error message: $($Error[0].Exception.Message)"
                # return null object incase the connection was not opened
                # return $null
                exit
            }
	    }
	    Catch 
	    {
            # Incase of exception
		    $ErrorMessage = $_.Exception.Message
		    $ErrorMessage = "Exception in Get-Conn Function:"+$ErrorMessage
            # writing the exception message to log file
            Write-LogFile -LogText $ErrorMessage
            Write-Host $ErrorMessage
            # return null object incase of exceptions
            #return $null
            exit
 	    }
    }

    ###########################Executing query for getting device_number based on deviceName############################
    Function Run-Query
    {
        Param
        (
            [String]$qry
        )

	    Try
	    {
		    ##Calling Get-Conn function for executing query and getting result set
		    $DataSet = Get-Conn $qry
            
            # Object to hold the JSON Data
		    $getData = @{}
            
            # Checking if the returned data is not null
            if($DataSet -and $DataSet.Tables[0] -ne $null) # check the length
            {
		        ##reading data from resultset...
		        foreach ($Row in $DataSet.Tables[0].rows)
		        { 
			        foreach ($column in $DataSet.Tables[0].columns)
			        { 
				        $getData[$([String]$column).ToLower()] = $([String]$($Row.($column))) -replace '\n'," "
			        }	
		        }
            }
            else
            {
                Write-LogFile -LogText "Data was not found in database"
            }
		    return $getData
	    }
	    Catch 
	    {
            # Incase of any exception
		    $ErrorMessage = $_.Exception.Message
		    $ErrorMessage = "Exception in Run-Query Function:		"+$ErrorMessage
            # writing exception message to log file
            Write-LogFile -LogText $ErrorMessage
            # returning null JSON data incase of exception
		    $getData = @{}
		    ##if we didnt get any result then we need to place empty string 
		    $getData.DeviceNumber = ""
		    return $getData
 	    }
    }

    ###################################Executing vmware_inventory query and preparing result list###############################
    Function Get-VMWareInventory
    {
        Param
        (
            [String]$getDbQry
        )

	    Try
	    {
		    ##Calling Get-Conn function for executing query and getting result set
            Write-LogFile -LogText "Querying the database for vmware inventory data"
		    $DataSet = Get-Conn "$getDbQry"
            
            # Array to hold the object collection
		    #$getDbList = @()
            $getDbList = New-Object System.Collections.ArrayList

            # Checking if the returned data is not null
            if($DataSet -and $DataSet.Tables[0] -ne $null)
            {
                Write-LogFile -LogText "Fetched vmware onventory data"
		        ##reading data from result set
		        foreach ($Row in $DataSet.Tables[0].rows)
		        { 
			        $getData = @{}
			        foreach ($column in $DataSet.Tables[0].columns)
			        { 
				        ##preparing dict as dynamic way..
				        $getData[$([String]$column).ToLower()] = $([String]$($Row.($column))) -replace '\n'," "
			        }
			        ##preparing result list
			        $getDbList += $getData
		        }
            }
            else
            {
                Write-LogFile -LogText "VMWare inventory data was not found in database"
            }
		    return $getDbList
	    }
	    Catch 
	    {
            # Incase of any exceptions
		    $ErrorMessage = $_.Exception.Message
		    $ErrorMessage = "Exception in Get-VMWareInventory Function:		"+$ErrorMessage
            $script:ExceptionCodes += "Exception"
            # writing the exception message to log file
            Write-LogFile -LogText $ErrorMessage
            # Return the null data incase of exceptions
            return @()
 	    }
    }

    #############################Executing assessment_inventory query and getting resultset###################################
    Function Get-AssessmentInvenroty
    {
        Param
        (
            [String]$getDbQry
        )

	    Try
	    {
		    ##Calling Get-Conn function for executing query and getting result set
            Write-LogFile -LogText "Querying the database for assessment inventory data"
		    $DataSet = Get-Conn $getDbQry
            
            # Array to hold the object collection 
		    #$getDbList = @()
            $getDbList = New-Object System.Collections.ArrayList
            
            # Checking if the returned data is not null
            if($DataSet -and $DataSet.Tables[0] -ne $null)
            {
                Write-LogFile -LogText "Fetched the Assessment data and creating the custom JSON object"
		        foreach ($Row in $DataSet.Tables[0].rows)
		        { 
			        $getData = @{}
			        foreach ($column in $DataSet.Tables[0].columns)
			        { 
				        if([String]$column -eq "computer_name")
				        {
					        #calling runquery function for getting device number--------------------------------------------
					        $inputQry = "select DeviceNumber from AllDevices_Assessment.HardwareInventoryCoreView where ComputerName = '"+$([String]$($Row.("computer_name")))+"'"
					        $result = Run-Query "$inputQry"
					        [string]$device_number = $result.DeviceNumber
					        #write-host "devicenumber : "$device_number
					        $getData['devicenumber'] = $device_number
					        #-------------------------------------------------------------------------------------
				        }
                        $invntdata = $([String]$($Row.($column))) -replace '\n',","
                        #if($([String]$column).ToLower() -in ('disk_drive_size','disk_drive'))
                        #{
                        #    $invntdata = $invntdata.Substring(0,$invntdata.Length -1)
                        #}
                        if($invntdata.EndsWith(","))
                        {
                            $index = $invntdata.LastIndexOf(",")
                            $invntdata = $invntdata.Remove($index,1)
                        }
				        $getData[$([String]$column).ToLower()] = $invntdata
			        }
			        $getDbList += $getData
                }
		    }
            else
            {
                Write-LogFile -LogText "Assessment data was not found in the database"
            }
		    return $getDbList
	    }
	    Catch 
	    {
            # incase of any exceptions
		    $ErrorMessage = $_.Exception.Message
		    $ErrorMessage = "Exception in Get-AssessmentInvenroty Function:		"+$ErrorMessage
            $ExceptionCodes += "Exception"
            # writing the exception message to log file
            Write-LogFile -LogText $ErrorMessage
            # Return null object incase of exceptions
            return @()
 	    }
    }

    ##############################Executing Metrics summary query and executing result set####################################
    Function Get-MetricSummary
    {
        Param
        (
            [String]$getDbQry
        )
	
	    Try
	    {
            Write-LogFile -LogText "Querying the database for Metric summary"
		    $DataSet = Get-Conn $getDbQry
		  
            # Array to hold collection of data objects
		    #$getDbList = @()
            $getDbList = New-Object System.Collections.ArrayList
            # Dictionary to hold data object
		    
            
            # Checking if the returned data is not null
            if($DataSet -and $DataSet.Tables[0] -ne $null)
            {
                Write-LogFile -LogText "Fetched the Metric data and creating custom json object"
		        foreach ($Rw in $DataSet.Tables[0].rows)
		        { 
                    $getData = @{}
			        $getData['ComputerName'] = $([String]$($Rw.("Machine Name")))
			        #calling runquery function for getting device number--------------------------------------------
			        $inputQry = "select DeviceNumber from AllDevices_Assessment.HardwareInventoryCoreView where ComputerName = '"+$([String]$($Rw.("Machine Name")))+"'"
			        $result = Run-Query "$inputQry"
			        $device_number = $result.DeviceNumber
			        #write-host "devicenumber : "$device_number
			        $getData['devicenumber'] = $device_number
			        #-------------------------------------------------------------------------------------
			        $getData['CurrentOperatingSystem'] = $([String]$($Rw.("Operating System"))) -replace '\n'," "
			        $getData['Cpu'] = $([String]$($Rw.("CPU"))) -replace '\n'," "	
			        $getData['CPUSpeed'] = $([String]$($Rw.("CPU Speed (GHz"))) -replace '\n'," "
			        $getData['NumberOfCores'] = $([String]$($Rw.("Cores"))) -replace '\n',""
			        $getData['MaximumCpuUtilization'] = $([String]$($Rw.("Maximum CPU Utilization (%)"))) -replace '\n'," "
			        $getData['CpuUtilization95thPercentile'] = $([String]$($Rw.("95th Percentile CPU Utilization (%)"))) -replace '\n'," "
			        $getData['SystemMemory'] = $([String]$($Rw.("Memory (MB)"))) -replace '\n'," "
			        $getData['AverageMemoryUtilizationInGB'] = $([String]$($Rw.("Average Memory Utilization (GB)"))) -replace '\n'," "
			        $getData['MaximumMemoryUtilizationInGB'] = $([String]$($Rw.("Maximum Memory Utilization (GB)"))) -replace '\n'," "
			        $getData['MemoryUtilizationInGB95thPercentile'] = $([String]$($Rw.("95th Percentile Memory Utilization (GB)"))) -replace '\n'," "
			        $getData['AverageDiskIOPS'] = $([String]$($Rw.("Average Disk IOPS"))) -replace '\n'," "
			        $getData['MaximumDiskIOPS'] = $([String]$($Rw.("Maximum Disk IOPS"))) -replace '\n'," "
			        $getData['DiskIOPS95thPercentile'] = $([String]$($Rw.("95th Percentile Disk IOPS"))) -replace '\n'," "
			        $getData['AverageDiskWritesPerSec'] = $([String]$($Rw.("Avg Disk Writes/sec"))) -replace '\n'," "
			        $getData['MaximumDiskWritesPerSec'] = $([String]$($Rw.("Max Disk Writes/sec"))) -replace '\n'," "
			        $getData['DiskWritesPerSec95thPercentile'] = $([String]$($Rw.("95th Percentile Disk Writes/sec"))) -replace '\n'," "
			        $getData['AverageDiskReadsPerSec'] = $([String]$($Rw.("Avg Disk Reads/sec"))) -replace '\n'," "
			        $getData['MaximumDiskReadsPerSec'] = $([String]$($Rw.("Max Disk Reads/sec"))) -replace '\n'," "
			        $getData['DiskReadsPerSec95thPercentile'] = $([String]$($Rw.("95th Percentile Disk Reads/sec"))) -replace '\n'," "
			        $getData['AverageNetworkUtilizationInMBps'] = $([String]$($Rw.("Average Network Utilization (MB/s)"))) -replace '\n'," "
			        $getData['MaximumNetworkUtilizationInMBps'] = $([String]$($Rw.("Maximum Network Utilization (MB/s)"))) -replace '\n'," "
			        $getData['NetworkUtilizationInMBps95thPercentile'] = $([String]$($Rw.("95th Percentile Network Utilization (MB/s)"))) -replace '\n'," "
			        $getData['AverageNetworkByesSendPerSecInMBps'] = $([String]$($Rw.("Avg Network Bytes Sent (MB/s)"))) -replace '\n'," "
			        $getData['MaximumNetworkByesSendPerSecInMBps'] = $([String]$($Rw.("Max Network Bytes Sent (MB/s)"))) -replace '\n'," "
			        $getData['NetworkBytesRecvPerSecInMBpsPercentile'] = $([String]$($Rw.("95th Percentile Network Bytes Received (MB/s)"))) -replace '\n'," "
			        $dd = $([String]$($Rw.("Disk Drive"))) -replace '\n',","
                    if($dd.EndsWith(","))
                    {
                        $index = $dd.LastIndexOf(",")
                        $dd = $dd.Remove($index,1)
                    }
                    $getData['DiskDrive'] = $dd #.Substring(0,$dd.Length -1)
                    $dds = ($([String]$($Rw.("Disk Drive Size (GB)"))) -replace '\n',",")
                    if($dds.EndsWith(","))
                    {
                        $index = $dds.LastIndexOf(",")
                        $dds = $dds.Remove($index,1)
                    }
			        $getData['DiskDriveSize'] = $dds #.Substring(0,$dds.Length -1)
			        $getData['AverageDiskSpaceUtilizationInGB'] = $([String]$($Rw.("Average Disk Space Utilization (GB)"))) -replace '\n'," "
			        $getData['MaximumDiskSpaceUtilizationInGB'] = $([String]$($Rw.("Maximum Disk Space Utilization (GB)"))) -replace '\n'," "
			        $getData['DiskSpaceUtilizationInGB95thPercentile'] = $([String]$($Rw.("95th Percentile Disk Space Utilization (GB)"))) -replace '\n'," "
			        $getData['AverageDiskQueueLength'] = $([String]$($Rw.("Avg Disk Queue Length"))) -replace '\n'," "	 
			        $getData['MaximumDiskQueueLength'] = $([String]$($Rw.("Max Disk Queue Length"))) -replace '\n'," "
			        $getData['DiskQueueLengthPercentile'] = $([String]$($Rw.("95th Percentile Disk Queue Length"))) -replace '\n'," "
			        $getData['AverageDiskReadQueueLength'] = $([String]$($Rw.("Avg Disk Read Queue Length"))) -replace '\n'," "
			        $getData['MaximumDiskReadQueueLength'] = $([String]$($Rw.("Max Disk Read Queue Length"))) -replace '\n'," "
			        $getData['DiskReadQueueLengthPercentile'] = $([String]$($Rw.("95th Percentile Disk Read Queue Length"))) -replace '\n'," "
			        $getData['AverageDiskWriteQueueLength'] = $([String]$($Rw.("Avg Disk Write Queue Length"))) -replace '\n'," "
			        $getData['MaximumDiskWriteQueueLength'] = $([String]$($Rw.("Max Disk Write Queue Length"))) -replace '\n'," "
			        $getData['DiskWriteQueueLengthPercentile'] = $([String]$($Rw.("95th Percentile Disk Write Queue Length"))) -replace '\n'," "
			        $getData['AverageDiskBytesSec'] = $([String]$($Rw.("Avg Disk Bytes/sec"))) -replace '\n'," "
			        $getData['MaximumDiskBytesSec'] = $([String]$($Rw.("Max Disk Bytes/sec"))) -replace '\n'," "
			        $getData['DiskBytesSecPercentile'] = $([String]$($Rw.("95th Percentile Disk Bytes/sec"))) -replace '\n'," "
			        $getDbList += $getData
		        }
            }
            else
            {
                Write-LogFile -LogText "Metric summary data was not found in the database"
            }
		    return $getDbList
	    }
	    Catch 
	    {
            # incase of any exceptions
		    $ErrorMessage = $_.Exception.Message
		    $ErrorMessage = "Exception in Get-MetricSummary Function:		"+$ErrorMessage
            $script:ExceptionCodes += "Exception"
            # writing the exception to log file
            Write-LogFile -LogText $ErrorMessage
            # Return null object incase of exceptions
		    return @()
 	    }
    }

    function Out-FileUtf8NoBom 
    {

        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory, Position=0)] [string] $LiteralPath,
            [switch] $Append,
            [switch] $NoClobber,
            [AllowNull()] [int] $Width,
            [Parameter(ValueFromPipeline)] $InputObject
        )

        #requires -version 3

        # Make sure that the .NET framework sees the same working dir. as PS
        # and resolve the input path to a full path.
        [System.IO.Directory]::SetCurrentDirectory($PWD) # Caveat: .NET Core doesn't support [Environment]::CurrentDirectory
        $LiteralPath = [IO.Path]::GetFullPath($LiteralPath)

        # If -NoClobber was specified, throw an exception if the target file already
        # exists.
        if ($NoClobber -and (Test-Path $LiteralPath)) 
        {
            Throw [IO.IOException] "The file '$LiteralPath' already exists."
        }

        # Create a StreamWriter object.
        # Note that we take advantage of the fact that the StreamWriter class by default:
        # - uses UTF-8 encoding
        # - without a BOM.
        $sw = New-Object IO.StreamWriter $LiteralPath, $Append

        $htOutStringArgs = @{}
        if ($Width) 
        {
            $htOutStringArgs += @{ Width = $Width }
        }

        # Note: By not using begin / process / end blocks, we're effectively running
        #       in the end block, which means that all pipeline input has already
        #       been collected in automatic variable $Input.
        #       We must use this approach, because using | Out-String individually
        #       in each iteration of a process block would format each input object
        #       with an indvidual header.
        try 
        {
            $Input | Out-String -Stream @htOutStringArgs | % { $sw.WriteLine($_) }
        } 
        finally 
        {
            $sw.Dispose()
        }

    }

    Function Validate
    {
        Write-LogFile -FilePath $LogFilePath -LogText "Validating Parameters: SQLDBName."
        If([String]::IsNullOrEmpty($SQLDBName))
        {
            Write-LogFile -LogText "Validation failed.SQLDBName parameter value is empty."
            exit
        }
    }
}
Process
{
    Try
    {
        # Calling the function to Validate the Parameters
        Validate

        # preparing query for vmware_inventory and calling function
        Write-LogFile -LogText "Fecthing the vmware inventory data"
	    $getDbQry = "select * from [VMware_Inventory].[Host]"
	    $vmware_inventory_list = Get-VMWareInventory "$getDbQry"

        # Preparing qry for assessment_inventory and calling executing function
        Write-LogFile -LogText "Fetching the assessment inventory data"
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

	    $assessment_inventory_list = Get-AssessmentInvenroty "$getDbQry"

        # Preparing qry for PlacementMetricsSummary and calling executing function
        Write-LogFile -LogText "Fetching the Mentrics summary data"
        $getDbQry = "exec Perf_Reporting.PlacementMetricsSummary null"
	    $metricSummary_list = Get-MetricSummary "$getDbQry"

        ## preparing final jsonfile for uploading to diva
        Write-LogFile -LogText "Praparing the JSON Object with the data gathered"
        $finalJson = @{}

        ##adding key - values pairs to finaljson dict
        if($vmware_inventory_list -eq $null)
        {
            $finalJson.vmware_inventory = @()
        }
        else
        {
            $finalJson.vmware_inventory = $vmware_inventory_list
        }

        if($assessment_inventory_list -eq $null)
        {
            $finalJson.inventory_additional = @()
        }
        else
        {
            $finalJson.inventory_additional = $assessment_inventory_list
        }

        if($metricSummary_list -eq $null)
        {
            $finalJson.metricSummery = @()
        }
        else
        {
            $finalJson.metricSummery = $metricSummary_list
        }
        

        ##converting final dict to json string
        Write-LogFile -LogText "Praparing the JSON Object with the data gathered"
        #$finalJson | convertto-json -Depth 5 | out-file -FilePath "$PSScriptRoot\assessment_sample.json" -Force # "assessment_sample.json"
        #$finalJson | convertto-json | out-file -FilePath "$PSScriptRoot\assessment_sample1.json" -Force
        $finalJson | convertto-json | Out-FileUtf8NoBom -LiteralPath "$PSScriptRoot\assessment_sample.json"
        #$MyFile = Get-Content "$PSScriptRoot\assessment_sample1.json"
        #$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $true
        #[System.IO.File]::WriteAllLines("$PSScriptRoot\assessment_sample.json", $MyFile, $Utf8NoBomEncoding)
        #Remove-Item -Path "$PSScriptRoot\assessment_sample1.json" -Force

    }
    Catch 
    {
        # incase of any exception in above logic
	    $ErrorMessage = $_.Exception.Message
	    $ErrorMessage = "Exception in ne_onpremise_placementmetricssummary :		"+$ErrorMessage
        # Writing message to log file
        Write-LogFile -LogText $ErrorMessage
        Write-Host "There was an exception: $ErrorMessage"
        exit
    }
}
End
{
    # Execution completed
    if($script:ExceptionCodes)
    {
        Write-LogFile -LogText "Script execution completed. However there arefew exceptions found. Please check the log file and JSON file and re-try the script."
        Write-host "Script execution completed. However there are few exceptions found. Please check the log file and JSON file and re-try the script."
    }
    else
    {
        Write-LogFile -LogText "Script execution completed successfully."
        Write-host "Script execution completed successfully."
    }
    exit
}

