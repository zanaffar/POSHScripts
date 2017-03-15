ipconfig /flushdns
$computerlist = (Get-ADObject -Filter 'Name -like "w10-16fa*"').Name
[System.Collections.ArrayList]$ComputerObjectList = @()

foreach($computer in $computerlist) {
    $isBroken = $false
    $isOnline = $false
    $ErrorMessage = $null
    # $ping = ping hv56273w10 -4 -n 1 | Out-String
    
    # Failed ping - "Request timed out"

    # Get-WmiObject: Access is denied - indication of incorrect policies

    # Even though Test-Connection uses WMI, permissions aren't necessary

    try {
        Test-Connection -ComputerName $computer -Count 1 -ErrorAction Stop | Out-Null
        $isOnline = $true

        try {
            Get-WmiObject -ComputerName $computer -Class win32_computersystem -ErrorAction Stop | Out-Null
            $isBroken = $false
        } catch {
            $ErrorMessage = $_.Exception.Message
            $isBroken = $true

            #Write-Host $ErrorMessage
            
        }
    } catch {
        $ErrorMessage = $_.Exception.Message
    }
    $propHash =[ordered]@{
        Name = $computer
        isOnline = $isOnline
        isBroken = $isBroken
        ErrorMsg = $ErrorMessage
    }
    $obj = New-Object -TypeName psobject -Property $propHash
    $ComputerObjectList.Add($obj) | Out-Null

}

$ComputerObjectList | Out-GridView