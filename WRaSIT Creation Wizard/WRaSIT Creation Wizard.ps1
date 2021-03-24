################################################################################################################################################################
# AUTHOR:   Sgt Jeffreys, Duncan A.
# CREATED:  06/26/2018 
# UPDATED:  08/08/2018
# COMMENTS: This sript detects removable media devices on a compter, then formats and partitons them in preperation for being turned into reimaging media. After
# the devices have been wiped and formatted, this script begins to copy all files and folders from the specified desktop folders to the drives.
################################################################################################################################################################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$TempPath = $PSScriptRoot + '\TempFiles'
$TestTemp = Test-Path $TempPath
If ($TestTemp -eq $false) {New-Item -Path $TempPath -ItemType Directory -Force | Out-Null}

Function Get-DiskInfo()
{
 [cmdletbinding()]
 Param()

 $Path = $PSScriptRoot + '\TempFiles\ListDisk.txt'
 New-Item -path $Path -itemtype file -force | Out-Null
 Add-Content -path $Path "List Disk"
 $ListDisk = (Diskpart /s $Path)
 $TotalDisks = ($ListDisk.count)-9

 For ($d=0;$d -le $TotalDisks;$d++)

 {
 $Size = $ListDisk[-1-$d].substring(25,9).replace(" ","")
 $DiskID = $ListDisk[-1-$d].substring(7,5).trim()
 $Path = $PSScriptRoot + '\TempFiles\Detail.txt'

 New-Item -path $Path -itemtype file -force | Out-Null
 Add-Content -path $Path "Select Disk $DiskID"
 Add-Content -path $Path "Detail Disk"
 $Detail = (Diskpart /s $Path)

 $Model = $Detail[8]
 $Type = $Detail[10].substring(9)
 $DriveLetter = $Detail[-1].substring(15,1)

 # Displays disk size in bytes
 $Length = $Size.length
 $Multiplier = $Size.substring($Length-2,2)
 $IntSize = $Size.substring(0,$Length-2)
 Switch($Multiplier)
 {
 KB {$Mult = 1KB}
 MB {$Mult = 1MB}
 GB {$Mult = 1GB}
 }
 $DiskTotal = ([convert]::ToInt16($IntSize,10))*$Mult

 #Change 'DiskSize=$Size' to 'DiskSize=$DiskTotal' to display true size of disk
 [pscustomobject]@{DiskNum=$DiskID;Model=$Model;Type=$Type;DiskSize=$DiskTotal;DriveLetter=$DriveLetter}
 }
}



Function Get-VolumeInfo()
{
 [cmdletbinding()]
 Param()

 $Path = $PSScriptRoot + '\TempFiles\ListVolume.txt'
 New-Item -path $Path -itemtype file -force | Out-Null
 Add-Content -path $Path "List Volume"
 $ListVolume = (Diskpart /s $Path)
 $TotalVolumes = ($ListVolume.count)-9

 For ($d=0;$d -le $TotalVolumes;$d++)

 {
 $VolNum = $ListVolume[-1-$d].substring(2,10).trim()
 $Letter = $ListVolume[-1-$d].substring(14,3).trim()
 $Label = $ListVolume[-1-$d].substring(19,11).trim()
 $Format = $ListVolume[-1-$d].substring(32,5).replace(" ","")
 $Type = $ListVolume[-1-$d].substring(39,10).replace(" ","")
 $Size = $ListVolume[-1-$d].substring(51,7).replace(" ","")
 
 [pscustomobject]@{Number=$VolNum;VolumeLetter=$Letter;Label=$Label;Format=$Format;Type=$Type;Size=$Size}
 }
}



