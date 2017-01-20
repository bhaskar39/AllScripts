@echo off
echo Copying the backup file to share and removing the FileShare...
powershell.exe -noprofile -ExecutionPolicy ByPass -Command ".\CopyBakFileandRemoveShare.ps1"
Pause