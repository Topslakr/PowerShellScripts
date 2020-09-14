#Created 8.17.2020

Connect-ExchangeOnline
clear

#Define Temp Files for Reporting
$PreFile = "$($env:USERPROFILE)\AppData\Local\Temp\temp.preupdate"
$PostFile = "$($env:USERPROFILE)\AppData\Local\Temp\temp.postupdate"


$SharedMailboxIdentity = Read-Host -Prompt 'Input Shared Mailbox Name'
$UserToAdd = Read-Host -Prompt 'Input Full Name of User'

Write-Host "Capture Pre-Update Mailbox State"
Get-EXOMailboxPermission -Identity $SharedMailboxIdentity | Out-File -FilePath $PreFile

Write-Host "Adding User to Shared Mailbox"
Add-MailboxPermission -Identity $SharedMailboxIdentity -user $UserToAdd -AccessRights FullAccess

#Pausing 30 Seconds for Updates to be reflected Online
Write-Host "`n Pausing 30 Seconds for Change to Be reflected Online"
Start-Sleep -Seconds 30

Get-EXOMailboxPermission -Identity $SharedMailboxIdentity | Out-File -FilePath $PostFile

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