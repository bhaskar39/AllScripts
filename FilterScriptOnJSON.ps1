Param
(
    [string]$JSONPath,
    [string]$FilterFile
)

Try
{
    $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
    if((Test-Path $JSONPath) -and (Test-Path $FilterFile))
    {
        $data = Get-Content -Path $JSONPath | ConvertFrom-Json
        $data1 = $data.inventory_additional
        $data2 = $data.metricSummery
        $data3 = $data.vmware_inventory

        function Out-FileUtf8NoBom 
        {

            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory, Position=0)] [string] $LiteralPath,
                [switch] $Append,
                [switch] $NoClobber,
                [AllowNull()] [int] $Width,
                [Parameter(ValueFromPipeline)] $InputObject
            )

            #requires -version 3

            # Make sure that the .NET framework sees the same working dir. as PS
            # and resolve the input path to a full path.
            [System.IO.Directory]::SetCurrentDirectory($PWD) # Caveat: .NET Core doesn't support [Environment]::CurrentDirectory
            $LiteralPath = [IO.Path]::GetFullPath($LiteralPath)

            # If -NoClobber was specified, throw an exception if the target file already
            # exists.
            if ($NoClobber -and (Test-Path $LiteralPath)) 
            {
                Throw [IO.IOException] "The file '$LiteralPath' already exists."
            }

            # Create a StreamWriter object.
            # Note that we take advantage of the fact that the StreamWriter class by default:
            # - uses UTF-8 encoding
            # - without a BOM.
            $sw = New-Object IO.StreamWriter $LiteralPath, $Append

            $htOutStringArgs = @{}
            if ($Width) 
            {
                $htOutStringArgs += @{ Width = $Width }
            }

            # Note: By not using begin / process / end blocks, we're effectively running
            #       in the end block, which means that all pipeline input has already
            #       been collected in automatic variable $Input.
            #       We must use this approach, because using | Out-String individually
            #       in each iteration of a process block would format each input object
            #       with an indvidual header.
            try 
            {
                $Input | Out-String -Stream @htOutStringArgs | % { $sw.WriteLine($_) }
            } 
            finally 
            {
                $sw.Dispose()
            }

        }

        $final = @{}
        $array1 = New-Object System.Collections.ArrayList
        $array2 = New-Object System.Collections.ArrayList

        $given = Get-Content -Path $FilterFile

        foreach($a in $data1)
        {
            if($a.computer_name -in $given)
            {
                $array1 += $a
            }
            else
            {
                continue
            }
        }

        foreach($b in $data2)
        {
            if($b.ComputerName -in $given)
            {
                $array2 += $b
            }
            else
            {
                continue
            }
        }

        $final.inventory_additional = $array1
        $final.metricSummery = $array2
        $final.vmware_inventory = $data3

        $final | ConvertTo-Json | Out-FileUtf8NoBom -LiteralPath "$PSScriptRoot\FilteredJSON.json" #F:\NetEnrich\Diva\Final_Internal.json
    }
    else
    {
        Write-Host "Please check the correct path of given files"
        exit
    }
}
catch
{
    Write-Host $Error[0].Exception.Message
    exit
}
