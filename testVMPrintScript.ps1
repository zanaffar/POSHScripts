ipconfig /flushdns
$computerlist = (Get-ADObject -Filter 'Name -like "w10-16fa*"').Name
[System.Collections.ArrayList]$ComputerObjectList = @()

$hkeyUsersHIVE = [Microsoft.Win32.RegistryHive]::Users

$EventLogfilter = @{
    ProviderName = 'Microsoft-Windows-User Profiles Service'
    StartTime = (Get-Date).AddDays(-1)
}

foreach($computer in $computerlist) {
    $userprofs = $null
    $userprof = $null
    $online = $null
    $printerscriptRan = $null
    $hku_registry = $null
    $user_keys = $null
    $sid = $null
    $mapped_printers = $null
    $mac = $null
    $compObj = $null
    $ip = $null
    $VC_machine_name = $null
    $logOff = $null
    $objSID = $null
    $username = $null
    $isBroken = $null
    $ErrorMessage = $null

    if(Test-Connection -ComputerName $computer -Count 1) {
        
        try{
            $userprofs = Get-ChildItem -Path "\\$computer\c$\Users\" -ErrorAction STOP | Where-Object {($_.Name -ne "Administrator") -and ($_.Name -ne "Public")}
            
        } catch {
            $ErrorMessage = $_.Exception.Message
            $isBroken = $true
        }

        if($userprofs.count -ge "1") {
            foreach($userprof in $userprofs){
                $userprof = $userprof.name
                if(Test-Path -Path "\\$computer\c$\Users\$userprof\AppData\Local\Temp\Map-Network-Printers.txt") {
                    $printerscriptRan = $true
                } else {
                    $printerscriptRan = $false
                }
            }

            $hku_registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("$hkeyUsersHIVE", "$computer")
            $user_keys = $hku_registry.GetSubKeyNames() | Where-Object {($_ -ne "S-1-5-19") -and ($_ -ne "S-1-5-20") -and ($_ -ne "S-1-5-18") -and ($_ -ne ".DEFAULT") -and ($_ -notlike "*classes")}

            foreach($sid in $user_keys) {
                $mapped_printers = ($hku_registry.OpenSubKey("$sid\\Printers\\Connections")).GetSubKeyNames()
                $mac = $hku_registry.OpenSubKey("$sid\\Volatile Environment").GetValue("ViewClient_MAC_Address")
                $ip = $hku_registry.OpenSubKey("$sid\\Volatile Environment").GetValue("ViewClient_IP_Address")
                $VC_machine_name = $hku_registry.OpenSubKey("$sid\\Volatile Environment").GetValue("ViewClient_Machine_Name")

                $objSID = New-Object System.Security.Principal.SecurityIdentifier("$sid")
                $username = $objSID.Translate([ System.Security.Principal.NTAccount])

                $logOff = Get-WinEvent -FilterHashtable $EventLogfilter -ComputerName "$computer" | Where-Object {($_.UserID -eq "$sid") -and ($_.Message -like "Finished processing user logoff*")}

            }

            if($mapped_printers.count -eq "0") {
                if(($mac -eq "E8-5B-5B-71-AD-C4" <# MRH136A - Mullaney #>)) {
                    $mapped_printers = "MRH136A - Mullaney - These machines don't get printers"
                } elseif (($mac -eq "E8-5B-5B-71-AF-67" <# JP1FL #>) -or ($mac -eq "E8-5B-5B-71-AF-76" <# JP1FL #>) -or ($mac -eq "E8-5B-5B-71-B2-95" <# JP1FL #>)) {
                    $mapped_printers = "JP1FL - These machines don't get printers"
                } elseif ($VC_machine_name -like "cslin*" <# CS #>) {
                    $mapped_printers = "CS Linux Lab - These machines don't get printers"
                }


                if($logOff) {
                    $mapped_printers = "User has logged off and the machine is deleting"
                }
                if(($mac -eq $null) -or ($ip -eq $null) -or ($VC_machine_name -eq $null)) {
                    $mapped_printers = "Horizon Client machine"
                }
            }
        }
    
    } else {
        $online = $false
    }

    $propHash =[ordered]@{
        ComputerName = $computer
        Online = $online
        Broken = $isBroken
        MAC = $mac
        IP = $ip
        Profile = $username
        ScriptRan = $printerscriptRan
        Printers = $mapped_printers
        ViewClient_MachineName = $VC_machine_name
        LogOff = $logOff.timecreated
        ErrorMsg = $ErrorMessage
    }

    $compObj = New-Object -TypeName psobject -Property $propHash

    $ComputerObjectList.Add($compObj)
}

$ComputerObjectList | Out-GridView
