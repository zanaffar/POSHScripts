$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

#$computers = Get-Content -Path $dir\labs.txt

$computer = "MU56804"

$filter = @{

    #LogName = 'Application'

    ProviderName = 'Microsoft-Windows-PrintService'

    #ProviderName = 'Microsoft-Windows-Winlogon'

    #StartTime = (Get-Date).AddDays(-1)

    TimeCreated = -gt (Get-Date).AddDays(-1)

    #Id = '4006'

}

$a = Get-WinEvent -FilterHashtable $filter -ComputerName "MU56273" # | Where-Object {$_.TimeCreated -gt ((Get-Date).AddDays(-1))}

 

#foreach ($computer in $computers){

#    New-Object -TypeName PSObject -Property @{
   
#        Computer = $computer
    
#        Count = Get-WinEvent -FilterHashtable $filter -ComputerName $computer | Measure-Object | select -ExpandProperty Count 

#        } |  Export-Csv $dir\printlog.csv -Append

    #Get-WinEvent -FilterHashtable $filter -ComputerName $computer |  Out-File -FilePath $dir\log.txt -Append

#} 