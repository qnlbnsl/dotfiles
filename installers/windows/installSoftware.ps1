# well-known SID for admin group
if ('S-1-5-32-544' -notin [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups) {
    throw 'Script must run as admin!'
}


$localPath = Split-Path $MyInvocation.MyCommand.Path
Set-Location $localPath
Write-Host "current working directory is $localPath"

Write-Host "Installing Asus Dark Hero Drivers"
$confirmation = Read-Host "Are you Sure You Want To Proceed:"
if ($confirmation -eq 'y') {
    Start-Process '.\Drivers\wifi\Install.bat' -Wait -NoNewWindow
    Start-Process '.\Drivers\audio\Install.bat' -Wait -NoNewWindow
    Start-Process '.\Drivers\bluetooth\Install.bat' -Wait -NoNewWindow
    Start-Process '.\Drivers\chipset\silentinstall.cmd'-Wait -NoNewWindow
    Start-Process '.\Drivers\lan\Silent_Install.bat' -Wait -NoNewWindow
}

Write-Host "Installing Fonts"

$fontsFolder = 'Fonts'

foreach ($font in Get-ChildItem -Path $fontsFolder -File) {
    $dest = "C:\Windows\Fonts\$font"
    if (Test-Path -Path $dest) {
        "Font $font already installed."
    }
    else {
        $font | Copy-Item -Destination $dest
    }
}

Write-Host "Installing chocolatey"
(new-object net.webclient).DownloadFile('https://chocolatey.org/install.ps1', 'C:\Windows\Temp\install.ps1')

$env:chocolateyUseWindowsCompression = 'false'
for ($try = 0; $try -lt 5; $try++) {
  & C:/Windows/Temp/install.ps1
  if ($?) { 
    Write-Host "Chocolatey Installed" 
    break
  }
  if (Test-Path C:\ProgramData\chocolatey) {
    Write-Host "Chocolatey Installed" 
    break
  }
  Write-Host "Failed to install chocolatey (Try #${try})"
  Start-Sleep 2
}
# disables prompts from choco
choco feature enable -n=allowGlobalConfirmation 
$packages = @(
    "aida64-extreme",
    "brave",
    "deskscapes",
    "directx",
    "disable-nvidia-telemetry",
    "discord",
    "dotnet-sdk",
    "evga-precision-x1",
    "Flow-Launcher",`
    "git",
    "git-credential-manager-for-windows",
    "golang",
    "nvidia-broadcast",
    "nvidia-display-driver",
    "nvidia-geforce-now",
    "nvidia-profile-inspector",
    "nomachine",
    "obs-studio.install",
    "obsidian",
    "object-desktop",
    "office365business",
    "powershell-core",
    "powershellhere-elevated",
    "powertoys",
    "roccatswarm", 
    "sidequest", 
    "spotify", 
    "stardock-fences", 
    "steam-client", 
    "streamdeck", 
    "tailscale", 
    "telegram", 
    "terraform", 
    "unity-hub", 
    "vcredist-all", 
    "vscode", 
    "zotero"
    )

Write-Host "Installing packages from choco"
try {
   choco install $packages
 } catch {
     Write-Host "$installers[$i] returned the following error $_"
     # If you want to pass the error upwards as a system error and abort your powershell script or function
     Throw "Aborted mypatch.exe returned $_"
 }


Write-Host "Package Install Completed"



Write-Host " we will be installing the following custom exe applications"
Get-ChildItem -Filter *exe

$confirmation = Read-Host "Are you Sure You Want To Proceed: (y/n)"
if ($confirmation -eq 'y') {
   # Reads all exe's from the script root and executes them sequentially
Write-Host "Installing exe's at script location"
$installers = Get-ChildItem -File -Filter *.exe
for($i=0; $i -lt $installers.Count; $i++){
    $app = $installers[$i]
    try {
        
        Write-Host "installing $app"
        $confirmation = Read-Host "Are you Sure You Want To Proceed:"
        if ($confirmation -eq 'y'){
            Start-Process $app -Wait -ArgumentList "/S /silent /quiet"
        }
        
    } catch {

        Write-Host "$app returned the following error $_"
        # If you want to pass the error upwards as a system error and abort your powershell script or function
        Throw "Aborted $installers[$i] returned $_"
    }
}

}

