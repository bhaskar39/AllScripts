$vipname=$args[0]
$snat=$args[1]
$userName=$args[2]
$password=$args[3]
$f5=$args[4]

Function Get-F5Connection($username,$password, $F5boxhostname)
{
	try
    {
        Add-PSSnapin iControlSnapIn
	    $password = ConvertTo-SecureString -String $password -AsPlainText -Force
	    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password
	    #Initialize connection with F5 box
	    Initialize-F5.iControl -HostName $F5boxhostname -PSCredentials $cred
	    if($? -eq $true)
	    {
	    	#Get-f5.iControl
		    $GetF5 = Get-F5.iControl 
		    return $GetF5
    	}
    	else
	    { 
		    Return 10
	    }
    }
    catch [system.exception]
	{
		Return 10			
	}
}

Function Create-SNATPool 
{
[CmdletBinding()]
    Param (
			[parameter(Mandatory=$true)]
            [String]$vipfqdn,
			[parameter(Mandatory=$true)]
            [String[]]$snatIP,
			[parameter(Mandatory=$true)]
            [String]$username,
			[parameter(Mandatory=$true)]
            [String]$password,
			[parameter(Mandatory=$true)]
            [String]$F5boxhostname

			)
	#$vipfqdn="testfqdn.test.com"
	#$vipname= $vipfqdn.split('.')
    $vipname= $vipfqdn
	$vipname1=$vipname
	$SnatPoolName="$vipname1" + "_sn" + "_pl"
    Add-PSSnapIn iControlSnapIn
	if ( (Get-PSSnapin | Where-Object { $_.Name -eq "iControlSnapIn"}) -ne $null )
	{   
		#Write-Log " Creating Connection to the F5box Device " 0
		
		$AuthObj = Get-F5Connection -username $username -password $password -F5boxhostname $F5boxhostname
		
		################# Getting the list of  Pools and checking already existed or not ###############
		$checkLBSnatpool=$AuthObj.LocalLBSNATPool.get_list()
		if($checkLBSnatpool -match $SnatPoolname)
		{
			#write-Log "SnatPool is already Exists " 2
			$outputstatus=10
		}
		else
		{  
			#Write-Log " SNAT Pool is not exists..Go ahead and create the SNAT" 0
			$createsnatpool=$AuthObj.LocalLBSNATPool.create_v2($SnatPoolName,$snatip)
			if($? -eq $true)
			{
				#write-Log "Sucessfully created the snatpool" 0
				$AuthObj.SystemConfigSync.save_configuration("/config/bigip.conf","SAVE_HIGH_LEVEL_CONFIG")
				$outputstatus=0
			}
			else 
			{
				#write-Log "Snatpool creation failed " 2
				$outputstatus=10
			}
		}
	}
	else
	{
		#write-log "Snatpool creation failed as iControlSnapIn is not installed" 2
		return 10
	}
	return $outputstatus
}

$status = Create-SNATPool -vipfqdn $vipname -snatIP $snat -username $userName -password $password -F5boxhostname $f5
$status