Function CloneWPB()
{
 [CmdletBinding()]
 Param (
        [Parameter(Mandatory = $True)]
        [string] $Source
      , [Parameter(Mandatory = $True)]
        [string] $Destination
       )

 $RegexBytes = '(?<=\s+)\d+(?=\s+)';
 $CommonRobocopyParams = '/MIR /COPYALL /BYTES /MT:4 /NP /NDL /NC /NJH /NJS /R:3 /W:10';
 
 $Form = New-Object System.Windows.Forms.Form
 $Form.Text = 'Progress Bar'
 $Form.Size = '500,200'
 $Form.FormBorderStyle = 'FixedSingle'
 $Form.StartPosition = 'CenterScreen'
 
 $StageLabel = New-Object System.Windows.Forms.Label
 $StageLabel.Location = '05,05'
 $StageLabel.Size = '495,30'
 $StageLabel.Text = 'PROCESS:' + "`n" + 'Analyzing Job. Please wait...'
 $StageLabel.Font = 'Tahoma'
 $Form.Controls.Add($StageLabel)
 
 $DetailsLabel = New-Object System.Windows.Forms.Label
 $DetailsLabel.Location = '05,40'
 $DetailsLabel.Size = '495,70'
 $DetailsLabel.Text = 'DETAILS:' + "`n" + 'Scanning files to provide accurate information.'
 $DetailsLabel.Font = 'Tahoma'
 $Form.Controls.Add($DetailsLabel)
 
 $ProgressBar = New-Object System.Windows.Forms.ProgressBar
 $ProgressBar.Name = 'PowerShellProgressBar'
 $ProgressBar.Value = 0
 $ProgressBar.Step = 1
 $ProgressBar.Minimum = 0
 $ProgressBar.Maximum = 100
 $ProgressBar.Style='Continuous'
 $ProgressBar.Location = '05,115'
 $ProgressBar.Size = '474,40'
 $Form.Controls.Add($ProgressBar)
 
 $Form.Show() | Out-Null
 $Form.Topmost = $True
 
 Start-Sleep -Milliseconds 100
 $StagingLogPath = '{0}\TempFiles\{1} robocopy staging.log' -f $PSScriptRoot, (Get-Date -Format 'yyyy-MM-dd hh-mm-ss');
 $StagingArgumentList = '"{0}" "{1}" /LOG:"{2}" /L {3}' -f $Source, $Destination, $StagingLogPath, $CommonRobocopyParams;
 Start-Process -Wait -FilePath robocopy.exe -ArgumentList $StagingArgumentList -WindowStyle Hidden;
 $StagingContent = Get-Content -Path $StagingLogPath;
 $TotalFileCount = $StagingContent.Count - 1;
 [RegEx]::Matches(($StagingContent -join "`n"), $RegexBytes) | % { $BytesTotal = 0; } { $BytesTotal += $_.Value; };
 $RobocopyLogPath = '{0}\TempFiles\{1} robocopy.log' -f $PSScriptRoot, (Get-Date -Format 'yyyy-MM-dd hh-mm-ss');
 $ArgumentList = '"{0}" "{1}" /LOG:"{2}" {3}' -f $Source, $Destination, $RobocopyLogPath, $CommonRobocopyParams;
 $StartTime = Get-Date
 $Robocopy = Start-Process -FilePath robocopy.exe -ArgumentList $ArgumentList -PassThru -WindowStyle Hidden;
 Start-Sleep -Milliseconds 100;
 
 While (!$Robocopy.HasExited)
      {
       Start-Sleep -Milliseconds 100;
       $BytesCopied = 0;
       $LogContent = (Get-Content -Path $RobocopyLogPath);
       $BytesCopied = ([Regex]::Matches($LogContent, $RegexBytes) | ForEach-Object -Process { $BytesCopied += $_.Value; } -End { $BytesCopied; });
       $CopiedFileCount = $LogContent.Count - 1;
       $Percentage = 0;
       If ($BytesCopied -gt 0)
         {
          $ElapsedTime = $(Get-Date) - $StartTime
          $EstimatedTotalSeconds = (($TotalFileCount/$CopiedFileCount)*$ElapsedTime.TotalSeconds)
          $EstimatedTotalSecondsTS = New-TimeSpan -Seconds $EstimatedTotalSeconds
          $EstimatedCompletionTime = $StartTime + $EstimatedTotalSecondsTS
          $Percentage = (($BytesCopied/$BytesTotal)*100)
          $ShowSizeCopied = [Math]::Round($BytesCopied /1Gb, 2)
          $ShowSizeTotal = [Math]::Round($BytesTotal /1Gb, 2)
          $ProgressBar.Value = $Percentage
          $StageLabel.Text = 'PROCESS:' + "`n" + 'Copying Files. Please wait...'
          $DetailsLabel.Text = 'DETAILS:' + "`n" + "Processing File $CopiedFileCount of $TotalFileCount" +"`n" + "Processed $ShowSizeCopied'GB of $ShowSizeTotal'GB" + "`n" + "$ShowPercentage% Complete" + "`n" + "Estimated Completion Time: $EstimatedCompletionTime"
          $ShowPercentage = "{0:N}"-f $Percentage
          $Form.Refresh()
          Start-Sleep -Milliseconds 100
         }
      }
$Form.Close()
}



