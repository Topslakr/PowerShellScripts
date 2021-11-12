#RW - 9.29.2021
#Run this script on a Hyper-V Host to checkpoint each VM. The script will also purge any snapshots older than X number of days.
#The process that purges old checkpoints will ignore the two most recent checkpoints to prevent the system from purging all checkpoints even if the checkpoint creation fails.
#The script should be run via a scheduled task, or other automation triggering platform.

#Create Variable of Available VMs
#If needed, you can use this to exclude VMs you don't want to check point.
#By Default, this will simply capture all VMs, running or not.
$VMs = Get-VM

#Create Variable to Name the CheckPoints
#Get Date, and put in proper format
$TimeStamp = Get-Date -Format "MM/dd/yyyy HH:mm"
$SnapName = "Recovery Checkpoint $TimeStamp"

#Set the age of Snapshots to keep.
#Because  the checkpoints are deleted before new ones are made, this number should be one LOWER than you'd like to keep.
#Using -3 will actually keep 4 checkpoints.
$filterDate = (Get-Date).AddDays(-6)

#Now we do the work
Foreach($VM in $VMs){
$CurrentVM = $vm.Name.ToString()

#Print which VM is being investigated
Write-Host "Processing $CurrentVM"

#List and remove any stale checkpoints, ignoring the two most recent checkpoints
$StaleSnaps = get-vm -Name $CurrentVM | Get-VMSnapshot | Select -skiplast 2 | Where-Object {$_.CreationTime -LE $filterDate} 
Write-Host = "Checkpoints to be Deleted:"
Write-Host = "$StaleSnaps"
get-vm -Name $CurrentVM | Get-VMSnapshot | Select -skiplast 2 | Where-Object {$_.CreationTime -LE $filterDate} | Remove-VMSnapshot
#Give the server a few moments to crunch the numnbers.
Sleep 5

#Set the type of checkpoint to take. (Standard,Production, or ProductionOnly)
Set-VM -Name $CurrentVM -CheckpointType Production

#Take the snapshot.
Write-Host "Creating $SnapName for $CurrentVM"
Get-VM -Name $CurrentVM | Checkpoint-VM -SnapshotName $SnapName
#A few more moments to crunch those numbers.
Sleep 5
}

#Report on Disk Space Used by Checkpoint Diff Disks
#Find Locations of VM Disks
$VMDisk = Get-VMHardDiskDrive -VMName * | Select-Object -Last 1 | Select Path | Split-Path
#Calculate Disk space used, in Gb
$SpaceUsed = [Math]::Round(((Get-ChildItem -Path $VMDisk | Where Name -CLike "*avhdx" | Measure-Object -Property Length -Sum).Sum / 1Gb))
#Report Space Used in Log
Write-Host "Disk Space Used by Checkpoint Data"
Write-Host "$SpaceUsed Gb"
