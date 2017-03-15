$HP_driver = @()

## Delete all HP printer drivers ##
Stop-Service -Name Spooler -Force
Start-Service -Name Spooler
Get-PrinterDriver | Where-Object {$_.Name -like 'HP*'} | Remove-PrinterDriver

## Enumerate HP Printer Drivers in the Driver Store ##

$drivers = pnputil -e

for($i = 0; $i -lt $drivers.Count; $i++) {
    if(($drivers[$i] -like '*Printers*') -and ($drivers[$i-1] -like '*HP*')){
        $HP_driver += $drivers[$i-2].Split(':').trim()[1]
        $drivers[$i-1]
        $drivers[$i]
        Write-Output ''
    }
}

## Enumerate all printer drivers ##

[System.Collections.ArrayList]$prndrvr_col = @()
$prndrvr = cscript.exe 'C:\Windows\System32\Printing_Admin_Scripts\en-US\prndrvr.vbs' '-l'
#$key = 0
$start = 0
for($i = 0; $i -lt $prndrvr.Count; $i++) {
    if($prndrvr[$i] -eq ''){
        $hashProp = [ordered]@{
            #Content = $prndrvr[$start..$i]
            Driver = $prndrvr[$start+1].Split(',')[0].Replace('Driver name ','')
            Version = $prndrvr[$start+1].Split(',')[1]
            Envrionment = $prndrvr[$start+1].Split(',')[2]
        }
        $printObj = New-Object -TypeName psobject -Property $hashProp
        #$prndrvr_col += $prndrvr[$start..$i]
    $prndrvr_col += $printObj
    $start = $i+1
    }
}