Function CopyWPB()
{
 [CmdletBinding()]
 Param (
        [Parameter(Mandatory = $True)]
        [string] $Source
      , [Parameter(Mandatory = $True)]
        [string] $Destination
       )

 $RegexBytes = '(?<=\s+)\d+(?=\s+)';
 $CommonRobocopyParams = '/S /COPYALL /BYTES /MT:4 /NP /NDL /NC /NJH /NJS /R:3 /W:10';
 
 $Form = New-Object System.Windows.Forms.Form
 $Form.Text = 'Progress Bar'
 $Form.Size = '500,200'
 $Form.FormBorderStyle = 'FixedSingle'
 $Form.StartPosition = 'CenterScreen'
 
 $StageLabel = New-Object System.Windows.Forms.Label
 $StageLabel.Location = '05,05'
 $StageLabel.Size = '495,30'
 $StageLabel.Text = 'PROCESS:' + "`n" + 'Analyzing Job. Please wait...'
 $StageLabel.Font = 'Tahoma'
 $Form.Controls.Add($StageLabel)
 
 $DetailsLabel = New-Object System.Windows.Forms.Label
 $DetailsLabel.Location = '05,40'
 $DetailsLabel.Size = '495,70'
 $DetailsLabel.Text = 'DETAILS:' + "`n" + 'Scanning files to provide accurate information.'
 $DetailsLabel.Font = 'Tahoma'
 $Form.Controls.Add($DetailsLabel)
 
 $ProgressBar = New-Object System.Windows.Forms.ProgressBar
 $ProgressBar.Name = 'PowerShellProgressBar'
 $ProgressBar.Value = 0
 $ProgressBar.Step = 1
 $ProgressBar.Minimum = 0
 $ProgressBar.Maximum = 100
 $ProgressBar.Style='Continuous'
 $ProgressBar.Location = '05,115'
 $ProgressBar.Size = '474,40'
 $Form.Controls.Add($ProgressBar)
 
 $Form.Show() | Out-Null
 $Form.Topmost = $True
 
 Start-Sleep -Milliseconds 100
 $StagingLogPath = '{0}\TempFiles\{1} robocopy staging.log' -f $PSScriptRoot, (Get-Date -Format 'yyyy-MM-dd hh-mm-ss');
 $StagingArgumentList = '"{0}" "{1}" /LOG:"{2}" /L {3}' -f $Source, $Destination, $StagingLogPath, $CommonRobocopyParams;
 Start-Process -Wait -FilePath robocopy.exe -ArgumentList $StagingArgumentList -WindowStyle Hidden;
 $StagingContent = Get-Content -Path $StagingLogPath;
 $TotalFileCount = $StagingContent.Count - 1;
 [RegEx]::Matches(($StagingContent -join "`n"), $RegexBytes) | % { $BytesTotal = 0; } { $BytesTotal += $_.Value; };
 $RobocopyLogPath = '{0}\TempFiles\{1} robocopy.log' -f $PSScriptRoot, (Get-Date -Format 'yyyy-MM-dd hh-mm-ss');
 $ArgumentList = '"{0}" "{1}" /LOG:"{2}" {3}' -f $Source, $Destination, $RobocopyLogPath, $CommonRobocopyParams;
 $StartTime = Get-Date
 $Robocopy = Start-Process -FilePath robocopy.exe -ArgumentList $ArgumentList -PassThru -WindowStyle Hidden;
 Start-Sleep -Milliseconds 100;
 
 While (!$Robocopy.HasExited)
      {
       Start-Sleep -Milliseconds 100;
       $BytesCopied = 0;
       $LogContent = (Get-Content -Path $RobocopyLogPath);
       $BytesCopied = ([Regex]::Matches($LogContent, $RegexBytes) | ForEach-Object -Process { $BytesCopied += $_.Value; } -End { $BytesCopied; });
       $CopiedFileCount = $LogContent.Count - 1;
       $Percentage = 0;
       If ($BytesCopied -gt 0)
         {
          $ElapsedTime = $(Get-Date) - $StartTime
          $EstimatedTotalSeconds = (($TotalFileCount/$CopiedFileCount)*$ElapsedTime.TotalSeconds)
          $EstimatedTotalSecondsTS = New-TimeSpan -Seconds $EstimatedTotalSeconds
          $EstimatedCompletionTime = $StartTime + $EstimatedTotalSecondsTS
          $Percentage = (($BytesCopied/$BytesTotal)*100)
          $ShowSizeCopied = [Math]::Round($BytesCopied /1Gb, 2)
          $ShowSizeTotal = [Math]::Round($BytesTotal /1Gb, 2)
          $ProgressBar.Value = $Percentage
          $StageLabel.Text = 'PROCESS:' + "`n" + 'Copying Files. Please wait...'
          $DetailsLabel.Text = 'DETAILS:' + "`n" + "Processing File $CopiedFileCount of $TotalFileCount" +"`n" + "Processed $ShowSizeCopied'GB of $ShowSizeTotal'GB" + "`n" + "$ShowPercentage% Complete" + "`n" + "Estimated Completion Time: $EstimatedCompletionTime"
          $ShowPercentage = "{0:N}"-f $Percentage
          $Form.Refresh()
          Start-Sleep -Milliseconds 100
         }
      }
$Form.Close()
}



