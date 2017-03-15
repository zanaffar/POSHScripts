[System.Collections.ArrayList]$UserObjList= @()
[System.Collections.ArrayList]$UserList= @()

##############################################
### This needs to be run with zorak2 admin privs ###
### you must create a $cred var with Get-Credential first ###

if(!(Get-PSDrive -Name zorak2)) {
New-PSDrive -Name zorak2 -PSProvider FileSystem -Root "\\zorak2\g$\users" -Credential $cred
}

$Users = (Get-ChildItem -Path "zorak2:\" | Where-Object {($_.Name -notlike "s0*") -and ($_.Name -notlike "s1*")}).Name


foreach($User in $Users) {
    $desktopItems = $null
    $DesktopSize = $null
    $latestWriteItem = $null
    $latestWriteItemName = $null
    $latestWriteItemTime = $null
    $latestAccessItem = $null
    $latestAccessItemName = $null
    $latestAccessItemTime = $null

    if(Test-Path -Path "zorak2:\$user\Desktop") {
    
    Write-Host "Working on $user..."    
    $desktopItems = Get-ChildItem -Path "zorak2:\$user\Desktop" -Recurse

    ## Get the size of the desktop ##
    $DesktopSize = $desktopItems | Measure-Object -Property Length -Sum 
    $DesktopSize = "{0:N2}" -f ($DesktopSize.sum / 1KB)
    
    ## Get latest writetime item ##
    $latestWriteItem = ($desktopItems | Sort-Object -Property lastwritetime -Descending | Select-Object -Property FullName,LastWriteTime)[0]
    $latestWriteItemName = $latestWriteItem.FullName
    $latestWriteItemTime = $latestWriteItem.LastWriteTime

    ## Get latest accesstime item ##
    $latestAccessItem = ($desktopItems | Sort-Object -Property lastaccesstime -Descending | Select-Object -Property FullName,LastWriteTime)[0]
    $latestAccessItemName = $latestAccessItem.FullName
    $latestAccessItemTime = $latestAccessItem.LastWriteTime

    #$propHash =[ordered]@{
     #   Username = $User
      #  DesktopSize = $DesktopSize.sum
        
    #}

    $oUser = New-Object -TypeName psobject -Property @{
        Username = $User
        DesktopSizeKB = [string]$DesktopSize
        latestWriteItemName = $latestWriteItemName
        latestWriteItemTime = $latestWriteItemTime
        latestAccessItemName = $latestAccessItemName
        latestAccessItemTime = $latestAccessItemTime
    }
    
    #| Export-CSV -Path "MB:\users.csv" -Append

    $null = $UserList.Add($oUser)
    } else { 
    Write-Host "$user doesn't have a Desktop on zorak2"
    }
}

########################################

########################################
### Read the contents for the CSV to get the user list ###
<#
$CSV = Get-Content -Path "C:\users.csv"

for($i=2; $i -le $CSV.Length; $i++) {

    $line = $CSV[$i]
    $line = $line -split '",'
    $line = $line.Replace('"','')
    $line = $line.Replace(' KB','')

    $oUsr = New-Object -TypeName psobject -Property @{
        Username = [String]$line[1]
        DesktopSizeKB = [Double]$line[0]
    }

    $UserList.Add($oUsr) | Out-Null
}
#>
########################################

#$UserList = Get-Content -Path "C:\Users\mbado\Desktop\users.txt"

foreach($UserItem in $UserList) {
    
    $User = $UserItem.Username

    if($UserItem.DesktopSizeKB -eq "0.00") {
        continue
    }

    [System.Collections.ArrayList]$MachineObjList = @()

    $objUser = $null
    $strSID = $null
    $objSID = $null
    $domUser = $null
    $UserObj = $null
    $HasLaptop = $null

    $propHash = [ordered] @{
        Username = $User
        HasLaptop = $null
        DesktopSize = [String]$UserItem.DesktopSizeKB + " KB"
        latestWriteFileName = $UserItem.latestWriteItemName
        latestWriteFileTime = $UserItem.latestWriteItemTime
        latestAccessFileName = $UserItem.latestAccessItemName
        latestAccessFileTime = $UserItem.latestAccessItemTime
        DomainUsername = $null
        SID = $null
        PrimaryDevice = $null 
        UserAffinity = $null
    }

    $UserObj = New-Object -TypeName psobject -Property $propHash

    #Out-File -FilePath "C:\users\mbado\desktop\users.log" -InputObject "Working on $User" -Append

    $objUser = New-Object System.Security.Principal.NTAccount("$User")
    $objSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
    $domUser = $objSID.Translate([System.Security.Principal.NTAccount])

    $UserObj.DomainUsername = $domUser
    $UserObj.SID = $objSID.Value

    $modDomainUsername = $domUser.value.Replace("\","\\")

    $query = "Select * From SMS_UserMachineRelationship
    Where SMS_UserMachineRelationship.UniqueUserName = ""$modDomainUsername"""

    $UserComps =  Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "$query"


    foreach($comp in $UserComps) {
        #if($UserObj.HasLaptop -

        $Primary = $null
        $name = $comp.resourceName
        $MachineType = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "SELECT * FROM SMS_G_System_COMPUTER_SYSTEM WHERE SMS_G_System_COMPUTER_SYSTEM.Name = ""$name"""
        
        

        if($comp.types -eq "1"){
            $Primary = $true
            if($MachineType.Model -like "*book*") {
                $HasLaptop = $true
            }
        }
        
        $CompObj = New-Object -TypeName psobject -Property @{
            Name = $name
            Primary = $Primary
            Model = $MachineType.Model
        }
        
        $null = $MachineObjList.Add($CompObj)
    }

    $PrimaryDevices = $MachineObjList | Where-Object {$_.primary -eq $true} | Select-Object -Property Name,Model
    $settings_array = @("Name","Model")
    $UserObj.HasLaptop = $HasLaptop
    $UserObj.PrimaryDevice = ($PrimaryDevices | Select-Object -Property $settings_array)
    $UserObj.UserAffinity = (($MachineObjList.name) -join ',')

    Out-File -FilePath "C:\users\mbado\desktop\users.log" -InputObject "$UserObj" -Append


    $null = $UserObjList.Add($UserObj)
}

$UserObjList | Out-GridView