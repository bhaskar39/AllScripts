@echo off
Set /P Partner="Enter PartnerName:"
Set /P Client="Enter ClientName:"
Set /P Region="Enter Region:"
::Set /p UserID="Enter UserName:"
::Set /p Password="EnterPassword:"
echo Importing the MAP tool data from fileshare...
powershell.exe -noprofile -ExecutionPolicy ByPass -Command ".\ImportDB1.ps1 %Partner% %Client% %Region% sqladmin pass123@word"
Pause