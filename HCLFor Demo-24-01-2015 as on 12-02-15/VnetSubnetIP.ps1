
Function VnetSubnetIPValidation
{
    Param(
    [Parameter(Mandatory=$true)] 
    [string]$GivenSubNet,
    [Parameter(Mandatory=$true)] 
    [string]$GivenIPAddress,
    [Parameter(Mandatory=$true)] 
    [string]$GivenVnet,
    [Parameter(Mandatory=$true)] 
    [string]$Path,
    [Parameter(Mandatory=$true)] 
    [string]$Subscription,
    [Parameter(ParameterSetName="Affinity")] 
    [string]$AffinityGrp,
    [Parameter(ParameterSetName="Location")] 
    [string]$Location
    )
    
    [string]$IPAddressAll
    
    function Get-IPAddressrange
    {

        param 
        ( 

            [string]$AddressPrefix
     
        ) 
        

        function IPAddress-toINT64 () 
        { 
          param ($IPAddresss) 
          
           
          $octets = $IPAddresss.split(".") 
          return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
        } 
 
        function INT64-toIPAddress() 
        { 
          param ([int64]$int) 

          return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
        } 
 
       
        $SplittingAddress = $AddressPrefix.split("/")
        
        $IPAddress = $SplittingAddress[0]
        $CIDR = $SplittingAddress[1]
        
                 
        if ($IPAddress) 
        {
            $IPAddress = [Net.IPAddress]::Parse($IPAddress)
            
            
        } 
        if ($CIDR) 
        {
            
            
            $maskaddr = [Net.IPAddress]::Parse((INT64-toIPAddress -int ([convert]::ToInt64(("1"*$CIDR+"0"*(32-$CIDR)),2))))
            
                        
        } 
        if ($IPAddress) 
        {
            
            $networkaddr = new-object net.IPAddress($maskaddr.address -band $IPAddress.address)
            $networkaddr
            
        } 
        if ($IPAddress) 
        {
            $broadcastaddr = new-object net.IPAddress(([system.net.IPAddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))
            $broadcastaddr
        } 
 
        $startaddr = IPAddress-toINT64 -IPAddress  $networkaddr.IPAddressToString
        $endaddr = IPAddress-toINT64 -IPAddress $broadcastaddr.IPAddressToString
        
        #$startaddr
        #$endaddr
     
        for ($i = $startaddr; $i -le $endaddr; $i++) 
        { 
          $IPAddressAll = INT64-toIPAddress -int $i
          $IPAddressAll
        }

        #$IPAddressAll
        return $IPAddressAll
    
    }

    #Set-AzureSubscription -SubscriptionName $Subscription

    #$raw = Select-AzureSubscription -SubscriptionName $Subscription
    try
    {
        Get-AzureVNetConfig -ExportToFile "$Path\Vnetconfig.xml"
    
           
        [xml]$FileContent = Get-Content -Path "$Path\Vnetconfig.xml"

        $Vsites = $FileContent.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite

        if($AffinityGrp) ### IF-ELSE ADDED TO SUPPORT FOR REGIONAL WIDE VIRTUAL NETWORK
        {

            $AffinityGroupName = $FileContent.GetElementsByTagName("VirtualNetworkSite") | Where-Object {($_.name -ieq $GivenVnet) -and ($_.AffinityGroup -ieq $AffinityGrp)}

            if(($AffinityGroupName.AffinityGroup -ine $AffinityGrp))
            {
                Write-Host -ForegroundColor Red " The Vnet is not associated with the provided affinity group. Please provide the proper affinity group associated with Vnet"

                exit
            }
        }
        else
        {
            $IsLocation = $FileContent.GetElementsByTagName("VirtualNetworkSite") | Where-Object {($_.name -ieq $GivenVnet) -and ($_.Location -ieq $Location)}

            if(($IsLocation.Location -ine $Location))
            {
                Write-Host -ForegroundColor Red " The Vnet is not associated with the provided or Location. Please provide the proper affinity group associated with Vnet"

                exit
            }
        }

        $Sites = $Vsites.name

        if($Sites.Contains($GivenVnet))
        {
            $site = $Vsites | Where-Object { $_.name -imatch $GivenVnet}
       
            $SubNets = ($site.Subnets.Subnet).name
        
            $IPAddressPrefix = ($site.Subnets.Subnet | Where-Object { $_.name -eq $GivenSubNet}).AddressPrefix

            if($SubNets.Contains($GivenSubNet))
            {
            
                $IPAddressexist = (Test-AzureStaticVNetIP -IPAddress $GivenIPAddress -VNetName $GivenVnet).IsAvailable
                if($IPAddressexist)
                {
                
                    $IPAddressRanges = Get-IPAddressrange -AddressPrefix $IPAddressPrefix
                    $IPAddressRanges = $IPAddressRanges[4..($IPAddressRanges.Length -2)]
                
                
                    if($IPAddressRanges.Contains($GivenIPAddress))
                    {
                        return $true
                    }
                    else
                    {
                        Write-Host -ForegroundColor Red "Provided IPAddress falls beyond the Subnet Range in the Virtual Network or the IP address is not usable in this subnet"
                        return $false
                    }
            
                }
                else
                {
                    Write-Host -ForegroundColor Red "The Given IPAddress is already used.Please Select Another one."
                    return $false
                }

            }
            else
            {
                Write-Host -ForegroundColor Red "Provided Subnet does not exist in the Given Virtual Network."
                return $false
            }
        }
        else
        {
            write-host -ForegroundColor Red "Provided Virtual Network does not exist."
            return $false
        }

        Remove-Item -Path "$PSScriptRoot\Vnetconfig.xml"
    }
    catch [System.Exception]
    {
        Write-Host -ForegroundColor Red "Exception occured while executing the commands. It is due to the connectivity to internet"
        Throw $_
    }
}