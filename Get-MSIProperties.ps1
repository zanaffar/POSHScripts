[System.IO.FileInfo]$Path = "$PSScriptRoot\Files\$((Get-ChildItem -Path "$PSScriptRoot\Files" -Filter '*.msi').Name)"
$Property = 'ProductVersion'
## "ProductCode", "ProductVersion", "ProductName", "Manufacturer", "ProductLanguage", "FullVersion" ##

# Read property from MSI database
$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($Path.FullName, 0))
$Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
$Version = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
 
# Commit database and close view
$MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
$View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)           
$MSIDatabase = $null
$View = $null

$Version