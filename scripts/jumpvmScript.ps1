[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$userName
)
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

#$DesktopPath = [Environment]::GetFolderPath("Desktop") 
New-Item C:\Users\$userName\Desktop\sql-vm.rdp  -ItemType file
$a="full address:s:10.0.2.4:3389
prompt for credentials:i:1
administrative session:i:1"

Add-Content C:\Users\$userName\Desktop\sql-vm.rdp  $a
