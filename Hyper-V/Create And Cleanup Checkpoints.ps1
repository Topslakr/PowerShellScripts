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
$filterDate = (Get-Date).AddDays(-3)

#Now we do the work
Foreach($VM in $VMs){
$CurrentVM = $vm.Name.ToString()

#Print which VM is being investigated
Write-Host "Processing $CurrentVM"

#Remove any stale checkpoints, ignoring the two most recent checkpoints
get-vm -Name $CurrentVM | Get-VMSnapshot | Select -skiplast 2 | Where-Object {$_.CreationTime -LE $filterDate} | Remove-VMSnapshot
#Give the server a few moments to crunch the numnbers.
Sleep 5

#Set the type of checkpoint to take. (Standard,Production, or ProductionOnly)
Set-VM -Name $CurrentVM -CheckpointType Production

#Take the snapshot.
Get-VM -Name $CurrentVM | Checkpoint-VM -SnapshotName $SnapName
#A few more moments to crunch those numbers.
Sleep 5
}