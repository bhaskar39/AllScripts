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