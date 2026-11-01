# Installs lg-screens.ps1 in the Windows VM and runs it at every logon (as administrator).
# From an administrator PowerShell in Windows, while Linux serves arch/vm/windows
# (`make arch-vm-serve` prints the exact command):
#   iwr http://192.168.122.1:8765/install-lg-screens.ps1 -UseBasicParsing | iex
$ErrorActionPreference = 'Stop'
$src  = 'http://192.168.122.1:8765/lg-screens.ps1'
$dest = 'C:\ProgramData\Looking Glass (host)\lg-screens.ps1'

Invoke-WebRequest $src -UseBasicParsing -OutFile $dest

# Replaces the earlier fixed "screen 2" task (its DISPLAY number goes stale after a reboot).
foreach ($old in 'Looking Glass screen 2', 'Looking Glass screens') {
  Stop-ScheduledTask -TaskName $old -ErrorAction SilentlyContinue
  Unregister-ScheduledTask -TaskName $old -Confirm:$false -ErrorAction SilentlyContinue
}
# A copy of the script still running from before would fight the new one.
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  Where-Object { $_.CommandLine -match 'lg-screens\.ps1' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Get-CimInstance Win32_Process -Filter "Name='looking-glass-host.exe'" |
  Where-Object { $_.CommandLine -match 'os:shmDevice=\d' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Register-ScheduledTask -TaskName 'Looking Glass screens' `
  -Action (New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dest`"") `
  -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME) `
  -Principal (New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest) `
  -Settings (New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Seconds 0) `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries) | Out-Null
Start-ScheduledTask -TaskName 'Looking Glass screens'
'Looking Glass screens: installed and started.'
