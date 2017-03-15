$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

[String]$computer="MU53899"

Function Get-MappedDrives($computer) {

[System.Collections.ArrayList]$ComputerList = @()
[System.Collections.ArrayList]$UserList = @()
[System.Collections.ArrayList]$UsrDrvList = @()

#$computers = Get-Content -Path $dir\lbitl.txt
#$computer = "MU56273"
if((Get-Service -ComputerName "$computer" -Name "RemoteRegistry").Status -ne "Running") {
    Set-Service -ComputerName $computer -Name RemoteRegistry -StartupType Manual
    Set-Service -ComputerName $computer -Name RemoteRegistry -Status Running

}

$hkeyUsersHIVE = [Microsoft.Win32.RegistryHive]::Users
$hkeyLocalMachineHIVE = [Microsoft.Win32.RegistryHive]::LocalMachine

$hku_registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("$hkeyUsersHIVE", "$computer")
$user_keys = $hku_registry.GetSubKeyNames() | Where-Object {($_ -ne "S-1-5-19") -and ($_ -ne "S-1-5-20") -and ($_ -ne "S-1-5-18") -and ($_ -ne ".DEFAULT") -and ($_ -notlike "*classes")}
 
foreach($sid in $user_keys) {
    [System.Collections.ArrayList]$DriveList = @()
    $user = ""
    try {
        $objSID = New-Object System.Security.Principal.SecurityIdentifier("$sid")
        $user = $objSID.Translate([ System.Security.Principal.NTAccount])
    } catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        #Write-Host $ErrorMessage
        #Write-Host $FailedItem
        
    }    

    $user_obj = New-Object -TypeName PSObject -Property @{
        User_SID = $sid
        User_Name = "$user"
        MappedDrives = ""            
    }

    $mapped_drives = ($hku_registry.OpenSubKey("$sid\\Network")).GetSubKeyNames()
        
    foreach($mapped_drive in $mapped_drives){
            
        $mapped_drive_letter = $mapped_drive
        $mapped_drive_path = ($hku_registry.OpenSubKey("$sid\\Network\\$mapped_drive_letter")).getValue("RemotePath")
        $drive_obj = $mapped_drive_letter + ":   " + $mapped_drive_path            
        $DriveList.Add($drive_obj) | Out-Null
    }
        
    $user_obj.MappedDrives = $DriveList
    $UserList.add($user_obj) | Out-Null
}

foreach($UserObject in $UserList) {
    
    $props = [ordered]@{
        USER_SID = $UserObject.User_SID
        User_Name = $UserObject.User_Name
        MappedDrives = ($UserObject.MappedDrives | Out-String).Trim()
    }

    $user_drive_object_formatted = New-Object -TypeName PSObject -Property $props
        
    $UsrDrvList.Add($user_drive_object_formatted) | Out-Null
}

$UsrDrvList | Format-List

}
