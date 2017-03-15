$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath



Function Get-RegKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
            HelpMessage='What computer name would you like to target?')]
        [Alias('Computer')]
        [string[]]$ComputerName,
        [Parameter(Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
            HelpMessage='Scan for what reg key?')]
        [Alias('Key')]
		[string]$RegKey

    )

    [System.Collections.ArrayList]$Global:ComputerObjectList = @()

    if($computername -like "*.txt") {
        $computers = Get-Content -Path $computername
    }

    #HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_1188&PID_9545
    #$regKey = "SYSTEM\CurrentControlSet\Enum\USB\VID_8087&PID_0024\5&378a325c&0&1\Device Parameters"
    # SYSTEM\CurrentControlSet\Enum\USB\VID_8087&PID_0024\5&388fe42b&0&1\Device Parameters
    $RegKey = $RegKey.Replace("\","\\")


    #$computers = Get-Content -Path $dir\lbitl.txt

    foreach($computer in $computers) {

        $rkey = $null

        if(Test-Connection -ComputerName $computer -Count 1) {
            
            $registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", "$computer")

            if($registry.OpenSubKey("$RegKey") -ne $null) {
                $rkey = $registry.OpenSubKey("$RegKey")
                $key = "Bloomberg Keyboard attached"
            } else {
                $key = "Doesn't exist"
            } 

            <#
            try{
                #$key = ($registry.OpenSubKey("$regKey")).getValue("Default")
                #$key = ($registry.OpenSubKey("$regKey")).getsubkeynames()
                $rkey = $registry.OpenSubKey("$RegKey")
                $key = "Bloomberg Keyboard attached"
                #Write-Host $key
            } catch {
                $key = "Doesn't exist"
            }
            #>

            $compObj = New-Object -TypeName PSObject -Property @{
                KeyValue = $key
                Name = $computer
        
            } #| Export-Csv $dir\keylog.csv -Append

            $ComputerObjectList.Add($compObj)
            Write-Host $rkey
        }
    }

    #$ComputerObjectList | Out-GridView

}

