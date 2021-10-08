#Created 8.17.2020
#Version 1.1 - 3.27.2021 - Added Comments to Code

#This Script requires the Exchange Online PowerShell V2 module.
#You can or install the required module on your system from an elevated PowerShell Prompt with "Install-Module -Name ExchangeOnlineManagement" 

#Connect to Exchange Online
Connect-ExchangeOnline

#Define Temp Files for Reporting
$PreFile = "$($env:USERPROFILE)\AppData\Local\Temp\temp.preupdate"
$PostFile = "$($env:USERPROFILE)\AppData\Local\Temp\temp.postupdate"

#Prompt the User for the group, and user.
$SharedMailboxIdentity = Read-Host -Prompt 'Input Shared Mailbox Name'
$UserToAdd = Read-Host -Prompt 'Input Full Name of User'

#Generate a snapshot of the current membership of the group in a temp file.
Write-Host "Capture Pre-Update Mailbox State"
Get-EXOMailboxPermission -Identity $SharedMailboxIdentity | Out-File -FilePath $PreFile

#Perform the action of adding a user to the Shared Mailbox
Write-Host "Adding User to Shared Mailbox"
Add-MailboxPermission -Identity $SharedMailboxIdentity -user $UserToAdd -AccessRights FullAccess

#Pausing 30 Seconds for Updates to be reflected Online
#Without this pause, the request for current membership, in the next command, will not likely reflect your changes
Write-Host "`n Pausing 30 Seconds for Change to Be reflected Online"
Start-Sleep -Seconds 30

#Generate a snapshot of the current (updated) membership of the group in a temp file
Get-EXOMailboxPermission -Identity $SharedMailboxIdentity | Out-File -FilePath $PostFile

#Compare the Pre/Post membership snapshot to confirm the change was made
Write-Host "Displaying Any Changes Made to the group as part of this process"
$objects = @{
  ReferenceObject = (Get-Content -Path $PreFile)
  DifferenceObject = (Get-Content -Path $PostFile)
}

Compare-Object @objects

#Cleaning up Temp Files
Write-Host "Cleaning Up Temp Files"
Remove-Item -Path $PreFile
Remove-Item -Path $PostFile