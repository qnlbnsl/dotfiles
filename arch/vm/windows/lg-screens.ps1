# Looking Glass: one capture app per Windows screen, left to right (runs at logon, see
# install-lg-screens.ps1). Screen 1 is the Looking Glass service (it also shows the sign-in
# screen) on shared memory 0; screen N is an extra capture app on shared memory N-1, which
# Linux shows on workspace 1 / 11 / 21. Windows renumbers the virtual displays between boots
# (\\.\DISPLAY7 one day, \\.\DISPLAY5 the next), so they're looked up by position and checked
# every few seconds; a capture app that exits is started again.

Add-Type -AssemblyName System.Windows.Forms
$dir    = 'C:\Program Files\Looking Glass (host)'
$exe    = Join-Path $dir 'looking-glass-host.exe'
$ini    = Join-Path $dir 'looking-glass-host.ini'
$logDir = 'C:\ProgramData\Looking Glass (host)'
$maxScreens = 3   # shared-memory devices in arch/vm/win11.xml

while ($true) {
  # Map by position: left to right, then top to bottom (same order Linux uses for monitors).
  $screens = @([System.Windows.Forms.Screen]::AllScreens | Sort-Object { $_.Bounds.X }, { $_.Bounds.Y })
  $names = @($screens | ForEach-Object { $_.DeviceName.TrimStart('\', '.') })   # DISPLAY5, ...

  # Screen 1: pin the service to the leftmost screen; restart it only when that changes.
  # Both capture methods get the screen: D12 (preferred) doesn't null-terminate the name it
  # reads (Looking Glass B7), so its match can fail, and then the app falls back to DXGI.
  $want = "[d12]`r`noutput=$($names[0])`r`n[dxgi]`r`noutput=$($names[0])`r`n"
  $have = if (Test-Path $ini) { Get-Content $ini -Raw } else { '' }
  if ($have -ne $want) {
    Set-Content -Path $ini -Value $want -NoNewline -Encoding ascii
    Get-Service -DisplayName 'Looking Glass*' | Restart-Service -Force
  }

  # Screens 2..N: one extra capture app each.
  $extra = @(Get-CimInstance Win32_Process -Filter "Name='looking-glass-host.exe'" |
             Where-Object { $_.CommandLine -match 'os:shmDevice=\d' })
  for ($i = 1; $i -lt [Math]::Min($names.Count, $maxScreens); $i++) {
    $p = $extra | Where-Object { $_.CommandLine -match "os:shmDevice=$i\b" }
    if ($p -and $p.CommandLine -notmatch "dxgi:output=$($names[$i])\b") {
      $p | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }   # screen renumbered
      $p = $null
    }
    if (-not $p) {
      $log = Join-Path $logDir "looking-glass-host-screen$($i + 1).txt"
      Start-Process $exe -WindowStyle Hidden -ArgumentList @(
        "os:shmDevice=$i", "d12:output=$($names[$i])", "dxgi:output=$($names[$i])", "`"os:logFile=$log`"")
    }
  }
  Start-Sleep -Seconds 5
}
