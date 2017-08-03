Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

start /wait msiexec.exe /i NetApp_PowerShell_Toolkit_4.3.0.msi /qn ADDLOCAL=F.PSTKDOT
