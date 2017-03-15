$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

$model = (Get-WmiObject -Namespace "ROOT\cimv2" -Class "Win32_ComputerSystem" | Select-Object Model).model
$model
$destination = "\\mu56273\c$\models"

Start-Process -FilePath "$dir\HP BIOS Configuration Utility.msi" -ArgumentList "/qn /norestart"

Start-Sleep -Seconds 5

Start-Process -FilePath "${env:ProgramFiles(x86)}\HP\BIOS Configuration Utility\BiosConfigUtility64.exe" -ArgumentList "/Get:`"\\mu56273\c$\models\$model.txt`""