[System.Reflection.Assembly]::LoadFrom(“C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\Microsoft.ConfigurationManagement.ApplicationManagement.dll”)
[System.Reflection.Assembly]::LoadFrom(“C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\Microsoft.ConfigurationManagement.ApplicationManagement.Extender.dll”)
[System.Reflection.Assembly]::LoadFrom(“C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll”)


$server = "wlb-sysctr-02"
$site = "MU1"
$applications = Get-WmiObject -ComputerName "$server" -Namespace "root\sms\site_$site" -Query 'Select * from SMS_Application where SMS_Application.IsLatest = "True" and SMS_Application.IsEnabled = "True" and SMS_Applications.IsExpired = "False"'

foreach($application in $applications) {
    $app = [wmi]$application.__PATH

    $appXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($app.SDMPackageXML,$true)
    $appxml.AutoInstall = $true
    $appxml.AutoDistribute = $true
    $updatedXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($appXML,$true)
    $app.SDMPackageXML = $updatedXML
    $app.Put()

}
# to set post install behavior
#$appxml.deploymenttypes.installer.postinstallbehavior