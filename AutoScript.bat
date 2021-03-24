@Echo Off
cd %~dp0
powercfg.exe /h off

REM ########################################### CHECK FOR UNINSTALLERS ##########################################

if exist "Scripts\AutoDomainRemoval.bat" goto UNINSTALLERS
if exist "EMS-NG Uninstall" goto UNINSTALLERS
if exist "SCCM Uninstaller" goto UNINSTALLERS

REM ############################################## CHECK FOR FIXES ##############################################

if exist "Scripts\AutoFixes.bat" "Scripts\AutoFixes.bat"
if exist "Scripts\AutoFixes.bat" goto END

REM ############################################# INSTALLATION PREP #############################################


Echo Please Wait. Preparing to run Auto Domain Join script if present.
if not exist "Scripts\Domain\AutoDomainJoin.ps1" goto NADJS
if exist "Scripts\Domain\AutoDomainJoin.ps1" goto RADJS
:RADJS
Echo Please wait. Currently running Auto Domain Join script.
start powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%homedrive%%homepath%\Desktop\TempFolder\Scripts\Domain\AutoDomainJoin.ps1'"
pause
goto CONT1
:NADJS
Echo It apperas that you have not imported an Auto Domain Join script. If you had selected to install additional software, that software will still be Installation; however, this computer will not be added to the domain unless you do so manually.
pause
:CONT1
cls


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
	goto INSTALLS1
) else (
	Echo Importing Windows 10 Product Key.
	cscript slmgr.vbs /ipk FullProductKeyHere
	goto INSTALLS1
)



REM ############################################### INSTALLATIONS ###############################################


:INSTALLS1
timeout /t 10
cd %~dp0

if exist "AMSTAC" Echo Please Wait. Currently Installing AMSTAC.
if exist "AMSTAC" start /wait "" "AMSTAC\AMSTAC.msi" /quiet
cls

if exist "Adobe\FlashPlayer" Echo Please Wait. Currently Installing Adobe FlashPlayer.
if exist "Adobe\FlashPlayer" start /wait "" "Adobe\FlashPlayer\installer.exe" -install
cls

if exist "Adobe\Reader" Echo Please Wait. Currently Installing Adobe Reader DC.
if exist "Adobe\Reader" start /wait "" "Adobe\Reader\installer.exe" /qn /spb
cls

if exist "Adobe\ShockWave" Echo Please Wait. Currently Installing Adobe ShockWave.
if exist "Adobe\ShockWave" start /wait "" "Adobe\ShockWave\installer.msi" /qn
cls


REM Spot saved for DDS


REM Spot saved for DTODS


if exist "EMS-NG" Echo Please Wait. Currently Installing EMS-NG Viewer. This may Take several minutes.
if not exist "EMS-NG" goto CONT2
move "EMS-NG\EMS-NG_setup.iss" "C:\Windows\debug"
"EMS-NG\EMSNG\setup.exe" /s /f1"c:\Windows\debug\EMS-NG_setup.iss" /f2"c:\Windows\debug\EMS-NG_2.11.1.5_install.log"
Echo Installing IETMs.
move "EMS-NG\IETMS\EMSNG" C:\EMSNG
Echo Please Wait. Currently creating DataBase Restore script.
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%Public%\Desktop\Restore EMS-NG DataBase.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "C:\Program Files (x86)\EMSNG\Viewer\bin\Helper\emsng_restore_db.bat" >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "C:\Program Files (x86)\EMSNG\Viewer\bin\Helper" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
call CreateShortcut.vbs
del CreateShortcut.vbs
Echo Installing S3000 WIN Drivers
start /wait "" "EMS-NG\DRIVERS\S3000 Win\S3000 Win Installer.msi" ALLUSERS=1 /qn
Echo Installing SPACE WIN Drivers
start /wait "" "EMS-NG\DRIVERS\Space Win\Space Win Installer.msi" ALLUSERS=1 /qn
:CONT2
cls

