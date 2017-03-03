<#
    .SYNOPSIS
    Script to get the server information i.e Roles, features and applicaitions

    .DESCRIPTION
    Script to get the server information i.e Roles, features and applicaitions

    .PARAMETER CSVFilePath
    Servers list in csv format with credentials
	
	.AUTHOR
	Bhaskar Desharaju - bhaskar.desharaju@netenrich.com
	
	.EXAMPLE
	C:\inventory.ps1 -CSVFilePath C:\ServerList.csv
	
#>
Param
(
	[Parameter(Mandatory=$true)]
	[string]$CSVFilePath
)

try
{
	# Disabling the progress status popups
    $ProgressPreference = "SilentlyContinue"
    
	# Checking for the existence of the provided file
    if(Test-Path -Path $CSVFilePath)
    {
        $CSVdata = Import-Csv -Path $CSVFilePath

		# Importing the servermanager modules to fetch the roles and features
        Import-Module ServerManager
        $AllCollections = New-Object System.Collections.ArrayList
        foreach($server in $CSVdata)
        {
			# Checking the rechability of the server
            $ServerStatus = Get-WmiObject -Class Win32_PingStatus -Filter "Address=`'$($server.ServerNames)`'"
            if($ServerStatus.StatusCode -eq 0)
            {
                $o = New-Object psobject
                $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
                $hostname = $env:COMPUTERNAME
				
				# If the given server is the current server from where the script is being executed. Credentials are not required, else required
				# Feteching the installed applications
                if($server.ServerNames -eq $hostname)
                {
                    $InstalledApplications = Get-WmiObject -Namespace "root/cimv2" -Class Win32_Product -ErrorAction SilentlyContinue | Select Name, Version
                }
                else
                {
                    $Creds = New-Object System.Management.Automation.PSCredential ($server.UserName, (ConvertTo-SecureString -AsPlainText -String $server.Password -Force))
                    $InstalledApplications = Get-WmiObject -Namespace "root/cimv2" -Class Win32_Product -ComputerName $server.ServerNames -Credential $Creds -ErrorAction SilentlyContinue | Select Name, Version
                }
				
				# Generating the CSV file with server name for each server provided in list
                $raw = $InstalledApplications | Export-Csv -Path "$PSScriptRoot\$($server.ServerNames).csv" -NoTypeInformation -Force
                $o | Add-Member -MemberType NoteProperty -Name ServerName -Value $server.ServerNames
				
				# Fetching all features related to RDS
                if($server.ServerNames -eq $hostname)
                {
                    $RDSFeatures = Get-WindowsFeature -Name 'RDS-*' # -ComputerName $server.ServerNames -Credential $Creds
                }
                else
                {
                    $RDSFeatures = Get-WindowsFeature -Name 'RDS-*' -ComputerName $server.ServerNames -Credential $Creds
                }
            
                $RDSCon = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Connection-Broker'}
                if($RDSCon.InstallState -eq "Installed")
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Connection Broker' -Value "Yes"
                }
                else
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Connection Broker' -Value "No"
                }
                $RDSGW = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Gateway'}
                if($RDSGW.InstallState -eq "Installed")
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Gateway' -Value "Yes"
                }
                else
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Gateway' -Value "No"
                }
                $RDSLic = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Licensing'}
                if($RDSLic.InstallState -eq "Installed")
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Licensing' -Value "Yes"
                }
                else
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Licensing' -Value "No"
                }
                $RDSSSH = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-RD-Server'}
                if($RDSSSH.InstallState -eq "Installed")
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Session Host' -Value "Yes"
                }
                else
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Session Host' -Value "No"
                }
                $RDSWeb = $RDSFeatures | Where-Object {$_.Name -eq 'RDS-Web-Access'}
                if($RDSWeb.InstallState -eq "Installed")
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Web Access' -Value "Yes"
                }
                else
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'RDS Web Access' -Value "No"
                }
                if($server.ServerNames -eq $hostname)
                {
                    $PrintServices = Get-WindowsFeature -Name 'Print-Services' #-ComputerName $server.ServerNames -Credential $Creds
                }
                else
                {
                    $PrintServices = Get-WindowsFeature -Name 'Print-Services' -ComputerName $server.ServerNames -Credential $Creds
                }
                if($PrintServices.InstallState -eq 'Installed')
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'Print Services' -Value "Yes"                
                }
                else
                {
                    $o | Add-Member -MemberType NoteProperty -Name 'Print Services' -Value "No"
                }
                #$AllCollections += $o
            }
			# if the Server is not reachable, mention it as Not reachable
            else
            {
                $o = New-Object psobject
                $o | Add-Member -MemberType NoteProperty -Name ServerName -Value $server.ServerNames
                $o | Add-Member -MemberType NoteProperty -Name 'RDS Connection Broker' -Value "Not Reachable"
                $o | Add-Member -MemberType NoteProperty -Name 'RDS Gateway' -Value "Not Reachable"
                $o | Add-Member -MemberType NoteProperty -Name 'RDS Licensing' -Value "Not Reachable"
                $o | Add-Member -MemberType NoteProperty -Name 'RDS Session Host' -Value "Not Reachable"
                $o | Add-Member -MemberType NoteProperty -Name 'RDS Web Access' -Value "Not Reachable"
                $o | Add-Member -MemberType NoteProperty -Name 'Print Services' -Value "Not Reachable"
            }
            $AllCollections += $o
        }
		# Creating the final report with all details
        $raw = $AllCollections | Export-Csv -Path "$PSScriptRoot\ServerInventory.csv" -NoTypeInformation -Force
        $ProgressPreference = "Continue"
    }
    else
    {
        Write-Output "The Provided path for CSV does not exist"
        exit 1
    }
}
catch
{ 
    Write-Output "There was an exception. $($error[0])"
    exit 1
}