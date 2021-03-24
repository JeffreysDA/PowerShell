@Echo Off
cd "C:\Program Files (x86)\Microsoft Office\Office15\"
Echo Please wait. Currently attempting to activate Microsoft Office 2013.
for /f "tokens=3 delims=: " %%o in (
	'cscript //nologo ospp.vbs /dstatus ^| find /i "License Status:"'
) do set "licenseStatus=%%o"
if /i "%licenseStatus%"=="---LICENSED---" (
	Echo Microsoft Office 2013 is already activated.
	goto WINCHK1
) else (
	cscript ospp.vbs /act
	goto WINCHK1
)


:WINCHK1
cd "C:\Windows\System32\"
Echo Please wait. Currently attempting to activate Windows 10.
for /f "tokens=3 delims=: " %%w in (
	'cscript //nologo slmgr.vbs /dli ^| find "License Status:"'
) do set "licenseStatus=%%w"
if /i "%licenseStatus%"=="Licensed" (
	Echo Windows 10 is already activated.
	goto CLEAN
) else (
	cscript slmgr.vbs /ato
	goto CLEAN
)

:CLEAN
if exist "%homedrive%%homepath%\Desktop\TempFolder\AutoFixes.bat" goto END
if exist "%homedrive%%homepath%\Desktop\TempFolder\AutoScript.bat" goto END
timeout /t 30
(
cd %homedrive%%homepath%\Desktop
if exist "%homedrive%%homepath%\Desktop\Activate Product Keys.bat" DEL "%homedrive%%homepath%\Desktop\Activate Product Keys.bat"
shutdown /r /f /t 05
exit
)

:END
exit