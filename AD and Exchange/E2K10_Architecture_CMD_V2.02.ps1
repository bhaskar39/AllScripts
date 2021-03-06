####################################################################
# Exchange 2010 Architecture Report
#
# File : E2K10_Architecture_CMD.ps1
# Version : 2.0
# Author : Pascal Theil & Franck Nerot
# Author Mail : skall_21@hotmail.com & fnerot66@hotmail.com
# Creation date : 12/09/2011
# Modification date : 26/10/2011
#
# Exchange 2010
# 
####################################################################

#Argument control
$OK = $null
if ($args.count -eq 1)
    {
        if (($args[0] -ge 2) -and ($args[0] -le 15))
	{
		$OK =$TRUE
		$Threads = $args[0]
		Write-Host "Number of simultaneous jobs: " $Threads
	}
	else
	{
		Write-host -foregroundcolor "red" -backgroundcolor "black" "BAD ARGUMENT.`nUSAGE: <JOBSMAX> value must be between 2 and 15"
	}
    }
else
    {
        Write-host -foregroundcolor "red" -backgroundcolor "black" "ARGUMENT ERROR.`nUSAGE: E2K10_Architecture_V2_CMD.PS1 <JOBSMAX> where <JOBSMAX> is the maximum simultaneous jobs you want to launch. The value of <JOBSMAX> must be between 2 and 15"
    }

