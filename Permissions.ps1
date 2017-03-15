$computers = Get-Content -Path C:\Users\mbado\desktop\scripts\computers.txt
Invoke-Command -ComputerName $computers {ICACLS "C:\Program Files\Android\sdk" /grant '"Users":F' /t /q} -Verbose