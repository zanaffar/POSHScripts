$Modules = Get-Module
if (!($Modules.name -like "*ConfigurationManager*")) {
    Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
}

$location = Get-Location
if ($location.Path -ne "MU1:\") {
    Set-Location MU1:
}

$apps = Get-CMApplication | Where-Object {($_.isExpired -eq $False)}
$apps = $apps | Where-Object {($_.isExpired -eq $False)}
[System.Collections.ArrayList]$appsDeployTypeList = @()

foreach ($app in $apps) {

    $depTypeNum = $app.NumberOfDeploymentTypes

    $apps_obj = New-Object -TypeName PSObject -Property @{
        AppName = $app.localizeddisplayname
        DeploymentType = (Get-CMDeploymentType -ApplicationName $app.localizeddisplayname).localizeddisplayname
        DateLastModified = (Get-CMDeploymentType -ApplicationName $app.localizeddisplayname).datelastmodified
    }
    $appsDeployTypeList.add($apps_obj) | Out-Null
    $apps_obj
}

$appsDeployTypeList | Where-Object {$_.DateLastModified -ge (Get-Date).AddDays(-7)} | Out-GridView