Function Clean-Part()
{
 $Path = $PSScriptRoot + '\TempFiles\Clean.txt'
 $DriveList = (Get-DiskInfo | Where {$_.Type -eq 'USB' -and $_.DiskSize -lt 1000GB -and $_.DiskSize -gt 31GB})

 New-Item -path $Path -itemtype file -force | Out-Null

 $DriveList | Foreach {
            $Path = $PSScriptRoot + '\TempFiles\Clean.txt'
            $DiskNum = $_.DiskNum
            Add-Content -path $Path -Value "Select Disk $DiskNum"
            Add-Content -path $Path -Value "Clean"
            Add-Content -path $Path -Value "create partition primary size=30798"
            Add-Content -path $Path -Value "select partition 1"
            Add-Content -path $Path -Value "active"
            Add-Content -path $Path -Value "format fs=fat32 quick label='Config'"
            Add-Content -path $Path -Value "assign"
            Add-Content -path $Path -Value "create partition primary size=1029"
            Add-Content -path $Path -Value "select partition 2"
            Add-Content -path $Path -Value "format fs=fat32 quick label='BIOS'"
            Add-Content -path $Path -Value "assign"
            Add-Content -path $Path -Value "create partition primary"
            Add-Content -path $Path -Value "select partition 3"
            Add-Content -path $Path -Value "format fs=ntfs quick label='Storage'"
            Add-Content -path $Path -Value "assign"
                      }
 Diskpart /s $Path
}



Function Config()
{
 $Path = $PSScriptRoot + '\TempFiles\Config.txt'
 $DriveList = (Get-VolumeInfo | Where {$_.Label -eq 'Config' -and $_.Type -eq 'Partition' -and $_.Format -eq 'FAT32'})
 New-Item -path $Path -itemtype file -force | Out-Null
 $DriveList | Foreach {
            $MountList = (Get-VolumeInfo | Where {$_.Label -eq 'Configurati' -and $_.Type -eq 'DVD-ROM' -and $_.Format -eq 'UDF'-and $_.Size -lt 32GB -and $_.Size -gt 25GB}) 
            $MountLetter = ($MountList | Out-String -Stream | Select-String "VolumeLetter")
            $Source = "$MountLetter".TrimStart('VolumeLetter : ') + ':\*.*'
            $Destination = $_.VolumeLetter + ':\*.*'
            $MountSource = Test-Path $Source
            If ($MountSource -eq $False) {Write-Host 'No Mounted Disk could be found to copy from.'}
            If ($MountSource -eq $False) {Write-Host 'Please ensure you have mounted a virtual disk no smaller than 25GB and no larger than 32GB'}
            If ($MountSource -eq $False) {$FailSafe = Read-Host "Press 'R' to Retry, or press 'A' to Abort the operation."
                                          If ($FailSafe -eq 'R'){Config}
                                          If ($FailSafe -eq 'A'){Exit}
                                         }
            xcopy $Source $Destination /s /e /f
                      }
 Diskpart /s $Path
}



Function BIOS()
{
 $Path = $PSScriptRoot + '\TempFiles\BIOS.txt'
 $DriveList = (Get-VolumeInfo | Where {$_.Label -eq 'BIOS' -and $_.Type -eq 'Partition' -and $_.Format -eq 'FAT32'})
 New-Item -path $Path -itemtype file -force | Out-Null
 $DriveList | Foreach {
            $Source = "C:\Users\mceds-admin\Desktop\BIOS\ "
            $Destination = $_.VolumeLetter + ':\ '
            CloneWPB $Source $Destination -ErrorAction SilentlyContinue
                      }
 Diskpart /s $Path
}



