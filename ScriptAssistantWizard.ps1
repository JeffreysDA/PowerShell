################################################################################################################################################################
# AUTHOR:   Sgt Jeffreys, Duncan A.
# CREATED:  06/21/2018 
# UPDATED:  08/08/2018
# COMMENTS: This sript acts as a wizard for installing software on a computer after reimaging it, as well as managing, patching, updating, and uninstalling 
# software already installed on a computer. It takes the users input and copies the necessary folders and files from the external HDD to the host machine along
# with the scripts required to execute the selected options. 
################################################################################################################################################################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$DriveLetter = $PSScriptRoot.TrimEnd('Scripts')
$InstallPath = "$DriveLetter" + 'Installers'
$UninstPath = "$DriveLetter" + 'Uninstallers'
$DesPath = "$env:HOMEDRIVE$env:HOMEPATH\Desktop\TempFolder"
$ScriptDes = "$DesPath" + '\Scripts'
$Domain =  $PSScriptRoot + '\Domain'
$HBSS = $InstallPath + '\HBSS'
$DesHBSS = $DesPath + '\HBSS'
$DesFix = $DesPath + '\Fixes & Updates'

$ACCM = $HBSS + '\HBSS\Win ACCM'
$AFP = $InstallPath + '\Adobe\FlashPlayer'
$AR = $InstallPath + '\Adobe\Reader'
$ASW = $InstallPath + '\Adobe\ShockWave'
$AMS = $InstallPath + '\AMSTAC'
$BigFix = $HBSS + '\HBSS\BigFix'
$DDS = $InstallPath + '\DDS'
$DTODS = $InstallPath + '\DTODS'
$EMSNG = $InstallPath + '\EMS-NG'
$FEDLOG = $InstallPath + '\FED LOG'
$Java = $InstallPath + '\Java'
$McAgent = $HBSS + '\HBSS\McAfee Agent'
$McDLP = $HBSS + '\HBSS\McAfee DLP'
$McHIPS = $HBSS + '\HBSS\McAfee HIPS'
$McPA = $HBSS + '\HBSS\McAfee PA'
$McVSE = $HBSS + '\HBSS\McAfee VSE'
$MDSSII = $InstallPath + '\MDSS II'
$PLMS = $InstallPath + '\PLMS'
$Proxy = $HBSS + '\HBSS\MRAN Proxy'
$PST = $InstallPath + '\PsTools'
$SCCM = $HBSS + '\HBSS\SCCM'
$SoftLink = $InstallPath + '\SoftLink'
$WinIATS = $InstallPath + '\WinIATS'
$WMDC = $InstallPath + '\WMDC'

$TempPath = $PSScriptRoot + '\TempFiles'
$TestTemp = Test-Path $TempPath



