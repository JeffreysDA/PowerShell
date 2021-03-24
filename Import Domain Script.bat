@Echo Off
cd %~dp0
cls
Echo Please wait. Importing AutoDomainJoin Script.
if exist "%homedrive%%homepath%\Desktop\AutoDomainJoin.ps1" goto MOVE
Echo It appears that there is no script to be moved.
pause
exit

:MOVE
Move "%homedrive%%homepath%\Desktop\AutoDomainJoin.ps1" "%~dp0Scripts\Domain\Domain\"
Echo Your personal AutoDomainJoin script has been sucessfully imported to your External Hard Drive.
timeout /t 03
exit