$date = Get-Date
$month_number = $date.Month
$Year = $date.Year

switch ($date.Month)
{
	1 {
		$month = 'January'
	}
	2 {
		$month = 'February'
	}
	3 {
		$month = 'March'
	}
	4 {
		$month = 'April'
	}
	5 {
		$month = 'May'
	}
	6 {
		$month = 'June'
	}
	7 {
		$month = 'July'
	}
	8 {
		$month = 'August'
	}
	9 {
		$month = 'September'
	}
	10 {
		$month = 'October'
	}
	11 {
		$month = 'November'
	}
	12 {
		$month = 'December'
	}
}

#Set-Variable -Name "month_number" -Value $a.Month
#Set-Variable -Name "Year" -Value $a.Year

#If ($a.Month -eq 11) {Set-Variable -Name "month" -Value fNovember}
$dirMigData = '\\hercules\migdata$'
$dir_ScanState = "$dirMigData\USMT_SCANSTATE"
$dirDest = "$dir_ScanState\$Year\$month_number $month"
$dirUSMT = "$dirMigData\Backup_Commands\USMT10.0.14393\amd64"

#Set-Variable -Name "routeB" -Value "\\hercules\migdata$\USMT_Scanstate\$Year\$month_number $month"
#Set-Variable -Name "routeG" -Value "\\hercules\migdata$\Backup_Commands\USMT10.0.14393\amd64"
if (!(Test-Path -path $dirDest))
{
	New-Item -ItemType directory -Path $dirDest
}

$ScanState_param1 = "$dirDest\$env:COMPUTERNAME"
$ScanState_param2 = "/i:$dirUSMT\ed4newtest.xml"
$ScanState_param3 = "/i:$dirUSMT\eddocs.xml"
$ScanState_param4 = "/i:$dirUSMT\migapp.xml"
$ScanState_param5 = '/uel:360'
$ScanState_param6 = '/v:13'
$ScanState_param7 = "/l:$ScanState_param1\scan.log"
$ScanState_param8 = '/c'

& "$dirUSMT\scanstate.exe" "$ScanState_param1" "$ScanState_param2" "$ScanState_param3" "$ScanState_param4" "$ScanState_param5" "$ScanState_param6" "$ScanState_param7" "$ScanState_param8"

#& \\hercules\migdata$\Backup_Commands\USMT10.0.14393\amd64\scanstate.exe \\hercules\migdata$\$env:COMPUTERNAME /i:\\hercules\migdata$\Backup_Commands\USMT10.0.14393\amd64\eddocs.xml /l:\\hercules\migdata$\ed\scan.log /c
##%routeG%\scanstate.exe %routeB%\%computername% /i:%routeG%\ed4newtest.xml /i:%routeG%\eddocs.xml /i:%routeG%\migapp.xml /uel:360 /v:13 /l:%routeB%\%computername%\scan.log /c
 ##"Month: " + $a.Month
               ##"Year: " + $a.Year
               ##repeat for each month
## if(!(test-path -path \\hercules\migdata$\USMT_Scanstate\$Year\$month_number'_'$month)){New-Item -ItemType directory -Path \\hercules\migdata$\USMT_Scanstate\$Year\$month_number'_'$month}
##if(!(test-path -path "\\hercules\migdata$\USMT_Scanstate\$Year\$month_number'_'$month")){New-Item -ItemType directory -Path \\hercules\migdata$\USMT_Scanstate\$Year\$month_number'_'$month }
