[System.Collections.ArrayList]$Users = @()

$EMS_Server = "http://WLB-EMS-02/EmsDesktopWebDeploy/"

if("$env:USERNAME" -like "*$env:COMPUTERNAME*") {
    $UDA_Users = (Get-CimInstance -Namespace 'root/ccm/Policy/Machine/ActualConfig' -ClassName 'CCM_UserAffinity').ConsoleUser | ForEach-Object {$_.Split('\')[1]}
    if($UDA_Users.count -gt 1) {
        for($i = 0; $i -lt $UDA_Users.Count; $i++) {
            $User = Get-Item -Path "C:\Users\$($UDA_Users[$i])"
            $null = $Users.Add($User)
        }
    } else {
        $null = $Users.Add($UDA_Users)
    }

    foreach($User in $Users) {
        $flag = $false
        if((Test-Path "C:\Users\$User\AppData\Roaming\EMS2016") -and ((Get-Content "C:\Users\$User\AppData\Roaming\EMS2016\emswebdeployconfiguration.cfg") -eq "$EMS_Server")) {
            $flag = $true
        }
    }

    if($flag) {return $true}
} else {

    $User = $env:USERNAME

    if((Test-Path "C:\Users\$User\AppData\Roaming\EMS2016") -and ((Get-Content "C:\Users\$User\AppData\Roaming\EMS2016\emswebdeployconfiguration.cfg") -eq "$EMS_Server")) {
        return $true
    }
}
