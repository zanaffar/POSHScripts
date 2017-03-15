param([String]$username="") #Must be the first statement in your script

Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI -Name LastLoggedOnUser -Value $username

