$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

[hashtable]$CompRegList = @{}
#$computers = Get-Content -Path $dir\lbitl.txt
$computers = 'MU56553'
$Key = 'Software\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon'

foreach($computer in $computers) {
    $registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", "$computer")
    $regKey = $registry.OpenSubKey("$Key")
    $regValue = $regKey.getValue('Userinit')

    New-Object -TypeName PSObject -Property @{
        KeyValue = $regKey
        Name = $computer
        
    } #| Export-Csv $dir\keylog.csv -Append

    $CompRegList.Add($Computer, $regValue)

}


