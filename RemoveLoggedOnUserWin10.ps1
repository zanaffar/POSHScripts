param([String]$username="") #Must be the first statement in your script

Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI -Name LastLoggedOnUser -Value $username
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI -Name LastLoggedOnSAMUser -Value $username
Remove-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI -Name LastLoggedOnDisplayName -Force
Remove-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI -Name LastLoggedOnUserSID -Force
Remove-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI -Name SelectedUserSID -Force

