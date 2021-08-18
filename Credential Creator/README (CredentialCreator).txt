!!!IMPORTANT!!!
DPAPI is a feature that is exclusive to Windows Operation Systems. If this script is executed on a non-Windows machine using a cross-platform PowerShell version, 
then the password for the Exclusive Credential file will be stored as plain text. For this reason, it his strongly recommended that you instead use the Shared 
Credential option to create Credential files on non-Windows machines.


SUMMARY:
Exclusive Credential files can only be used on the computer and account that the user was logged into when they were created, while Shared Credential files can be 
used by any account on any computer if you have the Shared Credential files Decryption key. You can use Credential Reader.ps1 to verify that the Credentials 
have the desired information as well as to see how to import each Credential type and which commands are used to extract the username and password from each Credential
type.



DETAILED:
Exclusive Credentials are created in almost the exact same way that that PSCredentials are created, except that the information is exported into an .xml file so that it 
can be used in several scripts. Being as the creation process is nearly identical to the native PowerShell function 'Get-Credential' the Username is stored as plain 
text, while the Password is encrypted using the Windows Data Protection API (DPAPI). DPAPI uses a symmetric encryption/decryption key that is created using system 
information that is exclusive to the machine and account that the user is logged into. This means that just like a standard PSCredential, an Exclusive Credential file 
can only be used on the computer account that it was originally created on.

To further illustrate this example, let's say there is a user named Bob, who has a computer called DESKTOP. If Bob logs into DESKTOP using his account which is named
BOBSACCOUNT, and he creates an Exclusive file. Then he can only use that file while logged into DESKTOP under BOBSACCOUNT. Even if bob deletes BOBSACCOUNT from DESKTOP, 
then creates a new account name BOBSACCOUNT, the Exclusive credential will not work because the underlying system information for the new BOBSACCOUNT is not the same as 
the old BOBSACCOUNT.


Shared Credentials are created by making a custom object and injecting it into an .xml file. The Username is stored as plain text, but the password is encrypted/decrypted 
by randomly generated AES key that is exclusive to the Shared Credential file. By importing the information stored in the Shared Credential file, and importing the 
information stored in the key to decrypt the password, a local PSCredential object can be created for use with the script. Alternatively, the information can be pulled 
directly from the Shared Credential file and decrypted on the fly using the key if you do not wish to create a local PSCredential object.

It is up to you how you store the key. Without it, the password stored in the Shared Credential cannot be accessed, but anyone who has access to the key can easily 
decrypt the Shared Credential that it goes to.



ADDITIONAL OPTIONS:
When creating credentials, there are two optional checkboxes that you can take advantage of.

"Retain Encryption Key for additional Credential Creations"
  When checked, this option allows the Credential Creator to remember the randomly generated encryption key that gets created with the credential you are creating.
  The Credential Creator then uses the same encryption key for each successive credential creation until you uncheck the box or close the credential creator.


"Use an existing Encryption Key for Credential Creations"
  When checked, this option allows the Credential Creator to use a previously generated encryption key that you choose for the credential you are creating.
  The Credential Creator then uses the same encryption key for each successive credential creation until you uncheck the box or close the credential creator.
