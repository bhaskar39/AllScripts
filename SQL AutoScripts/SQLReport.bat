@echo off
echo Fetching the Query data and Creating excelsheet...
powershell.exe -noprofile -ExecutionPolicy ByPass -Command ".\SQLServerReport.ps1"
Pause