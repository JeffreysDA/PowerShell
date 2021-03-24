Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force

$User = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Bse64UserName'))
$Pass = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Base64PassWord'))
$SecPass = ConvertTo-SecureString $Pass -AsPlainText -Force
$Domain = 'FQDN'
$Credentials = New-Object System.Management.Automation.PSCredential ("domain\$User",$SecPass)
$TargetComputers = 'C:\Users\USER\Desktop\File Transfer\Target Machines.txt'

$LogFolder = $PSScriptRoot + '\Event Logs'
$TestLogFolder = Test-Path $LogFolder
$LogPath = '{0}\Event Logs\Computers_{1}.log' -f $PSScriptRoot, (Get-Date -Format 'yyyy-MM-dd HH-MM-ss')
If ($TestLogFolder -eq $False) {New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null}
New-Item -Path $LogPath -ItemType File -Force | Out-Null

Get-Credential $Credentials

Import-Csv 'C:\Users\USER\Desktop\File Transfer\FromTo.csv' | ForEach-Object -Process {
[String]$Source = $_.Source
[String]$Destination = $_.Destination
}


Get-Content $TargetComputers | ForEach {

    If (Test-Connection -ComputerName $_ -Count 1 -Quiet ) {
        Add-Content -Path $LogPath "$_ was Online"
        Copy-Item -Path $Source -Destination \\$_\c$\$Destination -Recurse
    } else {
        Add-Content -Path $LogPath "$_ was Offline"
        }     
}