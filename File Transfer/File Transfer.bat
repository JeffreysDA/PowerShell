@Echo Off
cd %~dp0
cls
start /wait powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%~dp0File Transfer.ps1'"
exit