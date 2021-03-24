cd C:\PsTools
:KILL
psexec -s -i cmd /c "net stop enterceptagent"
timeout /t 600
goto KILL
