$Modules = Get-Module
if (!($Modules.name -like "*ConfigurationManager*")) {
    Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
}

$location = Get-Location
if ($location.Path -ne "MU1:\") {
    Set-Location MU1:
}

$NewLimitingCollectionName = 'All MU Workstations excl VMView VMs'
$NewLimitingCollectionID = 'MU10000B'

$collections = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\sms\site_MU1 -Query "SELECT * FROM SMS_Collection WHERE SMS_Collection.LimitToCollectionName like '%Windows 7%'"
foreach($collection in $collections){
    $props = $collection.LimitToCollectionID
    $props = $NewLimitingCollectionID
    $collection.LimitToCollectionID = $props
    Set-CimInstance -InputObject $collection -PassThru -Verbose
}