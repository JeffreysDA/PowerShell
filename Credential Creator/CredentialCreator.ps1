<#
AUTHOR  : Duncan Jeffreys
CREATED : 02/09/2021
UPDATED : 02/12/2021
COMMENTS: 
Easy to use GUI to allow the creation of username and password credential files, that can be either exclusive to the host, or shared and used on any account and machine.
#>


<#Adds the necessary assemblies to display a GUI#>
Add-Type -AssemblyName System.Drawing, System.Windows.Forms, PresentationCore, PresentationFramework

<#Set the folder that created Credential files will be exported to.#>
$OutputFolder = "$env:USERPROFILE\Desktop\Credentials"

<#Script Variables#>
[String]$Script:ScriptName = 'Credential Creator'
[String]$Script:ScriptVersion = '2.0'


<#Primary Function to create the actual credential files#>
Function Create-Credential {
  Param ([Parameter(Mandatory = $True)]
         [ValidateSet('Exclusive','Shared')]
         [String]$CredentialType = 'Exclusive',
         [Parameter(Mandatory = $True)]
         [String]$Username,
         [Parameter(Mandatory = $True)]
         [String]$Password,
         [Parameter(Mandatory = $False)]
         [String]$CredentialName
        )


  <#Creates the output folder if it does not already exist
  The '-Force' Parameter can allow the creation of nested directories if needed#>
  If (!(Test-Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force
  }

  <#Determine how to creat the credential files based on the type of Credential file being created#>
  If ($CredentialType -eq 'Exclusive') {
    <#Check if custom Credential name was specified#>
    If ($CredentialName -eq $Null -or $CredentialName -eq '') {
      $CredentialName = "${env:USERNAME}_${env:COMPUTERNAME}"
    }

    <#Convert the plain text password into a secure string#>
    [SecureString]$SecPass = ConvertTo-SecureString $Password -AsPlainText -Force
    
    <#Create a PSCredential object using the username and securestring password, 
    then export that credential object into a xml file.#>
    [PSCredential]$Credential = New-Object System.Management.Automation.PSCredential($Username, $SecPass) |
      Export-CliXml -Path "$OutputFolder\ExclusiveCredential_$CredentialName.xml"

    <#Set new credential path as a variable to test the path for confirmation#>
    $CredentialFile = "$OutputFolder\ExclusiveCredential_$CredentialName.xml"

    <#Verify that the Credential file was created, then display a message to the user letting them know the results#>
    If (Test-Path $CredentialFile -PathType Leaf) {
      [System.Windows.MessageBox]::Show("Credential file successfully created! Your new Credential file can be found at:`n$CredentialFile",
      'Credential File Created','OK','Information')
    }
    Else {
      <#Quietly attempt to delete partial file#>
      If (Test-Path $CredentialFile -PathType Leaf -ErrorAction SilentlyContinue) {Remove-Item $CredentialFile | Out-Null}
      [System.Windows.MessageBox]::Show("An error occured while attempting to creat the Credential file.","ERROR",'OK','Error')
    }
  }
  ElseIf ($CredentialType -eq 'Shared') {
    <#Check if custom Credential name was specified#>
    If ($CredentialName -eq $Null -or $CredentialName -eq '') {
      $CredentialName = Get-Date -f 'DyyyyMMddTHHmmss'
    }

    <#Creating empty Key file#>
    $KeyFile = "$OutputFolder\SharedCredential_$CredentialName.key"

    <#Randomly generate AES key string. Bytes are 1/8 the bit count of the AES encryption type, and can only be 16, 24, or 32.
    So 16Bytes = 128Bit AES Encryption, 24Bytes = 192Bit AES Encryption, and 32Bytes = 256Bit AES Encryption#>
    $Key = New-Object Byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)

    <#Inject randomly generated AES key string into the Key file#>
    $Key | Out-File $KeyFile

    <#Redefine Key variable to hold the contents of the Key File#>
    $Key = Get-Content $KeyFile

    <#Convert the plain text password into a securestring#>
    $SecPass = ConvertTo-SecureString $Password -AsPlainText -Force
    
    <#Encrypt secure string password using the newly created AES Key file#>
    $EncPass = ConvertFrom-SecureString -SecureString $SecPass -Key $Key

    <#Create custom Object to act as a Sharable PSCredential object.#>
    $Credential = New-Object PSObject @{
          UserName = $Username
          Password = $EncPass
        }

    <#Inject custom object into xml file#>
    $Credential | Export-CliXml -Path "$OutputFolder\SharedCredential_$CredentialName.xml"

    <#Set new credential path as a variable to test the path for confirmation#>
    $CredentialFile = "$OutputFolder\SharedCredential_$CredentialName.xml"

    <#Verify that Credential file and Key file were created, then display a message to the user letting them know the results#>
    If ((Test-Path $CredentialFile -PathType Leaf) -and (Test-Path $KeyFile -PathType Leaf)) {
      [System.Windows.MessageBox]::Show("Credential and Decryption Key successfully created! Your new Credential can be found at:`n$CredentialFile
`nThe Decryption Key for your new Credential can be found at:`n$KeyFile",'Credential Files Created','OK','Information')
    }
    Else {
      <#Quietly attempt to delete partial files.#>
      If (Test-Path $CredentialFile -PathType Leaf -ErrorAction SilentlyContinue) {Remove-Item $CredentialFile | Out-Null}
      If (Test-Path $KeyFile -PathType Leaf -ErrorAction SilentlyContinue) {Remove-Item $KeyFile | Out-Null}
      [System.Windows.MessageBox]::Show("An error occured while attempting to creat the Credential file, Decryption Key, or both.","ERROR",'OK','Error')
    }
  }
  Else {
    [System.Windows.MessageBox]::Show("The Credential Type could not be identified.`nThe $Script:ScriptName will now exit. ","Critical Error!",'OK','Error')
  }
}




<##################################################GUI WINDOW##################################################>

<#Create the GUI window to display to the User.#>
$Form_Cred = New-Object System.Windows.Forms.Form 
$Form_Cred.Text = "$Script:ScriptName"
$Form_Cred.Size = New-Object System.Drawing.Size(300,325)
$Form_Cred.StartPosition = "CenterScreen"
$Form_Cred.KeyPreview = $True
$Form_Cred.Add_KeyDown({
  <#Allow pressing the 'Enter' key to shift the focus
  from the currently selected item to the next.#>
  If($_.KeyCode -eq "Enter") {
    If ($DropBox_CredType.Focused -eq $True) {
      $TextBox_CredName.Focus()
    }
    ElseIf ($TextBox_CredName.Focused -eq $True) {
      $TextBox_Username.Focus()
    }
    ElseIf ($TextBox_Username.Focused -eq $True) {
      $TextBox_Password.Focus()
    }
    ElseIf ($TextBox_Password.Focused -eq $True) {
      $TextBox_ConfPass.Focus()
    }
    ElseIf ($TextBox_ConfPass.Focused -eq $True) {
      $Button_Create.Focus()
    }
  }
})
$Form_Cred.Add_Shown({$Form_Cred.Activate();$TextBox_Username.Focus()})



<#Create the description text, and add it to the GUI Window.#>
$Label_Desc = New-Object System.Windows.Forms.Label
$Label_Desc.Location = New-Object System.Drawing.Size(05,05) 
$Label_Desc.Size = New-Object System.Drawing.Size(280,25) 
$Label_Desc.Text = "Please selece the type of credential file you would like to create using the dropdown box below."
$Form_Cred.Controls.Add($Label_Desc)


<#Create the dropdown box that will allow the user to choose
the type of Credential that they want to make, and add it to the GUI Window.#>
$DropBox_CredType = New-Object System.Windows.Forms.ComboBox
$DropBox_CredType.Location = New-Object System.Drawing.Point(10,40)
$DropBox_CredType.Size = New-Object System.Drawing.Size(260,30)
$DropBox_CredType.Items.Add('Exclusive')
$DropBox_CredType.Items.Add('Shared')
$DropBox_CredType.SelectedItem = 'Exclusive'
$Form_Cred.Controls.Add($DropBox_CredType)


<#Create the label that will identify the Optional Credential Name input box,
then crete the Credential Name input box, and add them to the GUI Window.#>
$Label_CredName = New-Object System.Windows.Forms.Label
$Label_CredName.Location = New-Object System.Drawing.Size(10,65) 
$Label_CredName.Size = New-Object System.Drawing.Size(280,15) 
$Label_CredName.Text = "Credential Name (Optional):"
$Form_Cred.Controls.Add($Label_CredName) 

$TextBox_CredName = New-Object System.Windows.Forms.TextBox
$TextBox_CredName.Location = New-Object System.Drawing.Size(10,80) 
$TextBox_CredName.Size = New-Object System.Drawing.Size(260,20) 
$Form_Cred.Controls.Add($TextBox_CredName)


<#Create the label that will identify the Username input box,
then crete the Username input box, and add them to the GUI Window.#>
$Label_Username = New-Object System.Windows.Forms.Label
$Label_Username.Location = New-Object System.Drawing.Size(10,115) 
$Label_Username.Size = New-Object System.Drawing.Size(280,15) 
$Label_Username.Text = "Username:"
$Form_Cred.Controls.Add($Label_Username) 

$TextBox_Username = New-Object System.Windows.Forms.TextBox
$TextBox_Username.Location = New-Object System.Drawing.Size(10,130) 
$TextBox_Username.Size = New-Object System.Drawing.Size(260,20)
$Form_Cred.Controls.Add($TextBox_Username)


<#Create the label that will identify the Password input box,
then crete the Password input box, and add them to the GUI Window.#>
$Label_Password = New-Object System.Windows.Forms.Label
$Label_Password.Location = New-Object System.Drawing.Size(10,155) 
$Label_Password.Size = New-Object System.Drawing.Size(280,15) 
$Label_Password.Text = "Password:"
$Form_Cred.Controls.Add($Label_Password)

$TextBox_Password = New-Object System.Windows.Forms.MaskedTextBox
$TextBox_Password.Location = New-Object System.Drawing.Size(10,170)
$TextBox_Password.Size = New-Object System.Drawing.Size(260,20)
$TextBox_Password.UseSystemPasswordChar = $True
$Form_Cred.Controls.Add($TextBox_Password)


<#Create the label that will identify the Confirm Password input box,
then crete the Confirm Password input box, and add them to the GUI Window.#>
$Label_ConfPass = New-Object System.Windows.Forms.Label
$Label_ConfPass.Location = New-Object System.Drawing.Size(10,195) 
$Label_ConfPass.Size = New-Object System.Drawing.Size(280,15) 
$Label_ConfPass.Text = "Confirm Password:"
$Form_Cred.Controls.Add($Label_ConfPass)

$TextBox_ConfPass = New-Object System.Windows.Forms.MaskedTextBox
$TextBox_ConfPass.Location = New-Object System.Drawing.Size(10,210)
$TextBox_ConfPass.Size = New-Object System.Drawing.Size(260,20)
$TextBox_ConfPass.UseSystemPasswordChar = $True
$Form_Cred.Controls.Add($TextBox_ConfPass)


<#Create the 'Create' button that will start the Credential
creation process, and add it to the GUI Window.#>
$Button_Create = New-Object System.Windows.Forms.Button
$Button_Create.Location = New-Object System.Drawing.Size(50,250)
$Button_Create.Size = New-Object System.Drawing.Size(75,23)
$Button_Create.Text = "Create"
$Button_Create.Add_Click({
  <#Verify that all requirements have been met before attmpting to create a Credential file#>
  If ($DropBox_CredType.SelectedItem -ne 'Exclusive' -and $DropBox_CredType.SelectedItem -ne 'Shared') {
    [System.Windows.MessageBox]::Show("Please select the type of Credential file you want to create.","Missing Credential Type",'OK','Error')
    $DropBox_CredType.Focus()
  }
  ElseIf ($TextBox_Username.Text -eq $Null -or $TextBox_Username.Text -eq '') {
    [System.Windows.MessageBox]::Show("There was no Username entered into the Username field.","Missing Username",'OK','Error')
    $TextBox_Username.Focus()
  }
  ElseIf ($TextBox_Password.Text -eq $Null -or $TextBox_Password.Text -eq '') {
    [System.Windows.MessageBox]::Show("There was no Password entered into the Password field.","Missing Password",'OK','Error')
    $TextBox_Password.Focus()
  }
  ElseIf ($TextBox_ConfPass.Text -eq $Null -or $TextBox_ConfPass.Text -eq '') {
    [System.Windows.MessageBox]::Show("It looks like you forgot to confirm you password.","Confirm Password",'OK','Error')
    $TextBox_ConfPass.Focus()
  }
  ElseIf (!($TextBox_Password.Text -ceq $TextBox_ConfPass.Text)) {
    [System.Windows.MessageBox]::Show("The Passwords did not match.`nPlease try again.","Password Mismatch",'OK','Error')
    $TextBox_Password.Text = ''
    $TextBox_ConfPass.Text = ''
    $TextBox_Password.Focus()
  }
  Else {
    Create-Credential -CredentialType $DropBox_CredType.SelectedItem -Username $TextBox_Username.Text -Password $TextBox_Password.Text -CredentialName $TextBox_CredName.Text
    <#Reset Input boxes for next credential#>
    $TextBox_CredName.Text = ''
    $TextBox_Username.Text = ''
    $TextBox_Password.Text = ''
    $TextBox_ConfPass.Text = ''
    $TextBox_Username.Focus()
  }
})
$Form_Cred.Controls.Add($Button_Create)


<#Create the 'Cancel' button that will exit out of the Credential
Creator window, and add it to the GUI Window.#>
$Button_Cancel = New-Object System.Windows.Forms.Button
$Button_Cancel.Location = New-Object System.Drawing.Size(160,250)
$Button_Cancel.Size = New-Object System.Drawing.Size(75,23)
$Button_Cancel.Text = "Cancel"
$Button_Cancel.Add_Click({$Form_Cred.Close();$Form_Cred.Dispose()})
$Form_Cred.Controls.Add($Button_Cancel)


<#Display the GUI Window now that all of it's components have been created.#>
$Form_Cred.Topmost = $False
$Form_Cred.ShowDialog()
