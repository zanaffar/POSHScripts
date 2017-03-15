$printer = Get-WmiObject -Class Win32_Printer
Write-Host 'Start ' $printer

$printerDriver = Get-WmiObject -Class Win32_PrinterDriver
Write-Host 'Start ' $printerDriver

$printer = $printer | Where-Object {$_.Name -like '*UGAdmissions_1*'}
$printer.delete()

$printer = Get-WmiObject -Class Win32_Printer
Write-Host 'End ' $printer
#$printer.delete()


#Stop-Service -Name Spooler -Force


#Remove-Printer 
#Invoke-Command -ComputerName MU53597 -ScriptBlock {Start-Service -Name Spooler}
#Get-PrinterDriver -ComputerName MU53597