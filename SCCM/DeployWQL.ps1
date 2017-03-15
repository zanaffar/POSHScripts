$Modules = Get-Module
if (!($Modules.name -like "*ConfigurationManager*")) {
    Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
}
Set-Location MU1:
$DeployGroupQuery = "SWUG_PreApproved_Install"

$CollectionName = "OSD - Deployments"
$Collection = Get-CMCollection -Name $CollectionName
[System.Collections.ArrayList]$Applications = Get-CMDeployment | Where-Object {($_.CollectionName -ne $CollectionName) -and (($_.CollectionName -eq $DeployGroupQuery) -and ($_.CI_ID -ne $null))}
$index = 0
[System.Collections.ArrayList]$removeArray = @()
foreach ($Application in $Applications) {
    
    $a = Get-CMDeployment -SoftwareName $Application.ApplicationName | Where-Object {$_.CollectionName -eq $CollectionName}
    if($a) {    
        $a = $Applications[$index]
        $removeArray.Add($a) 
        }
    $index++
    }
foreach ($removeApp in $removeArray) {
    $Applications.Remove($removeApp)
    }

Set-Location c:
function AppDeploy($Apps) {
Enter-PSSession -ComputerName wlb-sysctr-02
$SiteCode="MU1"
$SccmServer = "wlb-sysctr-02"
$DeploymentClass = [wmiclass] "\\localhost\root\sms\site_$($SiteCode):SMS_ApplicationAssignment"

foreach ($App in $Apps) {
    
    $Deployment = $DeploymentClass.CreateInstance()
    $Deployment.ApplicationName                 = $App.ApplicationName
    $Deployment.AssignmentName                  = $App.ApplicationName
    $Deployment.AssignedCIs                     = $App.CI_ID
    $Deployment.CollectionName                  = $Collection.name 
    $Deployment.DesiredConfigType               = 1 # 1 means install, 2 means uninstall
    $Deployment.LocaleID                        = 1033
    $Deployment.NotifyUser                      = $false
    $Deployment.OfferTypeID                     = 2 # 0 means required, 2 means available
    $Deployment.OverrideServiceWindows          = $true
    $Deployment.RebootOutsideOfServiceWindows   = $false
    $Deployment.SourceSite                      = "MU1"
    $Deployment.StartTime                       = "20160315120000.000000+***"
    $Deployment.SuppressReboot                  = $true
    $Deployment.TargetCollectionID              = $Collection.CollectionID   # CollectionID where to deploy it to
    $Deployment.WoLEnabled                      = $false
    $Deployment.UseGMTTimes                     = $false
    $Deployment.Put()
    }
}





AppDeploy($Applications)