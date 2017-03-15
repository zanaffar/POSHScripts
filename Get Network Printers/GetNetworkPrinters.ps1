[System.Collections.ArrayList]$printerList = @()
[System.Collections.ArrayList]$printers = @()
$computer = "mu52005"

#Enter-PSSession $computer

Get-ChildItem Registry::\HKEY_Users | 
Where-Object { $_.PSChildName -NotMatch ".DEFAULT|S-1-5-18|S-1-5-19|S-1-5-20|_Classes" } | 
Select-Object -ExpandProperty PSChildName | 
ForEach-Object {
$objSID = New-Object System.Security.Principal.SecurityIdentifier ("$_")
$objUser = $objSID.Translate([System.Security.Principal.NTAccount])
#$objUser.Value
#$objSID.Value
$regLocation = "Registry::\HKEY_Users\$_\Printers\Connections"
$printerList = Get-ChildItem $regLocation -Recurse | Select-Object Name
foreach ($printer in $printerList) {
    $printer = ($printer.Name -split "\,,")[1].replace(",","\")
    $printers.add($printer) | Out-Null
}
$netPrintObj = New-Object -TypeName PSObject -Property @{
    Printers = $printers
    SID = $objSID
    User = $objUser
}
$netPrintObj.User
$netPrintObj.Printers
}