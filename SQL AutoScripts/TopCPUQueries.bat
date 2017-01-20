@echo off
echo Fetching the Query data and Creating excelsheet...
powershell.exe -noprofile -ExecutionPolicy ByPass -Command ".\TopCPUQueries.ps1"
::Pause