if exist "FED LOG" Echo Please Wait. Currently Installing FEDLOG.
if not exist "FED LOG" goto CONT3
move "FED LOG\FED LOG" "C:\Program Files (x86)\FED LOG"
timeout /t 30 /nobreak
if exist "C:\Program Files (x86)\FED LOG" goto SHRTCTFL
if not exist "C:\Program Files (x86)\FED LOG" goto CONT3
:SHRTCTFL
Echo Creating FED LOG and FLIS Search Shortcuts.
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%Public%\Desktop\FED LOG.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "C:\Program Files (x86)\FED LOG\IMD64.EXE" >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "C:\Program Files (x86)\FED LOG" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
call CreateShortcut.vbs
del CreateShortcut.vbs
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%Public%\Desktop\FLIS Search.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "C:\Program Files (x86)\FED LOG\IMD2.EXE" >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "C:\Program Files (x86)\FED LOG" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
call CreateShortcut.vbs
del CreateShortcut.vbs
:CONT3
cls

if exist "Java" Echo Please Wait. Currently Installing Java.
if exist "Java" start /wait "" "Java\installer.exe" INSTALL_SILENT=Enable
cls

if exist "MDSS II" Echo Please Wait. Currently Installing MDSS II.
if exist "MDSS II" move "MDSS II\MDSSII_setup.iss" "C:\Windows\debug"
if exist "MDSS II" start /wait "" "MDSS II\setup.exe" /s /SMS /f1"c:\Windows\debug\MDSSII_setup.iss"
cls

if exist "PLMS" Echo Please Wait. Currently Installing PLMS.
if exist "PLMS" start /wait "" "PLMS\PLMS\INSTALLATION FILES\L_PLMS_30_AXP.MSI" /quiet
cls

if exist C:\PsTools goto PST1
move "PsTools" "C:\"
:PST1
if exist "C:\Users\mceds-admin\Desktop\Go To PSTOOLS.bat" goto PST2
move "Scripts\Go To PSTOOLS.bat" "C:\Users\USER\Desktop\"
:PST2
if exist "C:\Users\mceds-admin\Desktop\Stop HIPS.bat" goto PSTEND
move "Scripts\Stop HIPS.bat" "C:\Users\USER\Desktop\"
:PSTEND
cls

if exist "SoftLink" Echo Please Wait. Preparing to run the SoftLink Installer.
if exist "SoftLink" start "" "SoftLink\SoftLink License Information.txt"
if exist "SoftLink" start /wait "" "SoftLink\SoftLink_Setup.exe"
cls


REM Spot saved for WinIATS


if exist "Windows Mobile Device Center" Echo Please Wait. Currently Installing Windows Mobile Device Center.
if exist "Windows Mobile Device Center" start /wait "" "Windows Mobile Device Center\drvupdate-amd64.exe" /Q
cls



REM ############################################### HBSS ###############################################



if not exist "HBSS" goto CONT5
Echo Please Wait. Currently Installing McAfee Agent
start /wait "" "HBSS\McAfee Agent\McAfee Agent\installer.exe" /install=agent /s
cls

Echo Please Wait. Currently Installing DLP Agent.
start /wait "" "HBSS\McAfee DLP\McAfee DLP\installer.exe" /passive /norestart
cls

Echo Please Wait. Currently Installing Policy Auditor.
start /wait "" "HBSS\McAfee PA\McAfee PA\Setup.exe" /s
cls

Echo Please Wait. Currently Installing USAF ACCM.
start /wait "" "HBSS\Win ACCM\Win ACCM\installer.msi" /passive
cls

Echo Please Wait. Currently Installing VSE.
start /wait "" "HBSS\McAfee VSE\McAfee VSE\installer.Exe" /passive
cls

Echo Please Wait. Currently Installing Big Fix.
start /wait "" "HBSS\BigFix\BigFix\setup.exe" /S /v/qn
cls

Echo Please Wait. Currently Installing Microsoft SCCM Client.
start /wait "" "HBSS\SCCM\SCCM\ccmsetup.exe" /mp:SERVER1;SERVER2 SMSSITECODE=SiteCodeHere
:WAIT
cls
Echo Waiting for Microsoft SCCM Client to finish installing.
timeout /t 30
tasklist | find /i "ccmsetup.exe" >nul
if not %errorlevel%==1 goto WAIT
cls

Echo Please Wait. Installing Domain Proxy files.
if exist "C:\Program Files\PATH" goto MP1
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
if exist "C:\Users\Public\Desktop\Proxy Off.lnk" goto CONT4
if not exist "C:\Users\Public\Desktop\Proxy On.lnk" goto SHRTCTOFF
:SHRTCTOFF
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%Public%\Desktop\Proxy Off.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "C:\Program Files\PATH\TabletProxyManagement.vbs" >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "C:\Program Files\PATH" >> CreateShortcut.vbs
echo oLink.IconLocation = "%ProgramFiles%\PATH\Icon.ico" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
call CreateShortcut.vbs
del CreateShortcut.vbs
:CONT4
cls

