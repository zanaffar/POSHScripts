$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

[System.Collections.ArrayList]$ComputerList = @()
$ComputerList.Clear()

$DriveList.Clear()
[System.Collections.ArrayList]$UserList = @()
$UserList.Clear()

#$computers = Get-Content -Path $dir\lbitl.txt
$computer = "MU56273"

$hkeyUserHIVE = [Microsoft.Win32.RegistryHive]::Users
$hkeyLocalMachineHIVE = [Microsoft.Win32.RegistryHive]::LocalMachine


$hku_registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("$hkeyUserHIVE", "$computer")
$user_keys = $hku_registry.GetSubKeyNames() | Where-Object {($_ -ne "S-1-5-19") -and ($_ -ne "S-1-5-20") -and ($_ -ne "S-1-5-18") -and ($_ -ne ".DEFAULT") -and ($_ -notlike "*classes")}

 
foreach($user in $user_keys) {
    [System.Collections.ArrayList]$DriveList = @()
    $user_obj = New-Object -TypeName PSObject -Property @{
        User_SID = $user
        User_Name = ""
        MappedDrives = ""
            
    }

    $mapped_drives = ($hku_registry.OpenSubKey("$user\\Network")).GetSubKeyNames()
        
    foreach($mapped_drive in $mapped_drives){
            
        $mapped_drive_letter = $mapped_drive
        $mapped_drive_path = ($hku_registry.OpenSubKey("$user\\Network\\$mapped_drive_letter")).getValue("RemotePath")

        $drive_obj = $mapped_drive_letter + ":   " + $mapped_drive_path
            
        $DriveList.Add($drive_obj) | Out-Null
        #$user_obj.MappedDrives += $drive_obj
        #$user_obj.DrivePath.Insert($drive_obj.DrivePath)
    }
        
    $user_obj.MappedDrives = $DriveList



    $UserList.add($user_obj) | Out-Null

}
[System.Collections.ArrayList]$ObjList = @()

foreach($UserObject in $UserList) {
    #$UserObject
    $props = [ordered]@{
        USER_SID = $UserObject | Select -ExpandProperty User_SID
        MappedDrives = ($UserObject.MappedDrives | Out-String).Trim()
    }
    $nobj = New-Object -TypeName PSObject -Property $props
    
    
    $ObjList.Add($nobj)
}
