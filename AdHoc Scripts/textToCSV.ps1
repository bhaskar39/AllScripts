$rawData = New-Object System.Collections.ArrayList
$rawData1 = New-Object System.Collections.ArrayList
$rawData = Get-Content 'F:\AdHoc Scripts\temp.txt'
$rawData1 = Get-Content 'F:\AdHoc Scripts\temp1.txt'
$rawData = $rawData | select -Skip 1
$rawData1 = $rawData1 | select -Skip 1


$Obj1 = New-Object System.Collections.ArrayList
$Obj2 = New-Object System.Collections.ArrayList

foreach($a1 in $rawData1)
{
    $a1 = $a1.Trim()
    $a1 = $a1 -replace "\s+"," "
    $arr1 = $a1.Split(" ")
    $o1 = New-Object psobject
    if($arr1.Count -eq 4)
    {
        $o1 | Add-Member -MemberType NoteProperty -Name volume -Value $arr1[0]
        $o1 | Add-Member -MemberType NoteProperty -Name barcode -Value $arr1[1]
        $o1 | Add-Member -MemberType NoteProperty -Name '(%)' -Value $arr1[2]
        $o1 | Add-Member -MemberType NoteProperty -Name pool -Value $arr1[3]
        $o1 | Add-Member -MemberType NoteProperty -Name location -Value $null
        #$Obj1 += $o
    }
    else
    {
        #$o = New-Object psobject
        $o1 | Add-Member -MemberType NoteProperty -Name volume -Value $arr1[0]
        $o1 | Add-Member -MemberType NoteProperty -Name barcode -Value $arr1[1]
        $o1 | Add-Member -MemberType NoteProperty -Name '(%)' -Value $arr1[2]
        $o1 | Add-Member -MemberType NoteProperty -Name pool -Value $arr1[3]
        $o1 | Add-Member -MemberType NoteProperty -Name location -Value $arr1[4]
        #$Obj1 += $o
    }
    $Obj2 += $o1
}

foreach($a in $rawData)
{
    $a = $a.Trim()
    $a = $a -replace "\s+"," "
    $arr = $a.Split(" ")
    $o = New-Object psobject
    if($arr.Count -eq 10)
    {
        
        $o | Add-Member -MemberType NoteProperty -Name state -Value $null
        $o | Add-Member -MemberType NoteProperty -Name volume -Value $arr[0]
        $o | Add-Member -MemberType NoteProperty -Name written -Value "$($arr[1]) $($arr[2])"
        $o | Add-Member -MemberType NoteProperty -Name '(%)' -Value $arr[3]
        $o | Add-Member -MemberType NoteProperty -Name expires -Value $arr[4]
        $o | Add-Member -MemberType NoteProperty -Name read -Value "$($arr[5]) $($arr[6])"
        $o | Add-Member -MemberType NoteProperty -Name mounts -Value $arr[7]
        $bcode = $Obj2 | Where-Object {$_.volume -eq $arr[0]}
        $o | Add-Member -MemberType NoteProperty -Name barcode -Value $($bcode.barcode)
        $o | Add-Member -MemberType NoteProperty -Name pool -Value $($bcode.pool)
        $o | Add-Member -MemberType NoteProperty -Name location -Value $($bcode.location)
        #$Obj1 += $o
    }
    else
    {
        #$o = New-Object psobject
        $o | Add-Member -MemberType NoteProperty -Name state -Value $arr[0]
        $o | Add-Member -MemberType NoteProperty -Name volume -Value $arr[1]
        $o | Add-Member -MemberType NoteProperty -Name written -Value "$($arr[2]) $($arr[3])"
        $o | Add-Member -MemberType NoteProperty -Name '(%)' -Value $arr[4]
        $o | Add-Member -MemberType NoteProperty -Name expires -Value $arr[5]
        $o | Add-Member -MemberType NoteProperty -Name read -Value "$($arr[6]) $($arr[7])" 
        $o | Add-Member -MemberType NoteProperty -Name mounts -Value $arr[8]
        $o | Add-Member -MemberType NoteProperty -Name capacity -Value "$($arr[9]) $($arr[10])"
        $bcode = $Obj2 | Where-Object {$_.volume -eq $arr[1]}
        $o | Add-Member -MemberType NoteProperty -Name barcode -Value $($bcode.barcode)
        $o | Add-Member -MemberType NoteProperty -Name pool -Value $($bcode.pool)
        $o | Add-Member -MemberType NoteProperty -Name location -Value $($bcode.location)
    }
    $Obj1 += $o
}

function ConvertTo-MultiArray 
{

    param(
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject
    )
    BEGIN {
        $objects = @()
        [ref]$array = [ref]$null
    }
    Process {
        $objects += $InputObject
    }
    END {
        $properties = $objects[0].psobject.properties |%{$_.name}
        $array.Value = New-Object 'object[,]' ($objects.Count+1),$properties.count
        # i = row and j = column
        $j = 0
        $properties |%{
            $array.Value[0,$j] = $_.tostring()
            $j++
        }
        $i = 1
        $objects |% {
            $item = $_
            $j = 0
            $properties | % {
                if ($item.($_) -eq $null) {
                    $array.value[$i,$j] = ""
                }
                else {
                    $array.value[$i,$j] = $item.($_).tostring()
                }
                $j++
            }
            $i++
        }
        $array
    }
}
function Export-Excel 
{
        [cmdletBinding()]
        Param(
            [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
            [PSObject[]]$InputObject
        )
        begin{
            $header=$null
            $row=1
            $xl=New-Object -ComObject Excel.Application
            $wb=$xl.WorkBooks.add(1)
            $ws=$wb.WorkSheets.item(1)
            $xl.Visible=$false
            $xl.DisplayAlerts = $false
            $xl.ScreenUpdating = $False
            $objects = @()

            }
        process{
            $objects += $InputObject

        }
        end{
            $array4XL = ($objects | ConvertTo-MultiArray).value

            $starta = [int][char]'a' - 1
            if ($array4XL.GetLength(1) -gt 26) {
                $col = [char]([int][math]::Floor($array4XL.GetLength(1)/26) + $starta) + [char](($array4XL.GetLength(1)%26) + $Starta)
            } else {
                $col = [char]($array4XL.GetLength(1) + $starta)
            }
            $ws.Range("a1","$col$($array4XL.GetLength(0))").value2=$array4XL

            $wb.SaveAs("C:\Temp\Export-Excel.xlsx")
            $xl.Quit()
            Remove-Variable xl
        }
}

Export-Excel -InputObject $Obj1

