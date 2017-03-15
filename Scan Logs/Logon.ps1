# Lab number (ie E156) or Computer name (ie MU12345 or 12345)
#$nameVar = "2nd Floor Lounge Lab"
$SearchBase = $null
$computerList = $null
$OU = $null
$computerName = $null


$computerName = "MU52005"
#$OU = "HH306"
if($OU){
    $SearchBase = (Get-ADObject -Filter "OU -eq `"$OU`"").DistinguishedName
}

if($SearchBase) {
    $computerList = (Get-ADComputer -Filter "ObjectClass -eq 'computer'" -SearchBase $SearchBase).name
} else {
    $computerList = (Get-ADComputer -Filter "Name -eq `"$computerName`"").Name
}

#$computerList = (Get-ADObject -Filter "Name -like `"$nameVar*`"").Name

[System.Collections.ArrayList]$eventList = @()

foreach($computer in $computerList) {
    
    if(Test-Connection -ComputerName $computer -Count 1) {

        $filter = @{

            #LogName = 'Application'

            ProviderName = 'Microsoft-Windows-User Profiles Service'

            #ProviderName = 'Microsoft-Windows-Winlogon'

            StartTime = (Get-Date).AddDays(-100)

    
            #TimeCreated = (Get-Date).AddDays(-1).GetDateTimeFormats()[43]

            #Id = '4006'

        }

        $events = Get-WinEvent -FilterHashtable $filter -ComputerName "$computer" | Where-Object {($_.UserId -ne "S-1-5-19") -and ($_.UserId -ne "S-1-5-20") -and ($_.UserId -ne "S-1-5-18") -and ($_.UserId -ne ".DEFAULT") -and ($_.UserId -notlike "*classes") -and ($_.Message -like "Recieved user logon*")}


        foreach($event in $events) {
                $user = ''
                $objSID = ''
                $objUser = ''
                
                $user = $event.userid
                
                $objSID = New-Object System.Security.Principal.SecurityIdentifier("$user")
                if($objSID.Value -like '*-500') {
                    $objUser = "$env:COMPUTERNAME\Administrator"
                } else {
                    try{
                        $objUser = $objSID.Translate([ System.Security.Principal.NTAccount])
                    } catch { 

                    }
                }
                $propHash = [ordered]@{
                    Computer = $computer
                    User = $objUser
                    SID = $event.userid
                    Msg = $event.message
                    Time = $event.TimeCreated
                }

                $eventObj = New-Object -TypeName psobject -Property $propHash
                $eventList.Add($eventObj) | Out-Null

        }
    }
}

$eventList | Out-GridView
