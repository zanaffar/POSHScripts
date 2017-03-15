$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

$computers = Get-Content -Path $dir\labs.txt

$filter = @{

    LogName = 'Application'

    #ProviderName = 'Microsoft-Windows-Winlogon'

    StartTime = (Get-Date).AddDays(-1)

    Id = '4006'

}

 

foreach ($computer in $computers){

    New-Object -TypeName PSObject -Property @{
   
        Computer = $computer
    
        Count = Get-WinEvent -FilterHashtable $filter -ComputerName $computer | Measure-Object | select -ExpandProperty Count 

        } |  Export-Csv $dir\log.csv -Append

    #Get-WinEvent -FilterHashtable $filter -ComputerName $computer |  Out-File -FilePath $dir\log.txt -Append

} 