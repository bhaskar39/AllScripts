@echo off
Set /p DatabaseName="Enter DatabaseName:"
::Set /p Password="EnterPassword:"
echo Exporting the MAP tool data to fileshare...
powershell.exe -noprofile -ExecutionPolicy ByPass -Command ".\ExportDB.ps1 %DatabaseName%"
Pause