@Echo Off
cd %~dp0
start powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%~dp0\SBaC.ps1'"
exit