[System.Collections.ArrayList]$UserObjList = @()

$Users = (Get-ChildItem -Path "." | Where-Object {($_.Name -notlike "s0*") -and ($_.Name -notlike "s1*")}).Name

foreach($User in $Users) {
    if(Test-Path -Path "$user\Desktop") {
    
    Write-Host "Working on $user..."    
    $DesktopSize = Get-ChildItem -Path "$user\Desktop" -Recurse | Measure-Object -Property Length -Sum
    $DesktopSize = "{0:N2}" -f ($DesktopSize.sum / 1KB) + " KB"
    #$propHash =[ordered]@{
     #   Username = $User
      #  DesktopSize = $DesktopSize.sum
        
    #}

    $UserObj = New-Object -TypeName psobject -Property @{
        Username = $User
        DesktopSize = $DesktopSize
    } | Export-CSV -Path "MB:\users.csv" -Append

    $UserObjList.Add($UserObj) | Out-Null
    } else { 
    Write-Host "$user doesn't have a Desktop on zorak2"
    }
}

$UserObjList

