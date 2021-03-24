<#Variable to import the Credential files and key#>
$ExcCredFile = "PLACE FULL PATH TO EXCLUSIVE CREDENTIAL FILE HERE" #EXAMPLE: "C:\Users\User\Desktop\ExclusiveCredential_MyPersonalCredentials.xml"
$SharedCredFile = "PLACE FULL PATH TO SHARED CREDENTIAL FILE HERE" #EXAMPLE: "C:\Users\User\Desktop\SharedCredential_MySharedCredentials.xml"
$KeyFile = "PLACE FULL PATH TO SHARED CREDENTIAL DECRYPTION KEY FILE HERE" #EXAMPLE: "C:\Users\User\Desktop\SharedCredential_MySharedCredentials.key"



<#Imports the Exclusive Credential#>
$ExcCred = Import-CliXml -Path $ExcCredFile

<#Imports the information stored in the Shared Credential Decryption Key file#>
$Key = Get-Content $KeyFile

<#Imports the information stored in the Shared Credential file#>
$ImportSharedCred = Import-CliXml -Path $SharedCredFile

<#Decrypts the password from the imported Shared Credential file using that files decryption Key#>
$SharedCredPass = ConvertTo-SecureString -String $ImportSharedCred.Password -Key $Key

<#Creates a local PSCredential file stored in the form of a variabel so that the information from the Shared Credential can actually be used#>
$SharedCred = New-Object System.Management.Automation.PSCredential($ImportSharedCred.UserName, $SharedCredPass)



<#Clears the above text from the CLI screen and displays the information that Credential files are storing as proof of functionality#>
Clear-Host
Write-Host 'Exclusive Username : '$ExcCred.UserName
Write-Host 'Exclusive SecPass  : '$ExcCred.Password
Write-Host 'Exclusive PlainPass: '$ExcCred.GetNetworkCredential().Password
Write-Host "`n`n"
Write-Host 'Shared Username : '$SharedCred.UserName
Write-Host 'Shared SecPass  : '$SharedCred.Password
Write-Host 'Shared PlainPass: '$SharedCred.GetNetworkCredential().Password
