@EchoOff
start /B /W wmic.exe /interactive:off ComputerSystem Where "Name='%computername%'" Call UnJoinDomainOrWorkgroup FUnjoinOptions=0
start /B /W wmic.exe /interactive:off ComputerSystem Where "Name='%computername%'" Call JoinDomainOrWorkgroup name="OFFLINE"
start /B /W wmic.exe /interactive:off ComputerSystem Where "Name='%computername%'" Call Rename name="RenameMe"
ipconfig /release
ipconfig /flushdns
exit