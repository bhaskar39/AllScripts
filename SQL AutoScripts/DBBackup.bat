@echo off
echo Fetching the Query data and Creating excelsheet...
powershell.exe -noprofile -ExecutionPolicy ByPass -Command ".\DBBackup.ps1"
::Pause