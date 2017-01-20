
# Function to do initialization
function Do_Initialize
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$HostName,
        [Parameter(Mandatory=$true)]
        [string]$UserName,
        [Parameter(Mandatory=$true)]
        [string]$PassWord
    )
    if((Get-PSSnapin | Where-Object {$_.Name -ieq "iControlSnapIn"}) -eq $null)
    {
        Add-PSSnapin -Name iControlSnapIn
    }

    try
    {
        $securePassword = ConvertTo-SecureString -String Admin098 -AsPlainText -Force
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList admin,$securePassword
        $f5Status = Initialize-F5.iControl -HostName 52.24.197.85 -Credentials $cred
        return $f5Status
    }
    catch
    {
        $Error[0].Exception.Message
        return $null
    }
}

function Create-SnatPool
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string[]]$SnatPoolNames,
        [Parameter(Mandatory=$true)]
        [string[][]]$SnapPoolIPs
    )
    
    try
    {
        if(!$snatPoolNames -and $snapPoolIPs)
        {
            return
        }
        else
        {
            $GetF5 = Get-F5.iControl
            if($GetF5 -eq $null)
            {
                Do_Initialize -hostName $hostName -userName $userName -passWord $passWord
            }
            $snatPoolList = $GetF5.LocalLBSNATPool.get_list()
            $memberList = @()
            if($snatPoolList)
            {
                $snats = $snatPoolList | % {($_ -split "/")[2]}
                foreach($snat in $snats)
                {
                    $memberList += $GetF5.LocalLBSNATPool.get_member($snat)
                }
                for($i = 0;$i -lt $snatPoolNames.Length;$i ++)
                #foreach($snat in $snatPoolNames)
                {
                    if($snats.Contains($snatPoolNames[$i]))
                    {
                        $snatPoolNames = $snatPoolNames -replace $snatPoolNames[$i]
                        $snapPoolIPs = $snapPoolIPs -replace $snapPoolIPs[$i]
                    }
                    else
                    {
                        if($memberList)
                        {
                            for($j=0;$j -lt $snapPoolIPs.Length;$j++)
                            {
                                if($memberList[$i].Contains($snapPoolIPs[$j]))
                                {
                                    $status = "Conflict"
                                    $snatPoolNames = $snatPoolNames -replace $snatPoolNames[$i]
                                    $snapPoolIPs = $snapPoolIPs -replace $snapPoolIPs[$i]
                                }
                                else
                                {
                                    $status = "Success"
                                }
                            } 
                        }
                    }
                }
                $snatPoolNames = $snatPoolNames | ?{$_}
                $snapPoolIPs = $snapPoolIPs | ?{$_}
                if($snatPoolNames -and $snapPoolIPs)
                {
                    $GetF5.LocalLBSNATPool.create_v2($snatPoolNames,$snapPoolIPs)
                }
                else
                {
                    "error"
                }
            }
            else
            {
                $GetF5.LocalLBSNATPool.create_v2($snatPoolNames,$snapPoolIPs)
            }
        }
    }
    catch
    {
        $Error[0].Exception.Message
    }
}
function Create-VIPPool
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string[]]$VIPPoolNames,
        [Parameter(Mandatory=$true)]
        [string[][]]$VIPPoolIPs,
        [Parameter(Mandatory=$true)]
        $Ports,
        [switch]$HealthMonitor = 'NO',
        [string]$LBMethod = 'LB_METHOD_ROUND_ROBIN'
    )

    try
    {
        if(!$VIPPoolName -and !$VIPPoolIPs -and !$Ports)
        {
        }

        $GetF5 = Get-F5.iControl
        if($GetF5 -eq $null)
        {
            Do_Initialize -hostName $hostName -userName $userName -passWord $passWord
        }
        $vipPoolList = $GetF5.LocalLBPool.get_list()
        $vipMemberList = @()
        if($vipMemberList)
        {
            $vipsExists = $vipPoolList | % {($_ -split "/")[2]}
            if($vipsExists.Contains($VIPPoolNames[$i]))
            {
                #$VIPPoolNames = $VIPPoolNames -replace $VIPPoolNames[$i]
                #$VIPPoolIPs = $VIPPoolIPs -replace $VIPPoolIPs[$i]
                "conflict"
            }
            else
            {
                
            }
            #}
            #$snatPoolNames = $snatPoolNames | ?{$_}
            #$snapPoolIPs = $snapPoolIPs | ?{$_}

            $IPPortDefList = New-Object -TypeName iControl.CommonIPPortDefinition[] $MemberList.Length;
            for($i=0; $i-lt $VIPPoolIPs.Length; $i++)
            {
                $IPPortDefList[$i] = New-Object -TypeName iControl.CommonIPPortDefinition;
                $IPPortDefList[$i].address = $VIPPoolIPs[$i];
                $IPPortDefList[$i].port = $Ports;
            }
            #if($snatPoolNames -and $snapPoolIPs)
            #{
                $GetF5.LocalLBPool.create($VIPPoolNames,$LBMethod,$IPPortDefList)
            #}
            #else
            #{
            #    "error"
            #}
        }
        else
        {
            $IPPortDefList = New-Object -TypeName iControl.CommonIPPortDefinition[] $MemberList.Length;
            for($i=0; $i-lt $VIPPoolIPs.Length; $i++)
            {
                $IPPortDefList[$i] = New-Object -TypeName iControl.CommonIPPortDefinition;
                $IPPortDefList[$i].address = $VIPPoolIPs[$i];
                $IPPortDefList[$i].port = $Ports;
            }
            $GetF5.LocalLBSNATPool.create_v2($VIPPoolNames,$LBMethod,$IPPortDefList)
        }
    }
    catch
    {
    }
}
function Associate-HealthMonitor
{
    Param
    (
        [string]$VIPPoolName,
        [string]$HealthMonitor = 'NO'
    )

    try
    {
        $GetF5 = Get-F5.iControl
        if($GetF5 -eq $null)
        {
            Do_Initialize -hostName $hostName -userName $userName -passWord $passWord
        }
        $vipPoolList = $GetF5.LocalLBPool.get_list()
        $vipsExists = $vipPoolList | % {($_ -split "/")[2]}
        $len = $vipsExists.length 
        if($len -gt 1)
        {
            $status = $vipsExists -contains $VIPPoolName
        }
        else
        {
            $status = $VIPPoolName -ieq $VIPPoolName
        }

        if($status -eq $true)
        {
            $monitor_association = New-Object -TypeName iControl.LocalLBPoolMonitorAssociation
            $monitor_association.pool_name = $VIPPoolName
            $monitor_association.monitor_rule = New-Object -TypeName iControl.LocalLBMonitorRule
            $monitor_association.monitor_rule.type = "MONITOR_RULE_TYPE_SINGLE"
            $monitor_association.monitor_rule.quorum = 0
            $monitor_association.monitor_rule.monitor_templates = (, 'tcp')
            $GetF5.LocalLBPool.set_monitor_association( (, $monitor_association) )
        }
        else
        {
            "unable to find vip pool"
        }    
    }
    catch
    {
    }
}

$snatList = @("demo_sn1_pl","demo_sn2_pl")
$memList1 = @("10.30.0.1","10.30.0.2")
$memList2 = @("10.30.0.3","10.30.0.4")
$memList = @($memList1,$memList2)
Create-SnatPool -SnatPoolNames $snatList -SnapPoolIPs $memList