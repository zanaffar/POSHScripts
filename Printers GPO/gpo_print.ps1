[System.Collections.ArrayList]$printarray = @()
[System.Collections.ArrayList]$parsedGPOPrinterCollection = @()

$printers = Get-Printer -ComputerName "\\wlb-print-03"

foreach($pr in $printers) {
    $printserver = $pr.ComputerName
    $printshare = $pr.ShareName
    $printername = "\\" + "$printserver" + "\" + "$printshare"
    $printarray.Add($printername) | Out-Null
}

$printGPOCol = Get-GPO -All | Where-Object {$_.DisplayName -like "*Printer*"}

foreach($printGPO in $printGPOCol) {

[System.Collections.ArrayList]$GPOprinter_list = @()

$printGPO_name = $printGPO.DisplayName
[xml]$printGPO_xml = Get-GPOReport -Name "$printGPO_name" -ReportType xml -Verbose

## Get list of printers from policy
#$regex = [regex] '(?is)(?<=\\WLB-PRINT-03)(.*?)(?=")'
#$strStart = '\\wlb-print-03\'
#$strEnd = '"'

#$a = Get-Content -Path "$PSScriptRoot\a.xml"
#$a

foreach($printer_string in $printGPO_xml.gpo.User.ExtensionData.Extension.Printers.SharedPrinter.properties.path) {

    if($printer_string -like "*\\WLB-PRINT-03\*") {
        $GPOPrinter_obj = New-Object -TypeName psobject -Property @{
            GPO_Name = $printGPO_xml.gpo.name
            Printer = $printer_string
        }

        $GPOprinter_list.add($GPOPrinter_obj) | Out-Null
        
    }
}


foreach($gpo_printer in $GPOprinter_list.printer) {
    if($printarray -contains $gpo_printer) {
        Write-Host "All good! " $gpo_printer " in " $printGPO_xml.GPO.Name " exists."
        $printer_good = New-Object -TypeName psobject -Property @{
            GPO_Name = $printGPO_xml.gpo.Name
            Printer = $gpo_printer
            Status = "Good"
        }
        $parsedGPOPrinterCollection.Add($printer_good) | Out-Null
    } else {
        Write-Host $gpo_printer " in " $printGPO_xml.GPO.Name " does not exist on the print server!"
        $printer_bad = New-Object -TypeName psobject -Property @{
            GPO_Name = $printGPO_xml.gpo.Name
            Printer = $gpo_printer
            Status = "Bad"
        }
        $parsedGPOPrinterCollection.Add($printer_bad) | Out-Null
    }
}

}
$parsedGPOPrinterCollection | Out-GridView -Wait