Function CopyComplete
{
 If ($TestTemp -eq $True) {Remove-Item -Path $TempPath -Force -Recurse}
 
 $Form = New-Object System.Windows.Forms.Form
 $Form.Text = 'S.A.W'
 $Form.Size = '300,200'
 $Form.StartPosition = 'CenterScreen'

 $OKButton = New-Object System.Windows.Forms.Button
 $OKButton.Location = '100,120'
 $OKButton.Size = '75,23'
 $OKButton.Text = 'OK'
 $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
 $Form.AcceptButton = $OKButton
 $Form.Controls.Add($OKButton)

 $Label = New-Object System.Windows.Forms.Label
 $Label.Location = '10,10'
 $Label.Size = '270,110'
 $Label.Text = 'All necessary files have been copied to the host machine. Please select "OK" and close all windows, then safely remove your external hard drive. Once you have safely removed and unplugged your external hard drive from the host machine, open the desktop folder named "TempFolder" and run the "AutoScript.bat" file as an administrator.'
 $Form.Controls.Add($Label)

 $Form.Topmost = $True
 $Result = $Form.ShowDialog()
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

 If ($TestTemp -eq $false) {New-Item -path $TempPath -ItemType Directory -Force | Out-Null}
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
 #Start-Sleep -Seconds 2
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



Function Fixes-Patches
{
 $Form = New-Object System.Windows.Forms.Form
 $Form.Text = 'Fixes and Patches'
 $Form.Size = '300,200'
 $Form.StartPosition = 'CenterScreen'
    
 $OKButton = New-Object System.Windows.Forms.Button
 $OKButton.Location = '35,130'
 $OKButton.Size = '75,23'
 $OKButton.Text = 'OK'
 $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
 $Form.AcceptButton = $OKButton
 $Form.Controls.Add($OKButton)
 
 $CancelButton = New-Object System.Windows.Forms.Button
 $CancelButton.Location = '175,130'
 $CancelButton.Size = '75,23'
 $CancelButton.Text = 'Cancel'
 $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
 $Form.CancelButton = $CancelButton
 $Form.Controls.Add($CancelButton)
 
 $Label = New-Object System.Windows.Forms.Label
 $Label.Location = '05,05'
 $Label.Size = '295,25'
 $Label.Text = 'Please select all that apply.', '(These patches will change as the scripts get updated to include these changes.)'
 $Form.Controls.Add($Label)
 
 $TF1Checkbox = New-Object System.Windows.Forms.Checkbox
 $TF1Checkbox.Location = '10,40'
 $TF1Checkbox.Size = '250,15'
 $TF1Checkbox.Text = 'N/A'
 $Form.Controls.Add($TF1Checkbox)
 
 $TF2Checkbox = New-Object System.Windows.Forms.Checkbox
 $TF2Checkbox.Location = '10,55'
 $TF2Checkbox.Size = '250,15'
 $TF2Checkbox.Text = 'N/A'
 $Form.Controls.Add($TF2Checkbox)
 
 $TF3Checkbox = New-Object System.Windows.Forms.Checkbox
 $TF3Checkbox.Location = '10,70'
 $TF3Checkbox.Size = '250,15'
 $TF3Checkbox.Text = 'N/A'
 $Form.Controls.Add($TF3Checkbox)
 
 $TF4Checkbox = New-Object System.Windows.Forms.Checkbox
 $TF4Checkbox.Location = '10,85'
 $TF4Checkbox.Size = '250,15'
 $TF4Checkbox.Text = 'N/A'
 $Form.Controls.Add($TF4Checkbox)
 
 $TF5Checkbox = New-Object System.Windows.Forms.Checkbox
 $TF5Checkbox.Location = '10,100'
 $TF5Checkbox.Size = '250,15'
 $TF5Checkbox.Text = 'N/A'
 $Form.Controls.Add($TF5Checkbox)

 $Form.Topmost = $True
 $Result = $Form.ShowDialog()
 
 If ($Result -eq [System.Windows.Forms.DialogResult]::OK)
   {
    If ($TF1Checkbox.Checked -eq $True) {}
    If ($TF2Checkbox.Checked -eq $True) {}
    If ($TF3Checkbox.Checked -eq $True) {}
    If ($TF4Checkbox.Checked -eq $True) {}
    If ($TF5Checkbox.Checked -eq $True) {}
    Robocopy $PSScriptRoot $ScriptDes 'AutoFixes.bat' /R:3 /W:10
   }
}


Function Uncheck-SlA1
{
 $SlA1Checkbox.Checked = $False
}



Function Custom-Uninstall
{
 $Form = New-Object System.Windows.Forms.Form
 $Form.Text = 'S.A.W'
 $Form.Size = '450,430'
 $Form.StartPosition = 'CenterScreen'
 
 $OKButton = New-Object System.Windows.Forms.Button
 $OKButton.Location = '100,360'
 $OKButton.Size = '75,23'
 $OKButton.Text = 'OK'
 $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
 $Form.AcceptButton = $OKButton
 $Form.Controls.Add($OKButton)
 
 $CancelButton = New-Object System.Windows.Forms.Button
 $CancelButton.Location = '250,360'
 $CancelButton.Size = '75,23'
 $CancelButton.Text = 'Cancel'
 $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
 $Form.CancelButton = $CancelButton
 $Form.Controls.Add($CancelButton)
 
 $Label = New-Object System.Windows.Forms.Label
 $Label.Location = '50,05'
 $Label.Size = '430,15'
 $Label.Text = 'Which programs would you like to uninstall? Select all that apply.'
 $Form.Controls.Add($Label)
 
 $Label = New-Object System.Windows.Forms.Label
 $Label.Location = '05,20'
 $Label.Size = '430,30'
 $Label.Text = '(Options with a * next to them are HBSS programs. Options with a ** next to them have not been added yet.)'
 $Form.Controls.Add($Label)
 
 $ACCMCheckbox = New-Object System.Windows.Forms.Checkbox
 $ACCMCheckbox.Location = '10,50'
 $ACCMCheckbox.Size = '120,20'
 $ACCMCheckbox.Text = 'ACCM*'
 $ACCMCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($ACCMCheckbox)
 
 $AFPCheckbox = New-Object System.Windows.Forms.Checkbox
 $AFPCheckbox.Location = '10,75'
 $AFPCheckbox.Size = '120,20'
 $AFPCheckbox.Text = 'Adobe FlashPlayer'
 $AFPCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($AFPCheckbox)
 
 $ARCheckbox = New-Object System.Windows.Forms.Checkbox
 $ARCheckbox.Location = '10,100'
 $ARCheckbox.Size = '120,20'
 $ARCheckbox.Text = 'Adobe Reader DC'
 $ARCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($ARCheckbox)
 
 $ASWCheckbox = New-Object System.Windows.Forms.Checkbox
 $ASWCheckbox.Location = '10,125'
 $ASWCheckbox.Size = '120,20'
 $ASWCheckbox.Text = 'Adobe ShockWave'
 $ASWCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($ASWCheckbox)

 $AMSCheckbox = New-Object System.Windows.Forms.Checkbox
 $AMSCheckbox.Location = '10,150'
 $AMSCheckbox.Size = '120,20'
 $AMSCheckbox.Text = 'AMSTAC'
 $AMSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($AMSCheckbox)
 
 $BFCheckbox = New-Object System.Windows.Forms.Checkbox
 $BFCheckbox.Location = '10,175'
 $BFCheckbox.Size = '120,20'
 $BFCheckbox.Text = 'BigFix*'
 $BFCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($BFCheckbox)

 $DDSCheckbox = New-Object System.Windows.Forms.Checkbox
 $DDSCheckbox.Location = '10,200'
 $DDSCheckbox.Size = '120,20'
 $DDSCheckbox.Text = 'DDS**'
 $DDSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($DDSCheckbox)
 
 $DTODSCheckbox = New-Object System.Windows.Forms.Checkbox
 $DTODSCheckbox.Location = '10,225'
 $DTODSCheckbox.Size = '120,20'
 $DTODSCheckbox.Text = 'DTODS**'
 $DTODSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($DTODSCheckbox)
 
 $EMSNGCheckbox = New-Object System.Windows.Forms.Checkbox
 $EMSNGCheckbox.Location = '10,250'
 $EMSNGCheckbox.Size = '120,20'
 $EMSNGCheckbox.Text = 'EMS-NG'
 $EMSNGCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($EMSNGCheckbox)
 
 $FEDCheckbox = New-Object System.Windows.Forms.Checkbox
 $FEDCheckbox.Location = '10,275'
 $FEDCheckbox.Size = '120,20'
 $FEDCheckbox.Text = 'FED LOG'
 $FEDCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($FEDCheckbox)

 $JavaCheckbox = New-Object System.Windows.Forms.Checkbox
 $JavaCheckbox.Location = '10,300'
 $JavaCheckbox.Size = '120,20'
 $JavaCheckbox.Text = 'Java'
 $JavaCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($JavaCheckbox)

 $McAgntCheckbox = New-Object System.Windows.Forms.Checkbox
 $McAgntCheckbox.Location = '130,50'
 $McAgntCheckbox.Size = '120,20'
 $McAgntCheckbox.Text = 'McAfee Agent*'
 $McAgntCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($McAgntCheckbox)
 
 $McDLPCheckbox = New-Object System.Windows.Forms.Checkbox
 $McDLPCheckbox.Location = '130,75'
 $McDLPCheckbox.Size = '120,20'
 $McDLPCheckbox.Text = 'McAfee DLP*'
 $McDLPCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($McDLPCheckbox)

 $McHIPSCheckbox = New-Object System.Windows.Forms.Checkbox
 $McHIPSCheckbox.Location = '130,100'
 $McHIPSCheckbox.Size = '120,20'
 $McHIPSCheckbox.Text = 'McAfee HIPS*'
 $McHIPSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($McHIPSCheckbox)

 $McPACheckbox = New-Object System.Windows.Forms.Checkbox
 $McPACheckbox.Location = '130,125'
 $McPACheckbox.Size = '120,20'
 $McPACheckbox.Text = 'McAfee PA*'
 $McPACheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($McPACheckbox)

 $McVSECheckbox = New-Object System.Windows.Forms.Checkbox
 $McVSECheckbox.Location = '130,150'
 $McVSECheckbox.Size = '120,20'
 $McVSECheckbox.Text = 'McAfee VSE*'
 $McVSECheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($McVSECheckbox)

 $MDSSCheckbox = New-Object System.Windows.Forms.Checkbox
 $MDSSCheckbox.Location = '130,175'
 $MDSSCheckbox.Size = '120,20'
 $MDSSCheckbox.Text = 'MDSS II'
 $MDSSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($MDSSCheckbox)

 $ProxyCheckbox = New-Object System.Windows.Forms.Checkbox
 $ProxyCheckbox.Location = '130,200'
 $ProxyCheckbox.Size = '120,20'
 $ProxyCheckbox.Text = 'MRAN Proxy'
 $ProxyCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($ProxyCheckbox)

 $PLMSCheckbox = New-Object System.Windows.Forms.Checkbox
 $PLMSCheckbox.Location = '130,225'
 $PLMSCheckbox.Size = '120,20'
 $PLMSCheckbox.Text = 'PLMS'
 $PLMSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($PLMSCheckbox)

 $PSTCheckbox = New-Object System.Windows.Forms.Checkbox
 $PSTCheckbox.Location = '130,250'
 $PSTCheckbox.Size = '120,20'
 $PSTCheckbox.Text = 'PS Tools'
 $PSTCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($PSTCheckbox)
 
 $SCCMCheckbox = New-Object System.Windows.Forms.Checkbox
 $SCCMCheckbox.Location = '130,275'
 $SCCMCheckbox.Size = '120,20'
 $SCCMCheckbox.Text = 'SCCM*'
 $SCCMCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($SCCMCheckbox)
 
 $SftLnkCheckbox = New-Object System.Windows.Forms.Checkbox
 $SftLnkCheckbox.Location = '130,300'
 $SftLnkCheckbox.Size = '120,20'
 $SftLnkCheckbox.Text = 'SoftLink'
 $SftLnkCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($SftLnkCheckbox)

 $WIATSCheckbox = New-Object System.Windows.Forms.Checkbox
 $WIATSCheckbox.Location = '250,50'
 $WIATSCheckbox.Size = '120,20'
 $WIATSCheckbox.Text = 'WinIATS**'
 $WIATSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($WIATSCheckbox)

 $WMDCCheckbox = New-Object System.Windows.Forms.Checkbox
 $WMDCCheckbox.Location = '250,75'
 $WMDCCheckbox.Size = '180,20'
 $WMDCCheckbox.Text = 'Windows Mobile Device Center'
 $WMDCCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($WMDCCheckbox)

 $SlA1Checkbox = New-Object System.Windows.Forms.Checkbox
 $SlA1Checkbox.Location = '100,330'
 $SlA1Checkbox.Size = '100,20'
 $SlA1Checkbox.Text = "Select All"
 $SlA1Checkbox.Add_Click({
    If ($SlA1Checkbox.Checked -eq $True)
      {
       $USlA1Checkbox.Checked = $False
       $ACCMCheckbox.Checked = $True
       $AFPCheckbox.Checked = $True
       $ARCheckbox.Checked = $True
       $ASWCheckbox.Checked = $True
       $AMSCheckbox.Checked = $True
       $BFCheckbox.Checked = $True
       $DDSCheckbox.Checked = $True
       $DTODSCheckbox.Checked = $True
       $EMSNGCheckbox.Checked = $True
       $FEDCheckbox.Checked = $True
       $JavaCheckbox.Checked = $True
       $McAgntCheckbox.Checked = $True
       $McDLPCheckbox.Checked = $True
       $McHIPSCheckbox.Checked = $True
       $McPACheckbox.Checked = $True
       $McVSECheckbox.Checked = $True
       $MDSSCheckbox.Checked = $True
       $ProxyCheckbox.Checked = $True
       $PLMSCheckbox.Checked = $True
       $PSTCheckbox.Checked = $True
       $SCCMCheckbox.Checked = $True
       $SftLnkCheckbox.Checked = $True
       $WIATSCheckbox.Checked = $True
       $WMDCCheckbox.Checked = $True
      }
})
 $Form.Controls.Add($SlA1Checkbox)

 $USlA1Checkbox = New-Object System.Windows.Forms.Checkbox
 $USlA1Checkbox.Location = '250,330'
 $USlA1Checkbox.Size = '100,20'
 $USlA1Checkbox.Text = "Unselect All"
 $USlA1Checkbox.Add_Click({
    If ($USlA1Checkbox.Checked -eq $True)
      {
       $SlA1Checkbox.Checked = $False
       $ACCMCheckbox.Checked = $False
       $AFPCheckbox.Checked = $False
       $ARCheckbox.Checked = $False
       $ASWCheckbox.Checked = $False
       $AMSCheckbox.Checked = $False
       $BFCheckbox.Checked = $False
       $DDSCheckbox.Checked = $False
       $DTODSCheckbox.Checked = $False
       $EMSNGCheckbox.Checked = $False
       $FEDCheckbox.Checked = $False
       $JavaCheckbox.Checked = $False
       $McAgntCheckbox.Checked = $False
       $McDLPCheckbox.Checked = $False
       $McHIPSCheckbox.Checked = $False
       $McPACheckbox.Checked = $False
       $McVSECheckbox.Checked = $False
       $MDSSCheckbox.Checked = $False
       $ProxyCheckbox.Checked = $False
       $PLMSCheckbox.Checked = $False
       $PSTCheckbox.Checked = $False
       $SCCMCheckbox.Checked = $False
       $SftLnkCheckbox.Checked = $False
       $WIATSCheckbox.Checked = $False
       $WMDCCheckbox.Checked = $False
       $USlA1CheckBox.Checked = $False
      }
})
 $Form.Controls.Add($USlA1Checkbox)
 $Form.Topmost = $True
 $Result = $Form.ShowDialog()

 If ($Result -eq [System.Windows.Forms.DialogResult]::OK)
   {
    If ($ACCMCheckbox.Checked -eq $True) {CopyWPB $ACCM $DesPath -ErrorAction SilentlyContinue}
    If ($AFPCheckbox.Checked -eq $True) {CopyWPB $AFP $DesPath\Adobe -ErrorAction SilentlyContinue}
    If ($ARCheckbox.Checked -eq $True) {CopyWPB $AR $DesPath\Adobe -ErrorAction SilentlyContinue}
    If ($ASWCheckbox.Checked -eq $True) {CopyWPB $ASW $DesPath\Adobe -ErrorAction SilentlyContinue}
    If ($AMSCheckbox.Checked -eq $True) {CopyWPB $AMS $DesPath -ErrorAction SilentlyContinue}
    If ($BFCheckbox.Checked -eq $True) {CopyWPB $BigFix $DesPath -ErrorAction SilentlyContinue}
    If ($DDSCheckbox.Checked -eq $True) {CopyWPB $DDS $DesPath -ErrorAction SilentlyContinue}
    If ($DTODSCheckbox.Checked -eq $True) {CopyWPB $DTODS $DesPath -ErrorAction SilentlyContinue}
    If ($EMSNGCheckbox.Checked -eq $True) {CopyWPB $EMSNG $DesPath -ErrorAction SilentlyContinue}
    If ($FEDCheckbox.Checked -eq $True) {CopyWPB $FEDLOG $DesPath -ErrorAction SilentlyContinue}
    If ($JavaCheckbox.Checked -eq $True) {CopyWPB $Java $DesPath -ErrorAction SilentlyContinue}
    If ($McAgntCheckbox.Checked -eq $True) {CopyWPB $McAgent $DesPath -ErrorAction SilentlyContinue}
    If ($McDLPCheckbox.Checked -eq $True) {CopyWPB $McDLP $DesPath -ErrorAction SilentlyContinue}
    If ($McHIPSCheckbox.Checked -eq $True) {CopyWPB $McHIPS $DesPath -ErrorAction SilentlyContinue}
    If ($McPACheckbox.Checked -eq $True) {CopyWPB $McPA $DesPath -ErrorAction SilentlyContinue}
    If ($McVSECheckbox.Checked -eq $True) {CopyWPB $McVSE $DesPath -ErrorAction SilentlyContinue}
    If ($MDSSCheckbox.Checked -eq $True) {CopyWPB $MDSSII $DesPath -ErrorAction SilentlyContinue}
    If ($PLMSCheckbox.Checked -eq $True) {CopyWPB $PLMS $DesPath -ErrorAction SilentlyContinue}
    If ($ProxyCheckbox.Checked -eq $True) {CopyeWPB $Proxy $DesPath -ErrorAction SilentlyContinue}
    If ($PSTCheckbox.Checked -eq $True) {CopyWPB $PST $DesPath -ErrorAction SilentlyContinue}
    If ($PSTCheckbox.Checked -eq $True) {Robocopy $PSScriptRoot $ScriptDes 'Stop HIPS.bat'  /R:3 /W:10}
    If ($SCCMCheckbox.Checked -eq $True) {CopyWPB $SCCM $DesPath -ErrorAction SilentlyContinue}
    If ($SftLnkCheckbox.Checked -eq $True) {CopyWPB $SoftLink $DesPath -ErrorAction SilentlyContinue}
    If ($WIATSCheckbox.Checked -eq $True) {CopyWPB $WinIATS $DesPath -ErrorAction SilentlyContinue}
    If ($WMDCCheckbox.Checked -eq $True) {CopyWPB $WMDC $DesPath -ErrorAction SilentlyContinue}
    CopyComplete
   }
}



Function FMS-Install
{
 CopyWPB $DDS $DesPath -ErrorAction SilentlyContinue
 CopyWPB $DTODS $DesPath -ErrorAction SilentlyContinue
 CopyWPB $WinIATS $DesPath -ErrorAction SilentlyContinue
 CopyComplete
}



Function GSS-Install
{
 CopyWPB $AMS $DesPath -ErrorAction SilentlyContinue
 CopyWPB $FEDLOG $DesPath -ErrorAction SilentlyContinue
 CopyWPB $WMDC $DesPath -ErrorAction SilentlyContinue
 CopyComplete
}



Function LOS-Install
{
 CopyWPB $FEDLOG $DesPath -ErrorAction SilentlyContinue
 CopyWPB $MDSSII $DesPath -ErrorAction SilentlyContinue
 CopyWPB $PLMS $DesPath -ErrorAction SilentlyContinue
 CopyComplete
}



Function MTMIC-Install
{
 CopyWPB $EMSNG $DesPath -ErrorAction SilentlyContinue
 CopyWPB $FEDLOG $DesPath -ErrorAction SilentlyContinue
 CopyWPB $PLMS $DesPath -ErrorAction SilentlyContinue
 CopyComplete
}



Function PAS-Install
{
 CopyWPB $SoftLink $DesPath -ErrorAction SilentlyContinue
 CopyComplete
}



Function Uncheck-SlA2
{
 $SlA2Checkbox.Checked = $False
}



Function Custom-Install
{
 $Form = New-Object System.Windows.Forms.Form
 $Form.Text = 'S.A.W'
 $Form.Size = '450,430'
 $Form.StartPosition = 'CenterScreen'
 
 $OKButton = New-Object System.Windows.Forms.Button
 $OKButton.Location = '100,360'
 $OKButton.Size = '75,23'
 $OKButton.Text = 'OK'
 $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
 $Form.AcceptButton = $OKButton
 $Form.Controls.Add($OKButton)
 
 $CancelButton = New-Object System.Windows.Forms.Button
 $CancelButton.Location = '250,360'
 $CancelButton.Size = '75,23'
 $CancelButton.Text = 'Cancel'
 $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
 $Form.CancelButton = $CancelButton
 $Form.Controls.Add($CancelButton)
 
 $Label = New-Object System.Windows.Forms.Label
 $Label.Location = '50,05'
 $Label.Size = '430,15'
 $Label.Text = 'Which programs would you like to uninstall? Select all that apply.'
 $Form.Controls.Add($Label)
 
 $Label = New-Object System.Windows.Forms.Label
 $Label.Location = '05,20'
 $Label.Size = '430,30'
 $Label.Text = '(Options with a * next to them are HBSS programs. Options with a ** next to them have not been added yet.)'
 $Form.Controls.Add($Label)
 
 $ACCMCheckbox = New-Object System.Windows.Forms.Checkbox
 $ACCMCheckbox.Location = '10,50'
 $ACCMCheckbox.Size = '120,20'
 $ACCMCheckbox.Text = 'ACCM*'
 $ACCMCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($ACCMCheckbox)
 
 $AFPCheckbox = New-Object System.Windows.Forms.Checkbox
 $AFPCheckbox.Location = '10,75'
 $AFPCheckbox.Size = '120,20'
 $AFPCheckbox.Text = 'Adobe FlashPlayer'
 $AFPCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($AFPCheckbox)
 
 $ARCheckbox = New-Object System.Windows.Forms.Checkbox
 $ARCheckbox.Location = '10,100'
 $ARCheckbox.Size = '120,20'
 $ARCheckbox.Text = 'Adobe Reader DC'
 $ARCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($ARCheckbox)
 
 $ASWCheckbox = New-Object System.Windows.Forms.Checkbox
 $ASWCheckbox.Location = '10,125'
 $ASWCheckbox.Size = '120,20'
 $ASWCheckbox.Text = 'Adobe ShockWave'
 $ASWCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($ASWCheckbox)

 $AMSCheckbox = New-Object System.Windows.Forms.Checkbox
 $AMSCheckbox.Location = '10,150'
 $AMSCheckbox.Size = '120,20'
 $AMSCheckbox.Text = 'AMSTAC'
 $AMSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($AMSCheckbox)
 
 $BFCheckbox = New-Object System.Windows.Forms.Checkbox
 $BFCheckbox.Location = '10,175'
 $BFCheckbox.Size = '120,20'
 $BFCheckbox.Text = 'BigFix*'
 $BFCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($BFCheckbox)

 $DDSCheckbox = New-Object System.Windows.Forms.Checkbox
 $DDSCheckbox.Location = '10,200'
 $DDSCheckbox.Size = '120,20'
 $DDSCheckbox.Text = 'DDS**'
 $DDSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($DDSCheckbox)
 
 $DTODSCheckbox = New-Object System.Windows.Forms.Checkbox
 $DTODSCheckbox.Location = '10,225'
 $DTODSCheckbox.Size = '120,20'
 $DTODSCheckbox.Text = 'DTODS**'
 $DTODSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($DTODSCheckbox)
 
 $EMSNGCheckbox = New-Object System.Windows.Forms.Checkbox
 $EMSNGCheckbox.Location = '10,250'
 $EMSNGCheckbox.Size = '120,20'
 $EMSNGCheckbox.Text = 'EMS-NG'
 $EMSNGCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($EMSNGCheckbox)
 
 $FEDCheckbox = New-Object System.Windows.Forms.Checkbox
 $FEDCheckbox.Location = '10,275'
 $FEDCheckbox.Size = '120,20'
 $FEDCheckbox.Text = 'FED LOG'
 $FEDCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($FEDCheckbox)

 $JavaCheckbox = New-Object System.Windows.Forms.Checkbox
 $JavaCheckbox.Location = '10,300'
 $JavaCheckbox.Size = '120,20'
 $JavaCheckbox.Text = 'Java'
 $JavaCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($JavaCheckbox)

 $McAgntCheckbox = New-Object System.Windows.Forms.Checkbox
 $McAgntCheckbox.Location = '130,50'
 $McAgntCheckbox.Size = '120,20'
 $McAgntCheckbox.Text = 'McAfee Agent*'
 $McAgntCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($McAgntCheckbox)
 
 $McDLPCheckbox = New-Object System.Windows.Forms.Checkbox
 $McDLPCheckbox.Location = '130,75'
 $McDLPCheckbox.Size = '120,20'
 $McDLPCheckbox.Text = 'McAfee DLP*'
 $McDLPCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($McDLPCheckbox)

 $McHIPSCheckbox = New-Object System.Windows.Forms.Checkbox
 $McHIPSCheckbox.Location = '130,100'
 $McHIPSCheckbox.Size = '120,20'
 $McHIPSCheckbox.Text = 'McAfee HIPS*'
 $McHIPSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($McHIPSCheckbox)

 $McPACheckbox = New-Object System.Windows.Forms.Checkbox
 $McPACheckbox.Location = '130,125'
 $McPACheckbox.Size = '120,20'
 $McPACheckbox.Text = 'McAfee PA*'
 $McPACheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($McPACheckbox)

 $McVSECheckbox = New-Object System.Windows.Forms.Checkbox
 $McVSECheckbox.Location = '130,150'
 $McVSECheckbox.Size = '120,20'
 $McVSECheckbox.Text = 'McAfee VSE*'
 $McVSECheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($McVSECheckbox)

 $MDSSCheckbox = New-Object System.Windows.Forms.Checkbox
 $MDSSCheckbox.Location = '130,175'
 $MDSSCheckbox.Size = '120,20'
 $MDSSCheckbox.Text = 'MDSS II'
 $MDSSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($MDSSCheckbox)

 $ProxyCheckbox = New-Object System.Windows.Forms.Checkbox
 $ProxyCheckbox.Location = '130,200'
 $ProxyCheckbox.Size = '120,20'
 $ProxyCheckbox.Text = 'MRAN Proxy'
 $ProxyCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($ProxyCheckbox)

 $PLMSCheckbox = New-Object System.Windows.Forms.Checkbox
 $PLMSCheckbox.Location = '130,225'
 $PLMSCheckbox.Size = '120,20'
 $PLMSCheckbox.Text = 'PLMS'
 $PLMSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($PLMSCheckbox)

 $PSTCheckbox = New-Object System.Windows.Forms.Checkbox
 $PSTCheckbox.Location = '130,250'
 $PSTCheckbox.Size = '120,20'
 $PSTCheckbox.Text = 'PS Tools'
 $PSTCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($PSTCheckbox)
 
 $SCCMCheckbox = New-Object System.Windows.Forms.Checkbox
 $SCCMCheckbox.Location = '130,275'
 $SCCMCheckbox.Size = '120,20'
 $SCCMCheckbox.Text = 'SCCM*'
 $SCCMCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($SCCMCheckbox)
 
 $SftLnkCheckbox = New-Object System.Windows.Forms.Checkbox
 $SftLnkCheckbox.Location = '130,300'
 $SftLnkCheckbox.Size = '120,20'
 $SftLnkCheckbox.Text = 'SoftLink'
 $SftLnkCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($SftLnkCheckbox)

 $WIATSCheckbox = New-Object System.Windows.Forms.Checkbox
 $WIATSCheckbox.Location = '250,50'
 $WIATSCheckbox.Size = '120,20'
 $WIATSCheckbox.Text = 'WinIATS**'
 $WIATSCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($WIATSCheckbox)

 $WMDCCheckbox = New-Object System.Windows.Forms.Checkbox
 $WMDCCheckbox.Location = '250,75'
 $WMDCCheckbox.Size = '180,20'
 $WMDCCheckbox.Text = 'Windows Mobile Device Center'
 $WMDCCheckbox.add_click({ Uncheck-SlA1 })
 $Form.Controls.Add($WMDCCheckbox)

 $SlA1Checkbox = New-Object System.Windows.Forms.Checkbox
 $SlA1Checkbox.Location = '100,330'
 $SlA1Checkbox.Size = '100,20'
 $SlA1Checkbox.Text = "Select All"
 $SlA1Checkbox.Add_Click({
    If ($SlA1Checkbox.Checked -eq $True)
      {
       $USlA1Checkbox.Checked = $False
       $ACCMCheckbox.Checked = $True
       $AFPCheckbox.Checked = $True
       $ARCheckbox.Checked = $True
       $ASWCheckbox.Checked = $True
       $AMSCheckbox.Checked = $True
       $BFCheckbox.Checked = $True
       $DDSCheckbox.Checked = $True
       $DTODSCheckbox.Checked = $True
       $EMSNGCheckbox.Checked = $True
       $FEDCheckbox.Checked = $True
       $JavaCheckbox.Checked = $True
       $McAgntCheckbox.Checked = $True
       $McDLPCheckbox.Checked = $True
       $McHIPSCheckbox.Checked = $True
       $McPACheckbox.Checked = $True
       $McVSECheckbox.Checked = $True
       $MDSSCheckbox.Checked = $True
       $ProxyCheckbox.Checked = $True
       $PLMSCheckbox.Checked = $True
       $PSTCheckbox.Checked = $True
       $SCCMCheckbox.Checked = $True
       $SftLnkCheckbox.Checked = $True
       $WIATSCheckbox.Checked = $True
       $WMDCCheckbox.Checked = $True
      }
})
 $Form.Controls.Add($SlA1Checkbox)

 $USlA1Checkbox = New-Object System.Windows.Forms.Checkbox
 $USlA1Checkbox.Location = '250,330'
 $USlA1Checkbox.Size = '100,20'
 $USlA1Checkbox.Text = "Unselect All"
 $USlA1Checkbox.Add_Click({
    If ($USlA1Checkbox.Checked -eq $True)
      {
       $SlA1Checkbox.Checked = $False
       $ACCMCheckbox.Checked = $False
       $AFPCheckbox.Checked = $False
       $ARCheckbox.Checked = $False
       $ASWCheckbox.Checked = $False
       $AMSCheckbox.Checked = $False
       $BFCheckbox.Checked = $False
       $DDSCheckbox.Checked = $False
       $DTODSCheckbox.Checked = $False
       $EMSNGCheckbox.Checked = $False
       $FEDCheckbox.Checked = $False
       $JavaCheckbox.Checked = $False
       $McAgntCheckbox.Checked = $False
       $McDLPCheckbox.Checked = $False
       $McHIPSCheckbox.Checked = $False
       $McPACheckbox.Checked = $False
       $McVSECheckbox.Checked = $False
       $MDSSCheckbox.Checked = $False
       $ProxyCheckbox.Checked = $False
       $PLMSCheckbox.Checked = $False
       $PSTCheckbox.Checked = $False
       $SCCMCheckbox.Checked = $False
       $SftLnkCheckbox.Checked = $False
       $WIATSCheckbox.Checked = $False
       $WMDCCheckbox.Checked = $False
       $USlA1CheckBox.Checked = $False
      }
})
 $Form.Controls.Add($USlA1Checkbox)
 $Form.Topmost = $True
 $Result = $Form.ShowDialog()

 If ($Result -eq [System.Windows.Forms.DialogResult]::OK)
   {
    If ($ACCMCheckbox.Checked -eq $True) {CopyWPB $ACCM $DesPath -ErrorAction SilentlyContinue}
    If ($AFPCheckbox.Checked -eq $True) {CopyWPB $AFP $DesPath\Adobe -ErrorAction SilentlyContinue}
    If ($ARCheckbox.Checked -eq $True) {CopyWPB $AR $DesPath\Adobe -ErrorAction SilentlyContinue}
    If ($ASWCheckbox.Checked -eq $True) {CopyWPB $ASW $DesPath\Adobe -ErrorAction SilentlyContinue}
    If ($AMSCheckbox.Checked -eq $True) {CopyWPB $AMS $DesPath -ErrorAction SilentlyContinue}
    If ($BFCheckbox.Checked -eq $True) {CopyWPB $BigFix $DesPath -ErrorAction SilentlyContinue}
    If ($DDSCheckbox.Checked -eq $True) {CopyWPB $DDS $DesPath -ErrorAction SilentlyContinue}
    If ($DTODSCheckbox.Checked -eq $True) {CopyWPB $DTODS $DesPath -ErrorAction SilentlyContinue}
    If ($EMSNGCheckbox.Checked -eq $True) {CopyWPB $EMSNG $DesPath -ErrorAction SilentlyContinue}
    If ($FEDCheckbox.Checked -eq $True) {CopyWPB $FEDLOG $DesPath -ErrorAction SilentlyContinue}
    If ($JavaCheckbox.Checked -eq $True) {CopyWPB $Java $DesPath -ErrorAction SilentlyContinue}
    If ($McAgntCheckbox.Checked -eq $True) {CopyWPB $McAgent $DesPath -ErrorAction SilentlyContinue}
    If ($McDLPCheckbox.Checked -eq $True) {CopyWPB $McDLP $DesPath -ErrorAction SilentlyContinue}
    If ($McHIPSCheckbox.Checked -eq $True) {CopyWPB $McHIPS $DesPath -ErrorAction SilentlyContinue}
    If ($McPACheckbox.Checked -eq $True) {CopyWPB $McPA $DesPath -ErrorAction SilentlyContinue}
    If ($McVSECheckbox.Checked -eq $True) {CopyWPB $McVSE $DesPath -ErrorAction SilentlyContinue}
    If ($MDSSCheckbox.Checked -eq $True) {CopyWPB $MDSSII $DesPath -ErrorAction SilentlyContinue}
    If ($PLMSCheckbox.Checked -eq $True) {CopyWPB $PLMS $DesPath -ErrorAction SilentlyContinue}
    If ($ProxyCheckbox.Checked -eq $True) {CopyWPB $Proxy $DesPath -ErrorAction SilentlyContinue}
    If ($PSTCheckbox.Checked -eq $True) {CopyWPB $PST $DesPath -ErrorAction SilentlyContinue}
    If ($PSTCheckbox.Checked -eq $True) {Robocopy $PSScriptRoot $ScriptDes 'Stop HIPS.bat'  /R:3 /W:10}
    If ($SCCMCheckbox.Checked -eq $True) {CopyWPB $SCCM $DesPath -ErrorAction SilentlyContinue}
    If ($SftLnkCheckbox.Checked -eq $True) {CopyWPB $SoftLink $DesPath -ErrorAction SilentlyContinue}
    If ($WIATSCheckbox.Checked -eq $True) {CopyWPB $WinIATS $DesPath -ErrorAction SilentlyContinue}
    If ($WMDCCheckbox.Checked -eq $True) {CopyWPB $WMDC $DesPath -ErrorAction SilentlyContinue}
    CopyComplete
   }
}



$Form = New-Object System.Windows.Forms.Form
$Form.Text = 'S.A.W'
$Form.Size = '320,350'
$Form.StartPosition = 'CenterScreen'

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = '35,280'
$OKButton.Size = '75,23'
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$Form.AcceptButton = $OKButton
$Form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = '175,280'
$CancelButton.Size = '75,23'
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$Form.CancelButton = $CancelButton
$Form.Controls.Add($CancelButton)

$Label = New-Object System.Windows.Forms.Label
$Label.Location = '05,05'
$Label.Size = '295,25'
$Label.Text = 'Welcome to the Script Assistant Wizard. Please select all that apply.'
$Form.Controls.Add($Label)

$Label = New-Object System.Windows.Forms.Label
$Label.Location = '05,30'
$Label.Size = '300,15'
$Label.Text = '(Options with a ** next to them have not been added yet.)'
$Form.Controls.Add($Label)

$DomCheckbox = New-Object System.Windows.Forms.Checkbox
$DomCheckbox.Location = '10,55'
$DomCheckbox.Size = '180,20'
$DomCheckbox.Text = 'Add Computer to Domain'
$DomCheckbox.Add_Click({
    If ($DomCheckbox.Checked -eq $True)
      {
       $WorkCheckbox.Checked = $False
       $FSCheckbox.Checked = $False
       $UnstlCheckbox.Checked = $False
      }
    })
$Form.Controls.Add($DomCheckbox)

$WorkCheckbox = New-Object System.Windows.Forms.Checkbox
$WorkCheckbox.Location = '10,80'
$WorkCheckbox.Size = '200,20'
$WorkCheckbox.Text = 'Remove Computer from Domain'
$WorkCheckbox.Add_Click({
    If ($WorkCheckbox.Checked -eq $True)
      {
       $DomCheckbox.Checked = $False
       $HBSSCheckbox.Checked = $False
       $FSCheckbox.Checked = $False
       $FaPCheckbox.Checked = $False
      }
    })
$Form.Controls.Add($WorkCheckbox)

$HBSSCheckbox = New-Object System.Windows.Forms.Checkbox
$HBSSCheckbox.Location = '10,105'
$HBSSCheckbox.Size = '180,20'
$HBSSCheckbox.Text = 'Install all HBSS software'
$HBSSCheckbox.Add_Click({
    If ($HBSSCheckbox.Checked -eq $True)
      {
       $WorkCheckbox.Checked = $False
       $FSCheckbox.Checked = $False
       $UnstlCheckbox.Checked = $False
      }
    })
$Form.Controls.Add($HBSSCheckbox)

$FSCheckbox = New-Object System.Windows.Forms.Checkbox
$FSCheckbox.Location = '10,130'
$FSCheckbox.Size = '230,20'
$FSCheckbox.Text = 'This is a newly ReImaged computer'
$FSCheckbox.Add_Click({
    If ($FSCheckbox.Checked -eq $True)
      {
       $DomCheckbox.Checked = $False
       $WorkCheckbox.Checked = $False
       $HBSSCheckbox.Checked = $False
       $FaPCheckbox.Checked = $False
       $UnstlCheckbox.Checked = $False
      }
    })
$Form.Controls.Add($FSCheckbox)

$FaPCheckbox = New-Object System.Windows.Forms.Checkbox
$FaPCheckbox.Location = '10,155'
$FaPCheckbox.Size = '180,20'
$FaPCheckbox.Text = 'Install Fixes and Patches'
$FaPCheckbox.Add_Click({
    If ($FaPCheckbox.Checked -eq $True)
      {
       $DomCheckbox.Checked = $False
       $HBSSCheckbox.Checked = $False
       $FSCheckbox.Checked = $False
       $UnstlCheckbox.Checked = $False
      }
    })
$Form.Controls.Add($FaPCheckbox)

$UnstlCheckbox = New-Object System.Windows.Forms.Checkbox
$UnstlCheckbox.Location = '10,180'
$UnstlCheckbox.Size = '180,20'
$UnstlCheckbox.Text = 'Uninstall software**'
$UnstlCheckbox.Add_Click({
    If ($UnstlCheckbox.Checked -eq $True)
      {
       $DomCheckbox.Checked = $False
       $HBSSCheckbox.Checked = $False
       $FSCheckbox.Checked = $False
       $FaPCheckbox.Checked = $False
      }
    })
$Form.Controls.Add($UnstlCheckbox)

$Label = New-Object System.Windows.Forms.Label
$Label.Location = '05,210'
$Label.Size = '260,15'
$Label.Text = 'Which school will you be installing software for?'
$Form.Controls.Add($Label)

$ComboBox = New-Object System.Windows.Forms.ComboBox
$ComboBox.Items.Add('FMS**')
$ComboBox.Items.Add('GSS')
$ComboBox.Items.Add('LOS')
$ComboBox.Items.Add('MTMIC')
$ComboBox.Items.Add('PAS')
$ComboBox.Items.Add('Custom Installation')
$ComboBox.Location = '10,230'
$ComboBox.Size = '260,30'
$Form.Controls.Add($ComboBox)

$Form.Topmost = $True
$Result = $Form.ShowDialog()


If ($Result -eq [System.Windows.Forms.DialogResult]::OK)
  {
   If ($DomCheckbox.Checked -eq $True) {CopyWPB $Domain $ScriptDes -ErrorAction SilentlyContinue}
   If ($WorkCheckbox.Checked -eq $True) {Robocopy $PSScriptRoot $ScriptDes 'AutoDomainRemoval.bat'  /R:3 /W:10}
   If ($HBSSCheckbox.Checked -eq $True) 
     {
      CopyWPB $HBSS $DesPath -ErrorAction SilentlyContinue
      CopyWPB $AFP $DesPath\Adobe -ErrorAction SilentlyContinue
     }
   If ($FSCheckbox.Checked -eq $True) 
     {
      CopyWPB $Domain $ScriptDes -ErrorAction SilentlyContinue
      CopyWPB $HBSS $DesPath -ErrorAction SilentlyContinue
      CopyWPB $AFP $DesPath\Adobe -ErrorAction SilentlyContinue
      Robocopy $PSScriptRoot $ScriptDes 'Activate Product Keys.bat'  /R:3 /W:10
     }
   If ($FaPCheckbox.Checked -eq $True) {Fixes-Patches}
   If ($UnstlCheckbox.Checked -eq $True) {Custom-Uninstall}
   If ((Test-Path 'C:\PsTools') -eq $False) {CopyWPB $PST $DesPath -ErrorAction SilentlyContinue}
   If ((Test-Path 'C:\Users\mceds-admin\Desktop\Stop HIPS.bat') -eq $False) {Robocopy $PSScriptRoot $ScriptDes 'Stop HIPS.bat'  /R:3 /W:10}
   Robocopy $PSScriptRoot $DesPath 'AutoScript.bat'  /R:3 /W:10
   Robocopy $PSScriptRoot $ScriptDes 'ECAS.bat'  /R:3 /W:10
   Robocopy $PSScriptRoot $ScriptDes 'WARNING.bat'  /R:3 /W:10
   If ($ComboBox.SelectedItem -eq 'FMS**') {FMS-Install}
   If ($ComboBox.SelectedItem -eq 'GSS') {GSS-Install}
   If ($ComboBox.SelectedItem -eq 'LOS') {LOS-Install}
   If ($ComboBox.SelectedItem -eq 'MTMIC') {MTMIC-Install}
   If ($ComboBox.SelectedItem -eq 'PAS') {PAS-Install}
   If ($ComboBox.SelectedItem -eq 'Custom Installation') {Custom-Install}
   If ($ComboBox.SelectedItem -eq $Null -and $UnstlCheckbox.Checked -eq $False) {CopyComplete}
}

If ($Result -eq [System.Windows.Forms.DialogResult]::Cancel)
  {
   If ($TestTemp -eq $True) {Remove-Item -Path $TempPath -Force -Recurse}
  }