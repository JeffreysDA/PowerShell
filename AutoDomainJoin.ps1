<#
AUTHOR  : Duncan Jeffreys
CREATED : 06/21/2018
UPDATED : 02/12/2021
COMMENTS: 
Uses a Shared Credential file from the CredentialCreator.ps1 script to automatically rename and add computers to a domain.
#>

<#Credential File Variables#>
$SharedCredFile = "PLACE FULL PATH TO SHARED CREDENTIAL FILE HERE" #EXAMPLE: "C:\Users\User\Desktop\SharedCredential_MySharedCredentials.xml"
$KeyFile = "PLACE FULL PATH TO SHARED CREDENTIAL DECRYPTION KEY FILE HERE" #EXAMPLE: "C:\Users\User\Desktop\SharedCredential_MySharedCredentials.key"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Computer Info"
$objForm.Size = New-Object System.Drawing.Size(300,300) 
$objForm.StartPosition = "CenterScreen"

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(50,220)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$objTextBoxBldg.Text;$objTextBoxRoom.Text;$objTextBoxComp.Text;$objForm.Close()})
$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(160,220)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabelText = New-Object System.Windows.Forms.Label
$objLabelText.Location = New-Object System.Drawing.Size(10,20) 
$objLabelText.Size = New-Object System.Drawing.Size(280,40) 
$objLabelText.Text = "ONLY TYPE IN NUMBERS. DO NOT TYPE IN LETTERS OR SYMBOLS!"
$objForm.Controls.Add($objLabelText)

$objLabelBldg = New-Object System.Windows.Forms.Label
$objLabelBldg.Location = New-Object System.Drawing.Size(10,60) 
$objLabelBldg.Size = New-Object System.Drawing.Size(280,20) 
$objLabelBldg.Text = "Building Number:"
$objForm.Controls.Add($objLabelBldg) 

$objTextBoxBldg = New-Object System.Windows.Forms.TextBox 
$objTextBoxBldg.Location = New-Object System.Drawing.Size(10,80) 
$objTextBoxBldg.Size = New-Object System.Drawing.Size(260,20) 
$objForm.Controls.Add($objTextBoxBldg) 

$objLabelRoom = New-Object System.Windows.Forms.Label
$objLabelRoom.Location = New-Object System.Drawing.Size(10,110) 
$objLabelRoom.Size = New-Object System.Drawing.Size(280,20) 
$objLabelRoom.Text = "Room Number:"
$objForm.Controls.Add($objLabelRoom) 

$objTextBoxRoom = New-Object System.Windows.Forms.TextBox 
$objTextBoxRoom.Location = New-Object System.Drawing.Size(10,130) 
$objTextBoxRoom.Size = New-Object System.Drawing.Size(260,20) 
$objForm.Controls.Add($objTextBoxRoom) 

$objLabelComp = New-Object System.Windows.Forms.Label
$objLabelComp.Location = New-Object System.Drawing.Size(10,160) 
$objLabelComp.Size = New-Object System.Drawing.Size(280,20) 
$objLabelComp.Text = "Computer Number:"
$objForm.Controls.Add($objLabelComp) 

$objTextBoxComp = New-Object System.Windows.Forms.TextBox 
$objTextBoxComp.Location = New-Object System.Drawing.Size(10,180) 
$objTextBoxComp.Size = New-Object System.Drawing.Size(260,20) 
$objForm.Controls.Add($objTextBoxComp) 

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
$objForm.ShowDialog()


$Key = Get-Content $KeyFile
$ImportSharedCred = Import-CliXml -Path $SharedCredFile
$SharedCredPass = ConvertTo-SecureString -String $ImportSharedCred.Password -Key $Key
$Domain = 'Fully Qualified Domain Name Goes Here'
$Computer = ($objTextBoxBldg.Text + $objTextBoxRoom.Text + $objTextBoxComp.Text)
$Credentials = New-Object System.Management.Automation.PSCredential ("domain\$ImportSharedCred.UserName", $SharedCredPass)
Rename-Computer $Computer
Add-Computer -DomainName $Domain -Options JoinWithNewName -Credential $Credentials -PassThru -Verbose -Force
