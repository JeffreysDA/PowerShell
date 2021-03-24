@Echo Off

REM ############################################# FIXES PREP #############################################

cd "C:\Program Files (x86)\Microsoft Office\Office15"
Echo Checking Microsoft Office 2013 Product Key
for /f "tokens=8 delims=: " %%o in (
	'cscript //nologo ospp.vbs /dstatus ^| find /i "Last 5 characters of installed product key:"'
) do set "ProductKey=%%o"
if /i "%ProductKey%"=="Last5ofProductKeyHere" (
	Echo The Proper Microsoft Office Product Key is already installed.
	goto WINCHK1
) else (
	Echo Importing Microsoft Office Product Key.
	cscript ospp.vbs /inpkey:FullProductKeyHere
	goto WINCHK1
)
:WINCHK1
cd "C:\Windows\System32\"
Echo Checking Windows 10 Product Key
for /f "tokens=4 delims=: " %%w in (
	'cscript //nologo "C:\Windows\System32\slmgr.vbs" /dli ^| find "Partial Product Key:"'
) do set "ProductKey=%%w"
if /i "%ProductKey%"=="Last5ofProductKeyHere" (
	Echo The Proper Windows 10 Product Key is already installed. 
	goto FIXES1
) else (
	Echo Importing Windows 10 Product Key.
	cscript slmgr.vbs /ipk FullProductKeyHere
	goto FIXES1
)


REM ############################################# FIXES #############################################

:FIXES1
timeout /t 10
cd %homedrive%%homepath%\Desktop\TempFolder\
Echo Please Wait. Installing MRAN Proxy files.
if exist "C:\Program Files\MCEN\RAS" goto MP1
move "PATH" "C:\Program Files\"
:MP1
move "PATH\TabletProxyManagement.vbs" "C:\Program Files\PATH\"
if exist "C:\Users\Public\Desktop\Proxy On.lnk" goto MP2
if not exist "C:\Users\Public\Desktop\Proxy On.lnk" goto SHRTCTON
:SHRTCTON
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%Public%\Desktop\Proxy On.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "C:\Program Files\PATH\TabletProxyManagement.vbs" >> CreateShortcut.vbs
echo oLink.Arguments = "EnableProxy" >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "C:\Program Files\PATH" >> CreateShortcut.vbs
echo oLink.IconLocation = "%ProgramFiles%\PATH\Icon.ico" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
call CreateShortcut.vbs
del CreateShortcut.vbs
:MP2
if exist "C:\Users\Public\Desktop\Proxy Off.lnk" goto CONT1
if not exist "C:\Users\Public\Desktop\Proxy On.lnk" goto SHRTCTOFF
:SHRTCTOFF
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%Public%\Desktop\Proxy Off.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "C:\Program Files\PATH\TabletProxyManagement.vbs" >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "C:\Program Files\MCEN\RAS" >> CreateShortcut.vbs
echo oLink.IconLocation = "%ProgramFiles%\PATH\Icon.ico" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
call CreateShortcut.vbs
del CreateShortcut.vbs
:CONT1
cls


if exist "Fixes & Updates\Activate Product Keys.bat" Echo Waiting for five minutes before attempting to activate Product Keys. DO NOT ATTEMPT TO SKIP!
if not exist "Fixes & Updates\Activate Product Keys.bat" goto SKIPWAIT 
timeout /t 300 /nobreak
if exist "Fixes & Updates\Activate Product Keys.bat" Echo Attempting to activate Product Keys.
start /wait call "Fixes & Updates\Activate Product Keys.bat"

:MSVERIFY
cd "C:\Program Files (x86)\Microsoft Office\Office15\"
Echo Verifying Microsoft Office 2013 has been activated.
for /f "tokens=3 delims=: " %%o in (
	'cscript //nologo ospp.vbs /dstatus ^| find /i "License Status:"'
) do set "licenseStatus=%%o"
if /i "%licenseStatus%"=="---LICENSED---" (
	Echo Microsoft Office 2013 has been activated.
	goto WINVERIFY
) else (
	Echo Failed to activate Microsoft Office 2013. You will need to run the Activate Product Keys script again after this machine restarts.
	goto RETRY
)


:WINVERIFY
cd "C:\Windows\System32\"
Echo Verifying Windows 10 has been activated.
for /f "tokens=3 delims=: " %%w in (
	'cscript //nologo slmgr.vbs /dli ^| find "License Status:"'
) do set "licenseStatus=%%w"
if /i "%licenseStatus%"=="Licensed" (
	Echo Windows 10 has been activated.
	goto CLEAN
) else (
	Echo Failed to activate Windows 10. You will need to run the Activate Product Keys script again after this machine restarts.
	goto RETRY
)

:RETRY
cd %~dp0
start /max WARNING.bat
pause
if exists "%homedrive%%homepath%\Desktop\TempFolder\Fixes & Updates\Activate Product Keys.bat" move "%homedrive%%homepath%\Desktop\TempFolder\Fixes & Updates\Activate Product Keys.bat" "%homedrive%%homepath%\Desktop\"
Echo Failed to activate Microsoft Office 2013 and/or Windows 10.
Echo The Activate Product Keys script is being moved to the Desktop to prevent deletion.
Echo Please Rerun the Activate Product Keys script after this computer has finished restarting.
timeout /t 60

:SKIPWAIT
if not exist "Fixes & Updates\Activate Product Keys.bat" goto CLEAN



REM ############################################# CLEANUP #############################################



:CLEAN
timeout /t 10
Echo Cleaning up source files and preparing to resart.
powercfg.exe /h on
(
cd %homedrive%%homepath%\Desktop
if exist "%homedrive%%homepath%\Desktop\TempFolder" RMDIR /S /Q "%homedrive%%homepath%\Desktop\TempFolder"
shutdown /r /f /t 05
exit
)