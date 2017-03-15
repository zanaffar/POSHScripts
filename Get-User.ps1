[System.Collections.ArrayList]$UserList = @()

$Users = Get-ChildItem -Path "C:\Users" | Where-Object {($_.Name -ne "Public") -and ($_.Name -ne "All Users") -and ($_.Name -ne "Default") -and ($_.Name -ne "Default User") -and ($_.Name -ne "TEMP")}
$SIDs = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
foreach($User in $Users) {
    $User = $User.ToString().Split(".")[0]
    $objUser = New-Object System.Security.Principal.NTAccount("$User")
    try {
        $strSID = ($objUser.Translate([System.Security.Principal.SecurityIdentifier]).Value)
    } catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        #Write-Host $ErrorMessage
        #Write-Host $FailedItem
        $strSID = ($SIds | ForEach-Object { Get-ItemProperty -Path $_.pspath } | Where-Object { $_.ProfileImagePath -like "*$User" }).pschildname
    }
    $objSID = New-Object System.Security.Principal.SecurityIdentifier("$strSID")
    $UserSID = New-Object -TypeName PSObject -Property @{   
        User = $User
        SID = $strSID
        Path = "C:\Users\$User"
        DomainAndUsername = $objSID.Translate([ System.Security.Principal.NTAccount])
    }
    $UserList += $UserSID
    #Write-Host  $strSID "," $User
}
$UserList
## Test ##