$computer = "localhost"
$hivePath = "C:\Users\mbado\Desktop\jcalvo\NTUSER.DAT"
reg load "HKU\Temp" $hivePath


New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
$hkeyUsersHIVE = [Microsoft.Win32.RegistryHive]::Users
#$hku_registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("$hkeyUsersHIVE", "$computer")
$hku_registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey("$hkeyUsersHIVE", "Default")
$OffVersions = $hku_registry.OpenSubKey("Temp\Software\Microsoft\Office").GetSubKeyNames() | Where-Object {<#($_ -eq "11.0") -or ($_ -eq "12.0")  -or ($_ -eq "13.0") -or #> ($_ -eq "14.0") -or ($_ -eq "15.0")}

[System.Collections.ArrayList]$OfficeVersionList = @()
[System.Collections.ArrayList]$ProdList = @()
foreach($OffVersion in $OffVersions) {
    $versKey = $hku_registry.OpenSubKey("Temp\Software\Microsoft\Office\$OffVersion")

    $subkeys = $versKey.GetSubKeyNames()

    foreach($subkey in $subkeys) {
        $prodKey = $subkey
        $versKey
        
        if((($hku_registry.OpenSubKey("Temp\Software\Microsoft\Office\$OffVersion\$prodKey").GetSubKeyNames()) -eq "File MRU") -or (($hku_registry.OpenSubKey("Temp\Software\Microsoft\Office\$OffVersion\$prodKey").GetSubKeyNames()) -eq "Place MRU")) {
            #$prodKey
            #"HKU\Temp\Software\Microsoft\Office\$OffVersion\$prodKey"
            $ProdObj = New-Object -TypeName psobject -Property @{
                Name = $prodKey
                Path = "HKU\Temp\Software\Microsoft\Office\$OffVersion\$prodKey"
                OfficeVersion = $OffVersion

            }
        $ProdList.Add($ProdObj) | Out-Null
        }

    }

    #if($hku_registry.OpenSubKey("Temp\Software\Microsoft\Office\$OffVersion").SubKeyCount -ge "10") {
        #$OffVersion
    #    $OffVersionObj = New-Object -TypeName psobject -Property @{
    #        OfficeVersion = $OffVersion
    #        RegPath = "HKU\Temp\Software\Microsoft\Office\$OffVersion"
    #        Products = $hku_registry.OpenSubKey("Temp\Software\Microsoft\Office\$OffVersion").GetSubKeyNames() | Where-Object {($_ -notlike "Clip Organizer") -and ($_ -notlike "Clip OrganizerDB") -and ($_ -notlike "CLView") -and ($_ -notlike "Common") -and ($_ -notlike "OIS") -and ($_ -notlike "Picture Manager") -and ($_ -notlike "Registration") -and ($_ -notlike "User Settings") -and ($_ -notlike "WEC")}

    #    }
    #$OfficeVersionList.Add($OffVersionObj) | Out-Null

    #}
}

$hkeyCurrentUserHIVE = [Microsoft.Win32.RegistryHive]::CurrentUser
$hkcu_registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey("$hkeyCurrentUserHIVE", "Default")
$localoffversions = $hkcu_registry.OpenSubKey("Software\Microsoft\Office").GetSubKeyNames() | Where-Object {($_ -eq "11.0") -or ($_ -eq "12.0")  -or ($_ -eq "13.0") -or ($_ -eq "14.0") -or ($_ -eq "15.0") -or ($_ -eq "16.0")}
$subkeys = $hkcu_registry.OpenSubKey("Software\Microsoft\Office\16.0").GetSubKeyNames()

$UserMRU_GUID = $hkcu_registry.OpenSubKey("Software\Microsoft\Office\16.0\Word\User MRU").GetSubKeyNames()

foreach($product in $ProdList) {
    $prodName = $product.Name
    #$localoffversions = $hkcu_registry.OpenSubKey("Software\Microsoft\Office\").getsubkeynames()
    
    ## For Office 2016 ##
    foreach($prodkey in $subkeys) {
        if($prodName -eq $prodkey) {
            $prodSource = $ProdObj | Where-Object {$_.Name -eq $ProdName}
            $prodSourceOffVers = $prodSource.OfficeVersion
            #$prodSourcePath = $prodSource.Path

            $prodSourcePath = "HKU:\Temp\Software\Microsoft\Office\$prodSourceOffVers\$prodName"
            $prodSourceOffVers = $prodSource.OfficeVersion

            $prodDestName = $prodName
            $prodDestPath = "HKCU:\Software\Microsoft\Office\16.0\$prodName"


            Copy-Item -Path "$prodSourcePath\File MRU" -Destination "$prodDestPath\User MRU\$UserMRU_GUID\File MRU\Test" -Recurse
            Copy-Item -Path "$prodSourcePath\Place MRU" -Destination "$prodDestPath\User MRU\$UserMRU_GUID\Place MRU\Test" -Recurse

            #$offProd = $hku_registry.OpenSubKey("Temp\Software\Microsoft\Office\$prodSourceOffVers\$prodName")
        }
    }

}
