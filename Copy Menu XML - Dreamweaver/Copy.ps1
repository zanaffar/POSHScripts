$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

$computers = Get-Content -Path "$dir\hh212.txt"
foreach ($computer in $computers) {
    $destination = "\\$computer\c$\Program Files\Adobe\Adobe Dreamweaver CC 2015\configuration\Menus\"
    Copy-Item -Path "$dir\menus.xml" -Destination $destination -Force
    }