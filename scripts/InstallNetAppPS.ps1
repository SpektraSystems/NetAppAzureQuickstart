New-Item C:\NetApp -Type Directory
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://raw.githubusercontent.com/SpektraSystems/NetAppAzureQuickstart/master/scripts/NetApp_PowerShell_Toolkit_4.3.0.msi","C:\NetApp\NetApp_PowerShell_Toolkit_4.3.0.msi")
# Start-Process msiexec.exe -Wait -ArgumentList '/I C:\NetApp\NetApp_PowerShell_Toolkit_4.3.0.msi /quiet'
Invoke-Command -ScriptBlock { & cmd /c "msiexec.exe /i C:\NetApp\NetApp_PowerShell_Toolkit_4.3.0.msi" /qn ADDLOCAL=F.PSTKDOT}
