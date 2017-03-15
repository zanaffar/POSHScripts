$computers = Get-ADComputer -Filter "Name -like 'PZ207*'"

foreach ($computer in $computers) {
Invoke-Command -ComputerName $computer -ScriptBlock {Get-Process -Name iexplore | Stop-Process -Force}
}