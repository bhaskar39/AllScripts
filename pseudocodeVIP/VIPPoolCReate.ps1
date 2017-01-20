$vipName = "demovip"
[int[]]$ports = (80,443)
[string[]]$ips = @('10.40.0.1','10.40.0.2')
$names = @()
$lbMethod = "LB_METHOD_ROUND_ROBIN"
$Mon = 'YES'

try
{
    if($ports.Length -gt 1)
    {
        foreach($port in $ports)
        {
            $names += $vipName + "_" +$port +"_" + "pl"
        }
    }
    else
    {
        $names += $vipName + "_" +$ports + "_" + "pl"
    }

    $namesExist = $GetF5.LocalLBPool.get_list()
    if($namesExist)
    {
        $namesExist = $namesExist | %{($_ -split "/")[2]}
        for($i = 0;$i -lt $names.Length;$i++)
        {
            if($namesExist.Contains($names[$i]))
            {
                "Conflict"
            }
            else
            {
                $vipObj = New-Object -TypeName iControl.CommonIPPortDefinition[] $ips.Length
                for($j=0;$j -lt $ips.Length;$j++)
                {
                    $vipObj[$j]  = New-Object -TypeName iControl.CommonIPPortDefinition
                    $vipObj[$j].address = $ips[$j]
                    $vipObj[$j].port = $ports[$i]
                }
                $status = $GetF5.LocalLBPool.create($names[$i],$lbMethod,(,$vipObj))
                $GetF5.LocalLBPool.set_description($names[$i],"Sample Demo for VIP with $($ports[$i])")

                if($Mon -eq 'YES')
                {
                    $monitor_association = New-Object -TypeName iControl.LocalLBPoolMonitorAssociation
                    $monitor_association.pool_name = $names[$i]
                    $monitor_association.monitor_rule = New-Object -TypeName iControl.LocalLBMonitorRule
                    $monitor_association.monitor_rule.type = "MONITOR_RULE_TYPE_SINGLE"
                    $monitor_association.monitor_rule.quorum = 0
                    $monitor_association.monitor_rule.monitor_templates = (, 'tcp')
                    $GetF5.LocalLBPool.set_monitor_association( (, $monitor_association) )                
                }
            }
        }
    }
}
catch
{
    $Error[0]
}