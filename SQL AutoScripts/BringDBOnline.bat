@echo off
::Set /p DatabaseName="Enter DatabaseName:"
echo Fetching the Query data and Creating excelsheet...
powershell.exe -noprofile -ExecutionPolicy ByPass -Command ".\BringDBOnline.ps1"
Pause