Function Storage()
{
 $Path = $PSScriptRoot + '\TempFiles\Storage.txt'
 $DriveList = (Get-VolumeInfo | Where {$_.Label -eq 'Storage' -and $_.Type -eq 'Partition' -and $_.Format -eq 'NTFS'})
 New-Item -path $Path -itemtype file -force | Out-Null
 $DriveList | ForEach-Object {
            $Source = 'C:\Users\mceds-admin\Desktop\Storage\ '
            $Destination = $_.VolumeLetter + ':\ '
            CloneWPB $Source $Destination -ErrorAction SilentlyContinue
                             } 
 Diskpart /s $Path
 }

 

Function PurgeScripts()
{
 $Path = $PSScriptRoot + '\TempFiles\Purge.txt'
 $DriveList = (Get-VolumeInfo | Where {$_.Label -eq 'Storage' -and $_.Type -eq 'Partition' -and $_.Format -eq 'NTFS'})
 New-Item -path $Path -itemtype file -force | Out-Null
 $DriveList | ForEach-Object {
            $Target1 = $_.VolumeLetter + ':\ '
            $Target2 = $_.VolumeLetter + ':\Library\  '
            $Target3 = $_.VolumeLetter + ':\Installers\HBSS\HBSS\McAfee HIPS\McAfee HIPS\ '
            Get-ChildItem -Path "$Target3" -Recurse -Filter 'SB2.ps1' | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Get-ChildItem -Path "$Target2" -Recurse -Filter 'How to Utilize The SAW.docx' | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Get-ChildItem -Path "$Target2" -Recurse -Filter 'How to Utilize The SBaC.docx' | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Get-ChildItem -Path "$Target2" -Recurse -Filter 'How to Utilize The WRaSIT.docx' | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Get-ChildItem -Path "$Target1" -Recurse -Filter 'Scripts' | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Get-ChildItem -Path "$Target1" -Recurse -Filter 'Uninstallers' | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Get-ChildItem -Path "$Target1" -Recurse -Filter 'Import Domain Script.bat' | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Get-ChildItem -Path "$Target1" -Recurse -Filter 'Run SAW.bat' | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                             } 
 Diskpart /s $Path
 }



Function CleanUp()
{
 $TempPath = $PSScriptRoot + '\TempFiles'
 $TestTemp = Test-Path $TempPath
 If ($TestTemp -eq $True) {Remove-Item -Path $TempPath -Force -Recurse}
 
 $Form = New-Object System.Windows.Forms.Form
 $Form.Text = 'WRaSIT Creation Wizard'
 $Form.Size = '315,130'
 $Form.StartPosition = 'CenterScreen'
 
 $OKButton = New-Object System.Windows.Forms.Button
 $OKButton.Location = '110,55'
 $OKButton.Size = '75,23'
 $OKButton.Text = 'OK'
 $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
 $Form.AcceptButton = $OKButton
 $Form.Controls.Add($OKButton)
 
 $Label = New-Object System.Windows.Forms.Label
 $Label.Location = '05,05'
 $Label.Size = '280,50'
 $Label.Text = 'Process Complete. Please select "OK" and close all windows, then safely remove your external hard drive/s.'
 $Form.Controls.Add($Label)

 $Form.Topmost = $True
 $Result = $Form.ShowDialog()
}



$Form = New-Object System.Windows.Forms.Form
$Form.Text = 'WRaSIT Creation Wizard'
$Form.Size = '315,240'
$Form.StartPosition = 'CenterScreen'

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = '35,170'
$OKButton.Size = '75,23'
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$Form.AcceptButton = $OKButton
$Form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = '175,170'
$CancelButton.Size = '75,23'
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$Form.CancelButton = $CancelButton
$Form.Controls.Add($CancelButton)

$Label = New-Object System.Windows.Forms.Label
$Label.Location = '05,05'
$Label.Size = '305,30'
$Label.Text = 'Welcome to the Windows Reimaging and Software Installation Tool Creation Wizard.'
$Form.Controls.Add($Label)

$UpdateStorageChkBx = New-Object System.Windows.Forms.Checkbox
$UpdateStorageChkBx.Location = '10,40'
$UpdateStorageChkBx.Size = '280,20'
$UpdateStorageChkBx.Text = 'Update Storage'
$UpdateStorageChkBx.Add_Click({
    If ($UpdateStorageChkBx.Checked -eq $True)
      {
       $CleanChkBx.Checked = $False
       $NewWRaSITChkBx.Checked = $False
      }
})
$Form.Controls.Add($UpdateStorageChkBx)

