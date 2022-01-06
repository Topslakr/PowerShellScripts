#RW - 9.29.2021
#RW - 12.8.2021 - Updating script to dynamically keep more or less snaps based on free space
#RW - 01.06.2020 - Take Less Risk. Don't snap on less than 250GB of freespace, and remove any current snaps.
#Run this script on a Hyper-V Host to checkpoint each VM. The script will also purge any snapshots beyond limits set based on disk space.
#The script should be run via a scheduled task, or other automation triggering platform.

#Create Variable of Available VMs
#If needed, you can use this to exclude VMs you don't want to check point.
#By Default, this will simply capture all VMs, running or not.
$VMs = Get-VM

#Create Variable to Name the CheckPoints
#Get Date, and put in proper format
$TimeStamp = Get-Date -Format "MM/dd/yyyy HH:mm"
$SnapName = "Recovery Checkpoint $TimeStamp"

#Find which Drive letter hold the VM Disks
$DiskSource = Get-VMHardDiskDrive -VMName * | Select-Object -Last 1 | Select Path
$DiskLetter = $DiskSource.Path[0]

#Find out how many bytes of free space are available on VM Disk
$Free = Get-Volume $DiskLetter | Select SizeRemaining | Format-Table -HideTableHeaders | Out-String
$Spacefree = [Math]::Round((Measure-Object -InputObject $Free -Sum).Sum / 1GB)

Write-Host "Space Free: " $Spacefree "GB"

#Calcualte how many Snaps to keep, based on Free Space
If ( $SpaceFree -ge 500 )
{
    Write-Output "More than 500GiB Free"
    Write-Output "Keeping 8 Days of Snaps"
    $SnapCount = 7
}
elseif ($Spacefree -gt 250 )
{
    Write-Output "More than 250GiB Free"
    Write-Output "Keeping 5 Days of Snaps"
    $SnapCount = 4
}
else
{
    Write-Output "Less than 250GB Free"
    Write-Output "Create No Checkpoints. Delete All Checkpoints and exit"
    Foreach($VM in $VMs){
        $CurrentVM = $vm.Name.ToString()
        Write-Host "Cleaning Up $CurrentVM"
        get-vm -Name $CurrentVM | Get-VMSnapshot | Remove-VMSnapshot
        sleep 15
        }
    Exit
}

#Now we do the work
Foreach($VM in $VMs){
$CurrentVM = $vm.Name.ToString()

#Print which VM is being investigated
Write-Host "Processing $CurrentVM"

#List and remove any stale checkpoints, ignoring the two most recent checkpoints
$StaleSnaps = get-vm -Name $CurrentVM | Get-VMSnapshot | Select -skiplast $SnapCount
Write-Host = "Checkpoints to be Deleted:"
Write-Host = "$StaleSnaps"
get-vm -Name $CurrentVM | Get-VMSnapshot | Select -skiplast $SnapCount | Remove-VMSnapshot
#Give the server a few moments to crunch the numnbers.
Sleep 15

#Set the type of checkpoint to take. (Standard,Production, or ProductionOnly)
Set-VM -Name $CurrentVM -CheckpointType Production

#Take the snapshot.
Write-Host "Creating $SnapName for $CurrentVM"
Get-VM -Name $CurrentVM | Checkpoint-VM -SnapshotName $SnapName
#A few more moments to crunch those numbers.
Sleep 10
}

#Report on Disk Space Used by Checkpoint Diff Disks
#Find Locations of VM Disks
$VMDisk = Get-VMHardDiskDrive -VMName * | Select-Object -Last 1 | Select Path | Split-Path
#Calculate Disk space used, in Gb
$SpaceUsed = [Math]::Round(((Get-ChildItem -Path $VMDisk | Where Name -CLike "*avhdx" | Measure-Object -Property Length -Sum).Sum / 1Gb))
#Report Space Used in Log
Write-Host "Disk Space Used by Checkpoint Data"
Write-Host "$SpaceUsed Gb"