Echo Please Wait. Currently Installing HIPS.
start /wait "" "HBSS\McAfee HIPS\McAfee HIPS\McAfeeHIP_ClientSetup.exe"
:CONT5
cls



REM ############################################### CLEANUP PREP ############################################



if exist "Scripts\Activate Product Keys.bat" Echo Attempting to activate Product Keys.
if exist "Scripts\Activate Product Keys.bat" start /wait call "Scripts\Activate Product Keys.bat"

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
	goto ENDCLEANPREP
) else (
	Echo Failed to activate Windows 10. You will need to run the Activate Product Keys script again after this machine restarts.
	goto RETRY
)

:RETRY
cd %~dp0
start /max Scripts\WARNING.bat
pause
if exist "%homedrive%%homepath%\Desktop\TempFolder\Scripts\Activate Product Keys.bat" move "%homedrive%%homepath%\Desktop\TempFolder\Scripts\Activate Product Keys.bat" "%homedrive%%homepath%\Desktop\"
Echo Failed to activate Microsoft Office 2013 and/or Windows 10.
Echo The Activate Product Keys script has been moved to the Desktop to prevent deletion.
Echo Please Rerun the Activate Product Keys script after this computer has finished restarting.
timeout /t 60

:ENDCLEANPREP
cd %~dp0
net user "RenameMe"
If ErrorLevel 2 (goto CONT6) else (net user renameme /delete)
:CONT6
net user UsErNaMe PaSsWoRd
WMIC USERACCOUNT WHERE "Name = 'UsErNaMe'" SET PasswordExpires=FALSE
sc config remoteregistry start=auto



REM ################################################# CLEANUP ###################################################



:CLEAN
Echo Cleaning up source files and preparing to resart.
powercfg.exe /h on
(
cd %homedrive%%homepath%\Desktop
if exist "%homedrive%%homepath%\Desktop\TempFolder" RMDIR /S /Q "%homedrive%%homepath%\Desktop\TempFolder"
shutdown /r /f /t 05
exit
)



REM ############################################### UNINSTALLATION ###############################################



:UNINSTALLERS
if exist C:\PsTools goto PST3
move "PsTools" "C:\"
:PST3
if exist "C:\Users\mceds-admin\Desktop\Go To PSTOOLS.bat" goto PST4
move "Scripts\Go To PSTOOLS.bat" "C:\Users\USER\Desktop\"
:PST4
if exist "C:\Users\mceds-admin\Desktop\Stop HIPS.bat" goto PSTEND2
move "Scripts\Stop HIPS.bat" "C:\Users\USER\Desktop\"
:PSTEND2
cls

Echo Please Wait. Preparing to run Stop HIPS script if present.
if not exist "%homedrive%\Users\USER\Desktop\Stop HIPS.bat" goto NSH
if exist "%homedrive%\Users\USER\Desktop\Stop HIPS.bat" goto RSH
:RSH
Echo Please wait. Currently running Stop HIPS script.
start "" "%homedrive%\Users\USER\Desktop\Stop HIPS.bat"
timeout /t 10 /nobreak
goto CONT7
:NSH
Echo It apperas that the Stop HIPS script is not on the USERNAME desktop. It is strongly advised that you minimize this window and copy Stop HIPS.bat to the USERNAME desktop and run it manually before continuing. If you have verified that HIPS is not installed on this computer, you can ignore this message and continue.
pause
:CONT7
cls

if exist "Scripts\AutoDomainRemoval.bat" Echo Please Wait. Preparing to remove the computer from the doamin.
if not exist "Scripts\AutoDomainRemoval.bat" goto CONT8
start /wait call "Scripts\AutoDomainRemoval.bat"
:CONT8
cls

if exist "EMS-NG Uninstall" Echo Please Wait. Currently Uninstalling EMS-NG.
if exist "EMS-NG Uninstall" start /wait call "EMS-NG Uninstall\EMS-NG_Uninstall.bat"
cls

if exist "SCCM Uninstaller" Echo Please Wait. Currently Uninstalling SCCM.
if exist "SCCM Uninstaller" start /wait call "SCCM Uninstaller\SCCM_Uninstall.bat" -install
cls

goto CLEAN

:END
exit
