# Looking Glass: one capture app per Windows screen, left to right (runs at logon, see
# install-lg-screens.ps1). Screen 1 is the Looking Glass service (it also shows the sign-in
# screen) on shared memory 0; screen N is an extra capture app on shared memory N-1, which
# Linux shows on workspace 1 / 11 / 21. Windows renumbers the virtual displays between boots
# (\\.\DISPLAY7 one day, \\.\DISPLAY5 the next), so they're looked up by position and checked
# every few seconds; a capture app that exits is started again.
#
# Mouse jumping: a Looking Glass window only sees the Windows cursor while it's on its own
# screen. When the mouse moves onto another screen's window, Linux sends "<screen> <x> <y>"
# (x, y as 0-1 fractions) over the host-to-VM network (windows-cursor-bridge, port 8766) and
# the cursor is put there right away.

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class LgCursor {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr value);
}
'@
# Real pixel coordinates even with display scaling (per-monitor DPI aware v2).
[LgCursor]::SetProcessDpiAwarenessContext([IntPtr]-4) | Out-Null
Add-Type -AssemblyName System.Windows.Forms

$dir    = 'C:\Program Files\Looking Glass (host)'
$exe    = Join-Path $dir 'looking-glass-host.exe'
$ini    = Join-Path $dir 'looking-glass-host.ini'
$logDir = 'C:\ProgramData\Looking Glass (host)'
$maxScreens = 3   # shared-memory devices in arch/vm/win11.xml
$bridgeHost, $bridgePort = '192.168.122.1', 8766

function Get-Screens {
  # Map by position: left to right, then top to bottom (same order Linux uses for monitors).
  @([System.Windows.Forms.Screen]::AllScreens | Sort-Object { $_.Bounds.X }, { $_.Bounds.Y })
}

function Update-CaptureApps($screens) {
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
}

function Move-CursorTo($screens, $line) {
  $parts = $line.Trim() -split '\s+'
  if ($parts.Count -ne 3) { return }
  $n = [int]$parts[0]
  if ($n -lt 1 -or $n -gt $screens.Count) { return }
  $inv = [Globalization.CultureInfo]::InvariantCulture
  $b = $screens[$n - 1].Bounds
  $x = $b.X + [int]([double]::Parse($parts[1], $inv) * ($b.Width - 1))
  $y = $b.Y + [int]([double]::Parse($parts[2], $inv) * ($b.Height - 1))
  [LgCursor]::SetCursorPos($x, $y) | Out-Null
}

$tcp = $null; $stream = $null; $pending = ''
$buf = New-Object byte[] 4096
$nextManage = [datetime]::MinValue; $nextConnect = [datetime]::MinValue
while ($true) {
  $now = Get-Date
  if ($now -ge $nextManage) {
    $screens = Get-Screens
    try { Update-CaptureApps $screens } catch { }
    $nextManage = $now.AddSeconds(5)
  }

  # (Re)connect to the Linux bridge; it isn't there when Linux's session isn't running.
  if (-not $tcp -and $now -ge $nextConnect) {
    $nextConnect = $now.AddSeconds(3)
    try {
      $c = New-Object System.Net.Sockets.TcpClient
      if ($c.ConnectAsync($bridgeHost, $bridgePort).Wait(500) -and $c.Connected) {
        $c.NoDelay = $true
        $tcp = $c; $stream = $c.GetStream(); $pending = ''
      } else { $c.Close() }
    } catch { }
  }

  if ($tcp) {
    try {
      # Readable with nothing to read = Linux closed the connection.
      if ($tcp.Client.Poll(0, [System.Net.Sockets.SelectMode]::SelectRead) -and $tcp.Available -eq 0) {
        throw 'closed'
      }
      if ($tcp.Available -gt 0) {
        $r = $stream.Read($buf, 0, [Math]::Min($tcp.Available, $buf.Length))
        $lines = ($pending + [Text.Encoding]::ASCII.GetString($buf, 0, $r)) -split "`n"
        $pending = $lines[-1]                     # partial line, if any
        $done = @($lines | Select-Object -SkipLast 1 | Where-Object { $_ })
        if ($done.Count) { Move-CursorTo $screens $done[-1] }   # only the newest position matters
      }
    } catch {
      $tcp.Close(); $tcp = $null; $stream = $null
    }
  }
  Start-Sleep -Milliseconds 10
}
