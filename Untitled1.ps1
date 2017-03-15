Invoke-Command -ComputerName hv56273w7 -Credential monmouth0\mbado -ScriptBlock {
    cd c:\
    . .\Get-PendingUpdate.ps1
    Get-PendingUpdate -Computer localhost
    }