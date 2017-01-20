###########################################Function1:services list###########################################

function ServiceInfo()
{
	[Int]$Count = 0
	$hostname ="."
	$service = get-wmiobject -class win32_service | where {$_.name -like '*MSSQLSERVER'}
	if($service.state -eq "Running" -or  $service.status -eq "OK")
	{
			$Services = Get-WmiObject win32_Service -Computer $hostname | where {$_.DisplayName -match "SQL Server"} | select DisplayName,StartMode,State
			foreach ( $service in $Services)
			{
				if ($service.StartMode -eq "Auto" -And $service.State -eq "Stopped")
				{	
					write-host "`n`n****************Auto Stopped Services list****************"`n `n 
					$DisplayName =$service.DisplayName
					$Mode =$service.StartMode
					$state = $service.State 
					write-host "Service Name : " $DisplayName
					write-host "StartMode    : " $Mode
					write-host "Status       : "$state `n `n
					[Int]$Count = $Count + 1
				}
				
			}
			if($Count -eq 0){write-host "Auto stopped Services are not found..."}
	}
	else
	{
			write-host " "
	} 
}

##########################################Function2:ClusteredInfo status#########################################
Function ClusteredInfo()
{
	param([String]$datasource)#,[string]$userid,[String]$Pwd)
		write-host "*************************checking the user access mode********************`n`n"
		$readconn = New-Object System.Data.OleDb.OleDbConnection
		#[string]$connstr="Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security Info=False;Data Source=BVRMLPT038;Initial Catalog=msdb;User ID=bvrmlpt038\pavan;Password=Janaki@9065"
		#[string]$connstr="Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security Info=False;Data Source=$datasource;Initial Catalog=msdb;User ID=$userid;Password=$Pwd"
        [string]$connstr="Provider=SQLOLEDB.1;Integrated Security=True;Persist Security Info=False;Data Source=$datasource;Initial Catalog=msdb"#;User ID=$userid;Password=$Pwd"
		$readcmd = New-Object system.Data.OleDb.OleDbCommand
		$readconn.connectionstring = $connstr
		$readconn.open()
		$readcmd.connection=$readconn
		$readcmd.commandtext = "select name as database_name,state_desc,user_access_desc from sys.databases where user_access_desc in ('SINGLE_USER')or state_desc not in ('ONLINE')"
		
		
		$reader = $readcmd.executereader()
		################################Checking Cluster status###################################################
		$readcmd1 = New-Object system.Data.OleDb.OleDbCommand
		$readcmd1.connection=$readconn
		$readcmd1.commandtext = "SELECT SERVERPROPERTY('ISclustered') as ISclustered"
		$reader1 = $readcmd1.executereader()
		do
		{
			while ($reader1.read() -eq "True")
			{
				[Int]$ISclustered = $reader1.Item("ISclustered")
				write-host "ISclustered Status : "$ISclustered
			}
		}
		While ($reader1.NextResult())
		$reader1.close()
		
		###################################################################################
		#[Int]$status = $reader.Item("ISclustered")
		do
		{
			while ($reader.read() -eq "True")
			{
				[String]$dbName = $reader.Item("database_name")
				write-host "Database Name : "$dbName
				[String]$stateDesc =$reader.Item("state_desc")
				write-host "State : "$stateDesc
				[String]$user_access = $reader.Item("user_access_desc")
				write-host "User Access Mode : "$user_access `n
				<#
				if( $user_access -eq "MULTI_USER")
				{
					write-host "user access mode is multiuser"
				}
				else
				{
					write-host "user access mode is singleuser"
				}
					#>	
			}
		}
		While ($reader.NextResult())
		
		
		$reader.close()
		
		Return $ISclustered
}

####################################################Function3:Nodenameinfoin each logfile#####################################

function errorlogsinfo
{
	param([String]$InputPath)
	
	write-host "***************************checking the cluster failover*********************************`n`n"
	#$Path = "C:\Program Files (x86)\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\"
	$Path = $InputPath
	##"D:\Automation Scripts\SQL Sanity Check\" 
	
	
	#write-host "directory path" $Path
	$latest = Get-ChildItem -Path $Path -Filter "ERROR*" | Sort-Object LastAccessTime -Descending | Select-Object -First 2
	$fileNames = $latest.Name
	#write-host "list of error files" $fileNames
	$serverName1 = @()
	foreach ($latestFile in $fileNames)
	{
			[String]$filepath = $Path + [String]$latestFile
			#write-host $filepath
			[String]$nodeNameslist = Get-ChildItem $filepath | Select-String -Pattern "NETBIOS"
			#write-host "hostnames is" $Hostname
			foreach($nodeName in $nodeNameslist)
			{
				$finalvalues = @()
				[String]$StrData = $nodeName
				#write-host "server name is" $nodeName
				$finalvalues = $StrData.Split("'")
				$serverName1 += $finalvalues[1] 				 
			}
			#write-host "final result is****************************" $finalvalues[1]			
				
	}
	#write-host "Final array : "$serverName1
	Return $serverName1
}	

##########################################################################################################

#Getting Service Info
ServiceInfo

import-module failoverclusters
$CName = Get-CluserNode | Get-ClusterResource
$datasource = (($CName | ?{$_.Name -like "SQL Network Name*"}).Name.Split("("))[0].Split(")")[0].trim()
$datasource

#$datasource = $args[0]
#$userid = $args[1]
#$Pwd = $args[2]
$IPath = $args[0]
<#write-host "--------------------------------------------"
write-host "given data source : "$datasource
write-host "given UserId : "$userid
write-host "given Password : "$Pwd
#>
#ClusteredInfo "$datasource" "$userid" "$Pwd"
[Int]$ClusterStatus = ClusteredInfo "$datasource"# "$userid" "$Pwd"


if([Int]$ClusterStatus -ne 0)
{
	[Array]$serverName = errorlogsinfo "$IPath"
	#write-host "outer array : "$serverName
	if($serverName[0] -eq $serverName[1])
	{
		write-host "Cluster failover is not done.............." #from $serverName[1] to $serverName[0]"
	}
	else
	{
		write-host "Cluster failover is done from "$serverName[1] "to" $serverName[0]
	}
}
else
{
	write-host "Cluster failover is not enabled...."`n`n
}