$UpdateBIOSChkBx = New-Object System.Windows.Forms.Checkbox
$UpdateBIOSChkBx.Location = '10,60'
$UpdateBIOSChkBx.Size = '280,20'
$UpdateBIOSChkBx.Text = 'Update BIOS'
$UpdateBIOSChkBx.Add_Click({
    If ($UpdateBIOSChkBx.Checked -eq $True)
      {
       $CleanChkBx.Checked = $False
       $NewWRaSITChkBx.Checked = $False
      }
})
$Form.Controls.Add($UpdateBIOSChkBx)

$UpdateConfigChkBx = New-Object System.Windows.Forms.Checkbox
$UpdateConfigChkBx.Location = '10,80'
$UpdateConfigChkBx.Size = '280,20'
$UpdateConfigChkBx.Text = 'Update Configuration Manager'
$UpdateConfigChkBx.Add_Click({
    If ($UpdateConfigChkBx.Checked -eq $True)
      {
       $CleanChkBx.Checked = $False
       $NewWRaSITChkBx.Checked = $False
      }
})
$Form.Controls.Add($UpdateConfigChkBx)

$CleanChkBx = New-Object System.Windows.Forms.Checkbox
$CleanChkBx.Location = '10,100'
$CleanChkBx.Size = '280,20'
$CleanChkBx.Text = 'Clean and Partition Drive/s'
$CleanChkBx.Add_Click({
    If ($CleanChkBx.Checked -eq $True)
      {
       $UpdateStorageChkBx.Checked = $False
       $UpdateBIOSChkBx.Checked = $False
       $UpdateConfigChkBx.Checked = $False
       $NewWRaSITChkBx.Checked = $False
      }
})
$Form.Controls.Add($CleanChkBx)

$NewWRaSITChkBx = New-Object System.Windows.Forms.Checkbox
$NewWRaSITChkBx.Location = '10,120'
$NewWRaSITChkBx.Size = '280,20'
$NewWRaSITChkBx.Text = 'Create New WRaSIT'
$NewWRaSITChkBx.Add_Click({
    If ($NewWRaSITChkBx.Checked -eq $True)
      {
       $UpdateStorageChkBx.Checked = $False
       $UpdateBIOSChkBx.Checked = $False
       $UpdateConfigChkBx.Checked = $False
       $CleanChkBx.Checked = $False
      }
})
$Form.Controls.Add($NewWRaSITChkBx)

$PurgeChkBx = New-Object System.Windows.Forms.Checkbox
$PurgeChkBx.Location = '10,140'
$PurgeChkBx.Size = '280,20'
$PurgeChkBx.Text = 'Purge Scripts from Drive/s'
$PurgeChkBx.Add_Click({
    If ($PurgeChkBx.Checked -eq $True)
      {
       $UpdateStorageChkBx.Checked = $False
       $UpdateBIOSChkBx.Checked = $False
       $UpdateConfigChkBx.Checked = $False
       $CleanChkBx.Checked = $False
       $NewWRaSITChkBx.Checked = $False
      }
})
$Form.Controls.Add($PurgeChkBx)

$Form.Topmost = $True
$Result = $Form.ShowDialog()

If ($Result -eq [System.Windows.Forms.DialogResult]::OK)
  {
   If ($UpdateStorageChkBx.Checked -eq $True) {Storage}
   If ($UpdateBIOSChkBx.Checked -eq $True) {BIOS}
   If ($UpdateConfigChkBx.Checked -eq $True) {Config}
   If ($CleanChkBx.Checked -eq $True) {Clean-Part}
   If ($NewWRaSITChkBx.Checked -eq $True) {Clean-Part}
   If ($NewWRaSITChkBx.Checked -eq $True) {Config}
   If ($NewWRaSITChkBx.Checked -eq $True) {BIOS}
   If ($NewWRaSITChkBx.Checked -eq $True) {Storage}
   If ($PurgeChkBx.Checked -eq $True) {PurgeScripts}
   CleanUp
  }

If ($Result -eq [System.Windows.Forms.DialogResult]::Cancel)
  {
   $TempPath = $PSScriptRoot + '\TempFiles'
   $TestTemp = Test-Path $TempPath
   If ($TestTemp -eq $True) {Remove-Item -Path $TempPath -Force -Recurse}
  }
