$Modules = Get-Module
if (!($Modules.name -like "*ConfigurationManager*")) {
    Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
}

$location = Get-Location
if ($location.Path -ne "MU1:\") {
    Set-Location MU1:
}

$SiteServer = "wlb-sysctr-02"
$Namespace

#Get-CIMInstance -ComputerName $SiteServer -Namespace root\SMS\site_MU1 -Class SMS_Application -Filter "isLatest='true' and isExpired='false'"

# Filter by Deployment Types
$Apps = Get-CIMInstance -ComputerName $SiteServer -Namespace root\SMS\site_MU1 -Class SMS_ContentPackage |
Where-Object {($_.LastRefreshTime -ge (Get-Date).AddDays(-7))} 

$Apps | ForEach-Object {
    $appName = $_.name
    $deployTypes = Get-CMDeploymentType -ApplicationName "$appName"
    $deployTypes | ForEach-Object {
        $deployName = $_.localizeddisplayname
        Update-CMDistributionPoint -ApplicationName "$appName" -DeploymentTypeName "$deployName" -Verbose
    }
}

#$DeployTypes | Out-GridView