    $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
    New-Item -Path "$PSScriptRoot\..\test2" -ItemType Directory -Force