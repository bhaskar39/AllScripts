@echo off
echo Fetching the Query data and Creating excelsheet...
powershell.exe -noprofile -ExecutionPolicy ByPass -Command ".\Top10Waits.ps1"
::Pause