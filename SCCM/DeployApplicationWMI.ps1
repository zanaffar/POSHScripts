Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'

cd MU1:

$date = Get-Date
$colName = 'FASM Baseline'
$Collection = Get-CMCollection -Name $colName

$apps = Get-CMApplication -Fast | Where-Object {
    ($_.LocalizedCategoryInstanceNames -contains 'FASM Required') -and `
    ($_.LocalizedCategoryInstanceNames -notcontains 'Laptop Specific') -and `
    ($_.isExpired -eq $False)}

$SiteCode="MU1"
$SccmServer = "wlb-sysctr-02"
$DeploymentClass = [wmiclass] "\\$SccmServer\root\sms\site_$($SiteCode):SMS_ApplicationAssignment"

#foreach ($App in $Apps) {
    $app = $apps[0]
    
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
    $Deployment.StartTime                       = "20170315120000.000000+***"
    $Deployment.SuppressReboot                  = $true
    $Deployment.TargetCollectionID              = $Collection.CollectionID   # CollectionID where to deploy it to
    $Deployment.WoLEnabled                      = $false
    $Deployment.UseGMTTimes                     = $false
    $Deployment.Put()
#}