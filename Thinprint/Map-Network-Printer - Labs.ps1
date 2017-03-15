##Globals
#$Printer_CSV = "C:\printers.csv"
$Printer_CSV = $PSScrptRoot + 'Printers.csv'
$LogPath = $env:TMP + '\Map-Network-Printers.txt'
$Printers = @()
$MACaddress = @()
$timer = @()
$MapPrinters = @()
$log = @()
$CurrentPrinters = @()
$Default_Printer_Flag = $false
#Start program code
$timer = [Diagnostics.Stopwatch]::StartNew()

#Enumerate current connected printers
$CurrentPrinters = Get-WmiObject -Class Win32_Printer

#Unmap existing network printers
if ($CurrentPrinters) {
    foreach ($oldprinter in $CurrentPrinters) {
        if ($oldprinter.Name -match "\\") {
               (New-Object -ComObject WScript.Network).
RemovePrinterConnection($oldprinter.Name)
                $log += "Removing existing printer: " + $oldprinter.Name
                $log = $log | Out-String
               } else {}
        }
} else {}

#Load the CSV List
if (!$(Test-Path $Printer_CSV)) {
    #Do nothing - file not found
        $log += "File: " + $Printer_CSV + " was not found on the file system"
        $log = $log | Out-String
} else {
        $Printers += Import-Csv $Printer_CSV
}

#Determine the VDI Volatile Variables connecting endpoint MACaddress
#$MACaddress = Get-ItemProperty 'hkcu:\volatile environment'
#$MACaddress = $MACaddress.ViewClient_MAC_Address

## GET COMPUTER OU NAME ##

$rootDse = New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE") 
$Domain = $rootDse.DefaultNamingContext 
$root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$Domain") 

$ComputerName = $env:COMPUTERNAME 

$searcher = New-Object System.DirectoryServices.DirectorySearcher($root) 
$searcher.Filter = "(&(objectClass=computer)(name=$ComputerName))" 
[System.DirectoryServices.SearchResult]$result = $searcher.FindOne() 
if (!$?) 
{ 
    return 
} 
$dn = $result.Properties["distinguishedName"] 
$ouResult = $dn.Substring($ComputerName.Length + 4)
$ou = $ouResult.Split(',')[0].Replace('OU=','')

## END GET COMPUTER OU NAME ##

if ($ou) {
    if ($Printers | Where-Object {$_.OU -match $ou}) {
        $MapPrinters = $Printers | Where-Object {$_.OU -match $ou}
    } else {
        #Do nothing - no policies found
        $log += "No printing policies found for " + $ou
        $log = $log | Out-String
    }
} else {
    $log += "Could not determine machine OU"
    $log = $log | Out-String
}

#if ($Hostname -match ".parknet-ad.pmh.org") {
#$Hostname = $Hostname -replace ".parknet-ad.pmh.org"
#} else {}

#Determine the printers to map based on hostname (if rules exist)
<#
if ($MACaddress) {
    if ($Printers | Where-Object {$_.MACaddress -match $MACaddress}) {
        $MapPrinters = $Printers | Where-Object {$_.MACaddress -match $MACaddress}
    } else {
        #Do nothing - no policies found
        $log += "No printing policies found for " + $MACaddress
        $log = $log | Out-String
    }
} else {
    $log += "Could not determine VDI connecting endpoint MACaddress"
        $log = $log | Out-String
}
#>
#Map the printer(s)
if ($MapPrinters) {
    $Count = 0
    foreach ($Printer in $MapPrinters) {
    (New-Object -ComObject WScript.Network).AddWindowsPrinterConnection($Printer.UNCPath)
	#Add-Printer -ConnectionName $Printer.UNCPath
        $log += "Mapping UNC printer: " + $Printer.UNCPath + " for endpoint '"+ $ou + "'"
        $log = $log | Out-String
        $Count++

#Check if the printer should be set as the default and if so, do it
if ($Printer.Default -eq "Y") {
        $Default_Printer_Flag = $true
        $DefaultPrinterName = $Printer.UNCPath
        $DefaultPrinterName = $DefaultPrinterName -split "\\"
        $DefaultPrinterName = $DefaultPrinterName[3]
        #Set printer as default in the system
        #(Get-WmiObject -Class Win32_Printer | Where-Object {$_.Name -match $MappedPrinterName}).SetDefaultPrinter()
        #$log += "Setting UNC printer: " + $Printer.UNCPath + " as default printer '" + $MappedPrinterName + "' in the system"
        #$log = $log | Out-String
    } else {}
   }

if($Default_Printer_Flag) {
    (Get-WmiObject -Class Win32_Printer | Where-Object {($_.Name -match $DefaultPrinterName)}).SetDefaultPrinter()
        
    $log += "Setting UNC printer: " + $Printer.UNCPath + " as default printer '" + $DefaultPrinterName + "' in the system"
    $log = $log | Out-String
}

if ($Count -gt 0) {
        $log += "Mapped " + $Count + " printer(s) "
        $log = $log | Out-String
    } else {}
} else {
$log += "No policies to map..."
    $log = $log | Out-String
}
#Stop and write out console/log data
$timer.Stop()
$log += "[Script Execution Time(H:M:S): " + $timer.Elapsed.Hours + ":" +
$timer.Elapsed.Minutes + ":" + $timer.Elapsed.Seconds + "]"
$log = $log | Out-String
$log | Set-Content $LogPath -force