$Snaps = Get-PSSnapin -Registered
	foreach ($Snap in $Snaps)
		{
			if ($Snap.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010")
				{
					$OKSnap = $True
				}
		}
if ($OKSnap -ne $TRUE)
	{
		Write-host -foregroundcolor "red" -backgroundcolor "black" "SNAPIN ERROR.`nExchange 2010 Management Tools not installed on the Local Machine"
	}


if (($OK -eq $TRUE) -and ($OKSnap -eq $TRUE))
    {
        ##########################
		# Initializing variables #
		##########################
		$Mess=""
		$Cancelled = $null

		$labelElapsedTime = ""
		$Begin = $null
		$Stop = $null
		$Filename = $null
		$HTMLFile = $null
		$Final = $null
		$ALLTABLEJOBS = $null
		$ALLTABLEJOBS = @()
		$jobs = $null
		$job = $null
		
		###############	
		# MAIN REGION #
		###############
			
		$begin = Get-Date
		
        $LIST = get-content ".\scripts\JobsListCMD.txt"
 
			
				#Removing all current Jobs if needed
				$jobs = Get-Job
				if ($jobs -ne $null)
				{
					$a = 0
				Write-Host  "Clearing old jobs"
					foreach ($job in $jobs)
					{
						$a++
						Write-Progress -Activity "Clearing old jobs" -Status "Progress:" -PercentComplete ($a/$jobs.count*100)
						if ($job.state -eq "Running")
							{
								Stop-Job $job.id
								Remove-Job $job.id
							}
						else
							{
								Remove-Job $job.id
							}						
					}				
				}			
				
				#Generating Report Filename
				$Filename = ".\ArchitectureReport_" + $Begin.Hour + $Begin.Minute + "_" + $Begin.Day + "-" + $Begin.Month + "-" + $Begin.Year + ".htm"
				$jobs = @() 
			
				#Generating HTML Header
				Write-Progress -Activity "Creating Report Header" -Status "Progress:" -PercentComplete (0/1*100)
				Start-Job -Name "Header" -FilePath ".\Scripts\Header.ps1" | Out-Null
				wait-Job -Name "Header"	| Out-Null
				Write-Progress -Activity "Creating Report Header" -Status "Progress:" -PercentComplete (100)
				$HTMLFile = Receive-Job -Name "Header"
				Remove-Job -Name "Header"
			
				#Creating list of jobs that have been selected
				$a = 0
				foreach ($item in $LIST)
					{
						$a++
						$CurrentTime = Get-Date
								Write-Host $item.ToString()	
								Write-Progress -Activity "Creating list of jobs" -Status "Progress:" -PercentComplete ($a/$LIST.count*100)
								if ($item.ToString() -eq "Active Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Active Directory"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\ActiveDirectory.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}
						if ($item.ToString() -eq "Viewing SPN")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Viewing SPN"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\SetSPNView.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}
								if ($item.ToString() -eq "Duplicated SPN")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Duplicated SPN"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\SetSPNDupl.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}																		
								if ($item.ToString() -eq "Hardware Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Hardware Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\HardwareInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}
								if ($item.ToString() -eq "Disk Report Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Disk Report Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\DiskInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}	
								if ($item.ToString() -eq "Exchange Servers Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Exchange Servers Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\ExchangeServersInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}	
								if ($item.ToString() -eq "Exchange Services")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Exchange Services"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\ExchangeServices.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0	
										$ALLTABLEJOBS += $TABLE		
									}
								if ($item.ToString() -eq "Exchange Rollup (E2K7 Only)")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Exchange Rollup (E2K7 Only)"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\ExchangeRollupE2K7.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE		
									}									
								if ($item.ToString() -eq "Exchange Rollup (E2K10 Only)")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Exchange Rollup"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\ExchangeRollup.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE		
										
									}
								if ($item.ToString() -eq "Client Access Server Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\CASServerInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE										
									}
								if ($item.ToString() -eq "Client Access Server - OWA Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS OWA"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\CASOWA.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE										
									}
								if ($item.ToString() -eq "Client Access Server - WebServices Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS WebServices"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\CASWebservices.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Client Access Server - Autodiscover Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS Autodiscover"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\CASAutodiscover.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}
								if ($item.ToString() -eq "Client Access Server - OAB Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS OAB"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\CASOAB.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE										
									}
								if ($item.ToString() -eq "Client Access Server - ECP Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS ECP"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\CASECP.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}	
								if ($item.ToString() -eq "Client Access Server - ActiveSync Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS ActiveSync"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\CASActiveSync.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}	
								if ($item.ToString() -eq "Client Access Server - Powershell Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "PowershellVD"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\PowershellVD.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}									
								if ($item.ToString() -eq "Client Access Server - Exchange Certificates")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS Certificates"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\CASCertificates.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "HUB Transport - Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "HUB Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\HUBInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE										
									}
								if ($item.ToString() -eq "HUB Transport - Back Pressure (E2K10 Only)")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "HUB BackPressure"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\HUBBackPressure.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Database Availability Group - Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\DAGInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Database Availability Group - Network")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG Network"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\DAGNetwork.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Database Availability Group - Replication")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG Replication"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\DAGReplication.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
										
									}
								if ($item.ToString() -eq "Database Availability Group - DatabaseCopy")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG DBCopy"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\DAGDBCopy.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}
								if ($item.ToString() -eq "Database Availability Group - Backup")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG Backup"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\DAGBackup.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Database Availability Group - Database Size and Availability")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG DBSize"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\DAGDBSize.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Database Availability Group - RPCClientAccessServer")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG RPCClientAccessSRV"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\DAGRPCClientAccessServer.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Mailbox Server - Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\MBXInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}
								if ($item.ToString() -eq "Mailbox Server - Database Size and Availability")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX DBSize"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\MBXDBSIZE.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}
								if ($item.ToString() -eq "Mailbox Server - Backup")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX Backup"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\MBXBACKUP.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}	
								if ($item.ToString() -eq "Mailbox Server - RPCClientAccessServer")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX RPCClientAccessServer"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\MBXRPCClientAccessServer.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}										
								if ($item.ToString() -eq "Mailbox Server - Offline Address Book")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX OAB"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\MBXOAB.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}
								if ($item.ToString() -eq "Mailbox Server - Calendar Repair Assistant")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX Calendar RA"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\MBXCalRepairAssistant.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}											
								if ($item.ToString() -eq "Public Folder Databases")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Public Folder Databases"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\PublicFolderDB.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE		
									}
								if ($item.ToString() -eq "RPCClientAccess Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "RPCClientAccess Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\RPCClientAccess.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE		
									}									
								if ($item.ToString() -eq "Test Mailflow")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestMailflow"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\TestMailflow.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE										
									}
								if ($item.ToString() -eq "Test OWA Connectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestOWAConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\TestOWAConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test Web Services Connectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestWSConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\WEBServicesConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test ActiveSync Connectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestASConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\TestASConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test ECP Connectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestECPConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\TestECPConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test MAPI Connectivity - Mailbox and Public Folder Databases")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestMAPIConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\TestMAPIConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test OutlookConnectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestOLConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\TestOLConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test OutlookWebServices")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestOutlookWebServices"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\TestOutlookWebServices.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}	
								if ($item.ToString() -eq "Test PowershellConnectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestPowershellConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value ".\Scripts\TestPowershellConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}					
					}
				#Variables initialization for next loop
				$i = 0
				$StillJobsToRun = (@($ALLTABLEJOBS | Where-Object {$_.JOBLoaded -eq 0})).count
				$CurrentThreads = 0
				$jobs = @()
				#Looping While Cancel button is not clicked and all jobs have not been created. At the same time we check for not going beyond the number of maximum defined threads
				while ($StillJobsToRun -gt 0)
					{	
						$Inc = $Threads - $CurrentThreads					
						if ($CurrentThreads -lt $Threads)
							{
								$Max = $i +$Inc
								for ($j = $i ; $j -lt $Max ; $j++)
									{									
										if ($StillJobsToRun -eq 0)
										{										
											break;
										}
										else
										{
											$i++
											$jobs += Start-Job -Name $ALLTABLEJOBS[$j].JobName -FilePath $ALLTABLEJOBS[$j].Filepath
											$ALLTABLEJOBS[$j].JOBLoaded = 1		
											#Next "if" needed to complete the last job because $CompletedJobs is null for the last object
											if ($CompletedJobs -eq $null)
												{
													$CompletedJobs =0
												}
											$StillJobsToRun = (@($ALLTABLEJOBS | Where-Object {$_.JOBLoaded -eq 0})).count
										}
									
									}
								
							}
						$CurrentThreads = (@(Get-Job | Where-Object {$_.state -eq "Running"})).count
						$CompletedJobs = (@(Get-Job | Where-Object {$_.state -eq "Completed"})).count
						Write-Progress -Activity "Work in Progress" -Status "Waiting for running jobs. Jobs still to execute: $StillJobsToRun" -PercentComplete ($CompletedJobs/$LIST.count*100)
						Start-Sleep -Seconds 1
						
					} 
			
			#Waiting for last jobs to finish			
				$jobs = Get-Job| Where-Object{$_.state -eq "Running"}
				while ($jobs -ne $null)
					{
						$CurrentTime = Get-Date		
						$jobs = Get-Job| Where-Object{$_.state -eq "Running"}
						$CompletedJobs = (@(Get-Job | Where-Object {$_.state -eq "Completed"})).count
						$Still = $ALLTABLEJOBS.count - $CompletedJobs
						Start-Sleep 1
						Write-Progress -Activity "Waiting for last jobs to finish" -Status "Jobs still in Running state: $Still" -PercentComplete ($CompletedJobs/$LIST.count*100)
					}
				
				#Retrieving finished jobs
				$jobs = Get-Job | sort ID
				$a = 0
				foreach ($job in $jobs)
					{	
						Write-Progress -Activity "Merging Data" -Status $job.Name -PercentComplete ($a/$LIST.count*100)
						$CurrentTime = Get-Date				
						$Final = receive-job $job.ID
						$HTMLFile += $Final
						Remove-Job $job.ID
					}				
				#Compiling data returned by jobs
				$HTMLFile += Get-Content ".\scripts\footer.txt"
				$HTMLFile | out-file -encoding ASCII -filepath $Filename
	
			
		}

