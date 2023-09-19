Add-Type -AssemblyName System.Windows.Forms

# Define the packages and descriptions
$packages = @{
    'Drivers' = 'Asus DarkHero Drivers'
    'nvm'     = 'Node Version Manager'
    'docker'  = 'Docker Container Engine'
}

# Submenu for motherboard drivers
$motherboardDrivers = @{
    'AsusDarkHero'      = 'Asus DarkHero'
    'GigabyteAorus'     = 'Gigabyte Aorus Xtreme'
    'MSIMegGodlike'     = 'MSI Meg Godlike'
}

# Function to show submenu for motherboard drivers
function ShowDriverSubMenu {
    $formDriver = New-Object System.Windows.Forms.Form
    $formDriver.Text = 'Select Motherboard Driver'
    $formDriver.Size = New-Object System.Drawing.Size(300, 300)

    $listBoxDriver = New-Object System.Windows.Forms.ListBox
    $listBoxDriver.Location = New-Object System.Drawing.Point(10, 10)
    $listBoxDriver.Size = New-Object System.Drawing.Size(260, 200)

    $motherboardDrivers.GetEnumerator() | ForEach-Object {
        $listBoxDriver.Items.Add($_.Value) | Out-Null
    }

    $buttonDriver = New-Object System.Windows.Forms.Button
    $buttonDriver.Location = New-Object System.Drawing.Point(10, 220)
    $buttonDriver.Size = New-Object System.Drawing.Size(260, 30)
    $buttonDriver.Text = 'Install'
    $buttonDriver.Add_Click({
        $formDriver.Close()
    })

    $formDriver.Controls.Add($listBoxDriver)
    $formDriver.Controls.Add($buttonDriver)
    $formDriver.ShowDialog() | Out-Null

    $listBoxDriver.SelectedItem
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select Packages to Install'
$form.Size = New-Object System.Drawing.Size(300, 300)

# Create and configure the ListBox
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 10)
$listBox.Size = New-Object System.Drawing.Size(260, 200)
$listBox.SelectionMode = 'MultiExtended'

$packages.GetEnumerator() | ForEach-Object {
    $listBox.Items.Add($_.Value) | Out-Null
}

$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10, 220)
$button.Size = New-Object System.Drawing.Size(260, 30)
$button.Text = 'Install'
$button.Add_Click({
    $form.Close()
})

$form.Controls.Add($listBox)
$form.Controls.Add($button)

$form.ShowDialog() | Out-Null

foreach ($item in $listBox.SelectedItems) {
    $key = $packages.GetEnumerator() | Where-Object { $_.Value -eq $item } | Select-Object -ExpandProperty Key
    if ($key -eq "Drivers") {
        $driver = ShowDriverSubMenu
        Write-Host "Installing driver for motherboard: $driver..."
    } else {
        Write-Host "Installing $key..."
    }
    # Replace the Write-Host command with your actual installation logic.
}
