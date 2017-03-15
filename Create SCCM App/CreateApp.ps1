Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
New-PSDrive mu1 -PSProvider cmsite -Root wlb-sysctr-02.monmouth.edu
cd mu1:

$name = Read-Host 'Enter the Application Name'
$publisher = Read-Host 'Enter the Application Publisher'
$version = Read-Host 'Enter the Application Version'
$appName = "$name $version"
New-CMApplication -Name $appName -Publisher $publisher -SoftwareVersion $version
Send-MailMessage -To "mbado@monmouth.edu" -Subject "New ConfigMgr Application" -Body "$appName" -From "mbado@monmouth.edu" -SmtpServer "mail.monmouth.edu"