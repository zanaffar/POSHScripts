Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'

cd MU1:

$date = Get-Date
$colName = 'FASM Baseline'

#New-CMCollection -CollectionType Device -LimitingCollectionName 'All MU Workstations excl VMView VMs' -Name 'FASM Baseline' -Verbose

$apps = Get-CMApplication -Fast | Where-Object {
    ($_.LocalizedCategoryInstanceNames -contains 'FASM Required') -and `
    ($_.LocalizedCategoryInstanceNames -notcontains 'Laptop Specific') -and `
    ($_.isExpired -eq $False)}

Start-CMApplicationDeployment -CollectionName "$colName" -Name "$($apps[1].LocalizedDisplayName)" `
-AvailableDateTime $date `
-DeadlineDateTime $date.AddDays(1) `
-DeployAction 'Install' `
-FailParameterValue 40 `
-OverrideServiceWindow $True `
-PersistOnWriteFilterDevice $False `
-PostponeDateTime $date.AddDays(2) `
-PreDeploy $True `
-RebootOutsideServiceWindow $True `
-SendWakeUpPacket $True `
-SuccessParameterValue 30 `
-UseMeteredNetwork $True `
-UserNotification 'DisplaySoftwareCenterOnly' `
-DeployPurpose 'Required' `
-TimeBaseOn 'LocalTime' `
-Verbose