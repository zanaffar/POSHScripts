$a = Get-Date

              
Set-Variable -Name "month_number" -Value $a.Month
Set-Variable -Name "Year" -Value $a.Year

If ($a.Month -eq 11) {Set-Variable -Name "month" -Value fNovember}

Set-Variable -Name "routeB" -Value "\\hercules\migdata$\USMT_Scanstate\$Year\$month_number $month"
Set-Variable -Name "routeG" -Value "\\hercules\migdata$\Backup_Commands\USMT10.0.14393\amd64"
 if(!(test-path -path $routeB)){New-Item -ItemType directory -Path $routeB}


##%routeG%\scanstate.exe %routeB%\%computername% /i:%routeG%\ed4newtest.xml /i:%routeG%\eddocs.xml /i:%routeG%\migapp.xml /uel:360 /v:13 /l:%routeB%\%computername%\scan.log /c
 ##"Month: " + $a.Month
               ##"Year: " + $a.Year
               ##repeat for each month
## if(!(test-path -path \\hercules\migdata$\USMT_Scanstate\$Year\$month_number'_'$month)){New-Item -ItemType directory -Path \\hercules\migdata$\USMT_Scanstate\$Year\$month_number'_'$month}
##if(!(test-path -path "\\hercules\migdata$\USMT_Scanstate\$Year\$month_number'_'$month")){New-Item -ItemType directory -Path \\hercules\migdata$\USMT_Scanstate\$Year\$month_number'_'$month }
& \\hercules\migdata$\Backup_Commands\USMT10.0.14393\amd64\scanstate.exe \\hercules\migdata$\$env:COMPUTERNAME /i:\\hercules\migdata$\Backup_Commands\USMT10.0.14393\amd64\eddocs.xml /l:\\hercules\migdata$\ed\scan.log /c