################################################################################################################################################################
# AUTHOR:   Sgt Jeffreys, Duncan A.
# CREATED:  06/28/2018 
# UPDATED:  08/08/2018
# COMMENTS: This sripts primary purpose is to Backup and Restore all required scripting information/files necessary to scripting all of my other tools/scripts.
# This scripts seconadary purpose is to Backup and Restore files and folders on any machine. Be carfule as "Cloning" mirriors and makes an exact clone of it's
# source, whereas "Copying" only copies the the source, but doesn't copy over hidden/system files unique to the source.
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
        [Parameter(Mandatory = $true)]
        [string] $Source
      , [Parameter(Mandatory = $true)]
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
 $Form.Topmost = $true
 
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
        [Parameter(Mandatory = $true)]
        [string] $Source
      , [Parameter(Mandatory = $true)]
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
 $Form.Topmost = $true
 
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



Function Select-Path()
{
 [cmdletbinding()]
 Param([string]$Description = 'Select Folder',[string]$RootFolder='Desktop')
 [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

 $OpenPathDialog = New-Object System.Windows.Forms.FolderBrowserDialog
 $OpenPathDialog.rootfolder = $RootFolder
 $OpenPathDialog.description = $Description
 $Show = $OpenPathDialog.showdialog()
    If ($Show -eq 'OK')
      {
       Return $OpenPathDialog.selectedpath
      }
    Else
      {
       Write-Error 'Operation Cancelled by User'
      }
}



Function Clean()
{
 $Path = $PSScriptRoot + '\TempFiles\Clean.txt'
 $DriveList = (Get-DiskInfo | Where {$_.Type -eq 'USB' -and $_.DiskSize -lt 1000GB -and $_.DiskSize -gt 31GB})

 New-Item -path $Path -itemtype file -force | Out-Null

 $DriveList | Foreach
           {
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



Function Backup()
{
 $Source = "$env:HOMEDRIVE$env:HOMEPATH\Desktop\"
 $Dest = $PSScriptRoot + '\BackupFiles\'

 CloneWPB $Source'BIOS' $Dest'BIOS\ '  -ErrorAction SilentlyContinue
 CloneWPB $Source'Storage' $Dest'Storage\ '  -ErrorAction SilentlyContinue
 CloneWPB $Source'Storage Extras' $Dest'Storage Extras\ '  -ErrorAction SilentlyContinue
}



Function Restore()
{
 $Source = $PSScriptRoot + '\BackupFiles\'
 $Dest = "$env:HOMEDRIVE$env:HOMEPATH\Desktop\"

 CopyWPB $Source'BIOS' $Dest'BIOS\ '  -ErrorAction SilentlyContinue
 CopyWPB $Source'Storage' $Dest'Storage\ '  -ErrorAction SilentlyContinue
 CopyWPB $Source'Storage Extras' $Dest'Storage Extras\ '  -ErrorAction SilentlyContinue
}



Function Clone()
{



}



Function CleanUp()
{
 $TempPath = $PSScriptRoot + '\TempFiles'
 $TestTemp = Test-Path $TempPath
 If ($TestTemp -eq $True) {Remove-Item -Path $TempPath -Force -Recurse}

 $Form = New-Object System.Windows.Forms.Form
 $Form.Text = 'SBaC Wizard'
 $Form.Size = New-Object System.Drawing.Size(315,130)
 $Form.StartPosition = 'CenterScreen'

 $OKButton = New-Object System.Windows.Forms.Button
 $OKButton.Location = New-Object System.Drawing.Point(110,55)
 $OKButton.Size = New-Object System.Drawing.Size(75,23)
 $OKButton.Text = 'OK'
 $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
 $Form.AcceptButton = $OKButton
 $Form.Controls.Add($OKButton)

 $Label = New-Object System.Windows.Forms.Label
 $Label.Location = New-Object System.Drawing.Point(10,10)
 $Label.Size = New-Object System.Drawing.Size(280,50)
 $Label.Text = 'Process Complete. Please select "OK" and close all windows, then safely remove your external hard drive/s.'
 $Form.Controls.Add($Label)

 $Form.Topmost = $True
 $Result = $Form.ShowDialog()

 If ($Result -eq [System.Windows.Forms.DialogResult]::OK)
  {
   If ($TestTemp -eq $True) {Remove-Item -Path $TempPath -Force -Recurse}
  }
}



$Form = New-Object System.Windows.Forms.Form
$Form.Text = 'SBaC Wizard'
$Form.Size = New-Object System.Drawing.Size(315,240)
$Form.StartPosition = 'CenterScreen'

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(35,165)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$Form.AcceptButton = $OKButton
$Form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(175,165)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$Form.CancelButton = $CancelButton
$Form.Controls.Add($CancelButton)

$Label = New-Object System.Windows.Forms.Label
$Label.Location = New-Object System.Drawing.Point(10,10)
$Label.Size = New-Object System.Drawing.Size(305,20)
$Label.Text = 'Welcome to the Script Backup and Cloning Wizard.'
$Form.Controls.Add($Label)

$BackupChkbx = New-Object System.Windows.Forms.Checkbox
$BackupChkbx.Location = New-Object System.Drawing.Size(10,35)
$BackupChkbx.Size = New-Object System.Drawing.Size(280,20)
$BackupChkbx.Text = 'Backup all Script Files from Host Machine'
$BackupChkbx.Add_Click({
    If ($BackupChkbx.Checked -eq $True)
      {
       $RestoreChkBx.Checked = $False
       $CloneDirChkBx.Checked = $False
       $CopyDirChkBx.Checked = $False
       $CloneDriveChkBx.Checked = $False
      }
})
$Form.Controls.Add($BackupChkbx)

$RestoreChkBx = New-Object System.Windows.Forms.Checkbox
$RestoreChkBx.Location = New-Object System.Drawing.Size(10,60)
$RestoreChkBx.Size = New-Object System.Drawing.Size(280,20)
$RestoreChkBx.Text = 'Restore all Script Files to Host Machine'
$RestoreChkBx.Add_Click({
    If ($RestoreChkBx.Checked -eq $True)
      {
       $BackupChkbx.Checked = $False
       $CloneDirChkBx.Checked = $False
       $CopyDirChkBx.Checked = $False
       $CloneDriveChkBx.Checked = $False
      }
})
$Form.Controls.Add($RestoreChkBx)

$CloneDirChkBx = New-Object System.Windows.Forms.Checkbox
$CloneDirChkBx.Location = New-Object System.Drawing.Size(10,85)
$CloneDirChkBx.Size = New-Object System.Drawing.Size(280,20)
$CloneDirChkBx.Text = 'Clone a Directory'
$CloneDirChkBx.Add_Click({
    If ($CloneDirChkBx.Checked -eq $True)
      {
       $BackupChkbx.Checked = $False
       $RestoreChkBx.Checked = $False
       $CopyDirChkBx.Checked = $False
       $CloneDriveChkBx.Checked = $False
      }
})
$Form.Controls.Add($CloneDirChkBx)

$CopyDirChkBx = New-Object System.Windows.Forms.Checkbox
$CopyDirChkBx.Location = New-Object System.Drawing.Size(10,110)
$CopyDirChkBx.Size = New-Object System.Drawing.Size(280,20)
$CopyDirChkBx.Text = 'Copy a Directory'
$CopyDirChkBx.Add_Click({
    If ($CopyDirChkBx.Checked -eq $True)
      {
       $BackupChkbx.Checked = $False
       $RestoreChkBx.Checked = $False
       $CloneDirChkBx.Checked = $False
       $CloneDriveChkBx.Checked = $False
      }
})
$Form.Controls.Add($CopyDirChkBx)

$CloneDriveChkBx = New-Object System.Windows.Forms.Checkbox
$CloneDriveChkBx.Location = New-Object System.Drawing.Size(10,135)
$CloneDriveChkBx.Size = New-Object System.Drawing.Size(280,20)
$CloneDriveChkBx.Text = 'Clone a Drive'
$CloneDriveChkBx.Add_Click({
    If ($CloneDriveChkBx.Checked -eq $True)
      {
       $BackupChkbx.Checked = $False
       $RestoreChkBx.Checked = $False
       $CloneDirChkBx.Checked = $False
       $CopyDirChkBx.Checked = $False
      }
})
$Form.Controls.Add($CloneDriveChkBx)

$Form.Topmost = $True
$Result = $Form.ShowDialog()

If ($Result -eq [System.Windows.Forms.DialogResult]::OK)
  {
   If ($BackupChkbx.Checked -eq $True) {Backup}
   If ($RestoreChkBx.Checked -eq $True) {Restore}
   If ($CloneDirChkBx.Checked -eq $True) {CloneWPB (Select-Path) (Select-Path)  -ErrorAction SilentlyContinue}
   If ($CopyDirChkBx.Checked -eq $True) {CopyWPB (Select-Path) (Select-Path)  -ErrorAction SilentlyContinue}
   If ($CloneDriveChkBx.Checked -eq $True) {Clone}
   CleanUp
  }

If ($Result -eq [System.Windows.Forms.DialogResult]::Cancel)
  {
   $TempPath = $PSScriptRoot + '\TempFiles'
   $TestTemp = Test-Path $TempPath
   If ($TestTemp -eq $True) {Remove-Item -Path $TempPath -Force -Recurse}
  }
