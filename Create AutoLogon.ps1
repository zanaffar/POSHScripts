param([String]$username="ymahajan") 
param([String]$password="Fin&sept") 
param([String]$domain="hawkdom2") 

Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\winlogon" -Name "DefaultPassword" -Value "$password"
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\winlogon" -Name "DefaultUserName" -Value "$username"
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\winlogon" -Name "DefaultDomainName" -Value "$domain"
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\winlogon" -Name "AutoAdminLogon" -Value "1"
Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\winlogon" -Name "AutoLogonCount"
#Restart-Computer -Force
