@echo off
echo Mapping the NetworkShare and Starting the installation...
powershell.exe -noprofile -ExecutionPolicy ByPass -Command ".\MapTool.ps1"
Pause