$script = Get-Content -Path "$PSScriptRoot\FileZilla\archive\$latestVersion\win_x86\Deploy-Application.ps1"

ForEach ($line in $script) {
    if ($line.contains("`$appVendor = `"`"")) { #if empty
        $script | ForEach-Object {$_ -replace "$line","	[string]`$appVendor = `"$appVendor`""} | Set-Content "$PSScriptRoot\FileZilla\archive\$latestVersion\win_x86\Deploy-Application.ps1"
    }
    #if ($line.contains("`$appName = `"`"")) { #if empty
    #    $script | ForEach-Object {$_ -replace "$line","	[string]`$appName = `"$appName`""} #| Set-Content $BrightAuthorDir\UserPreferences.xml 
    #}
    #if ($line.contains("`$appVersion = `"`"")) { #if empty
    #    $script | ForEach-Object {$_ -replace "$line","	[string]`$appVersion = `"$appVersion`""} #| Set-Content $BrightAuthorDir\UserPreferences.xml 
    #}
    #if ($line.contains("`$appArch = `"`"")) { #if empty
    #    $script | ForEach-Object {$_ -replace "$line","	[string]`$appArch = `"$appArch`""} | Set-Content "$PSScriptRoot\FileZilla\archive\$latestVersion\win_x86\Deploy-Application.ps1"
    #} 
    
} 