<#  
  .SYNOPSIS   
    Get the IP addresses in a range  
  .EXAMPLE  
   Get-IPrange -start 192.168.8.2 -end 192.168.8.20  
  .EXAMPLE  
   Get-IPrange -ip 192.168.8.2 -mask 255.255.255.0  
  .EXAMPLE  
   Get-IPrange -ip 192.168.8.3 -cidr 24  
#>
function Get-IPrange 
{ 
    param  
    (  
      [string]$start,  
      [string]$end,  
      [string]$ip,  
      [string]$mask,  
      [int]$cidr  
    )  
    function IP-toINT64 () 
    {  
      param ($ip)  
      $octets = $ip.split(".")  
      return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3])  
    }    
    function INT64-toIP() 
    {  
      param ([int64]$int)  
      return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() ) 
    }  
    if ($ip) 
    {
        $ipaddr = [Net.IPAddress]::Parse($ip)
    }  
    if ($cidr) 
    {
        $maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2)))) 
    }  
    if ($mask) 
    {
        $maskaddr = [Net.IPAddress]::Parse($mask)
    }  
    if ($ip) 
    {
        $networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)
    }  
    if ($ip) 
    {
        $broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))
    }  
    if ($ip) 
    {  
      $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring  
      $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring  
    } 
    else 
    {  
      $startaddr = IP-toINT64 -ip $start  
      $endaddr = IP-toINT64 -ip $end  
    }   
    for ($i = $startaddr; $i -le $endaddr; $i++)  
    {  
        INT64-toIP -int $i  
    } 
}
$ExistingIps = Get-Content E:\iplist.txt
$BoxName = "euschy644f5b4b"
$path = "C:\Users\v-bhde\Desktop\New folder\TestVIPs.csv"
$obj = Import-Csv $path -Header DeviceName,MgmtAddress,EgressAdd,SharedEgAdrss,BEAddress,SharedBEAdd,IntVIPRange,BPVIPRange,SnatRange -Delimiter "," | ForEach-Object {
            New-Object psobject -Property @{
                'Device Name' = $_.DeviceName;
                'Management Address' = $_.MgmtAddress;
                'Eggress Address' = $_.EgressAdd;
                'Shared Egr Address' = $_.SharedEgAdrss;
                'BE Address' = $_.BEAddress;
                'Shared BE Add' = $_.SharedBEAdd;
                'Int VIP Range' = $_.IntVIPRange;
                'BP VIP Range' = $_.BPVIPRange;
                'Snat Range' = $_.SnatRange;
            }
        }
$obj = $obj | Select -Skip 1

foreach($ob in $obj)
{
    if($ob.'Device Name' -ieq $BoxName)
    {
        $($ob.'Device Name')
        'Internet VIP Range:' + $($ob.'Int VIP Range')
        'Snat Range:' + $($ob.'Snat Range')
        $ip = ($ob.'Int VIP Range').Split("/")
        $IPRange = Get-IPrange -ip $ip[0] -cidr $ip[1]
        $freeIps = Compare-Object -ReferenceObject $IPRange -DifferenceObject $ExistingIps -PassThru #-re $IPRange $ExistingIps -PassThru
        $freeIps
    }
}
