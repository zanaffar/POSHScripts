$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$workbook = $excel.workbooks.Open("$PSScriptRoot\multimedia center ip control interface address list.xlsx")
$s1 = $workbook.sheets | where {$_.name -eq 'Sheet1'}

$hostname = hostname
$room = $hostname.split("-")[0]
$RoomRow = ($s1.UsedRange.Rows) | Where-Object {$_.value2 -contains "$room"}
