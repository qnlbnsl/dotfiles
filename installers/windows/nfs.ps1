$parameters = @{
    Name = "Installer"
    PSProvider = "FileSystem"
    Root = "\\192.168.1.7\Installers"
    Description = "Installers Drive for Installers"
}
New-PSDrive @parameters