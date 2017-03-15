## Get MSI Version Information ##
	
$FilePath = (Get-ChildItem -Path "$PSScriptRoot\Files\" | Where-Object {$_.Name -like '*.msp'}).FullName
[IO.FileInfo]$Path = $FilePath
$Property = 'DisplayName'
$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($Path.FullName, 32))
$Query = "SELECT Value FROM MsiPatchMetadata WHERE Property = '$($Property)'"
$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
$Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)

# Commit database and close view
$MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
$View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)           
$MSIDatabase = $null
$View = $null

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null

$Value = $Value.Split('()')[1]