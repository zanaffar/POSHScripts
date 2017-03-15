$version = (Get-ItemProperty ${env:ProgramFiles(x86)}\BrightSign\BrightAuthor\BrightAuthor.exe).VersionInfo.FileVersion

if($version -eq $null){
    Write-Host "BrightSign is not installed on this machine. Exiting."
    return
}

## Test to see if previous versions of BrightAuthor preferences exist. Copy those preferences if they exist.
if((Get-ChildItem -Path "$env:LOCALAPPDATA\BrightSign\BrightAuthor\").count -gt 1) {
    [System.Collections.ArrayList]$versionList = @()
    $versions = Get-ChildItem "$env:LOCALAPPDATA\BrightSign\BrightAuthor\"
    foreach ($vrsn in $versions) {
        if(Test-Path -Path "$env:LOCALAPPDATA\BrightSign\BrightAuthor\$vrsn\UserPreferences.xml") {
            $vrsnObj = New-Object -TypeName psobject -Property @{
                Version = [version]$vrsn.Name
                DateMod = Get-ItemPropertyValue -Path "$env:LOCALAPPDATA\BrightSign\BrightAuthor\$vrsn\UserPreferences.xml" -Name LastWriteTime
            }
            $versionList.add($vrsnObj) | Out-Null
            
        }
    }
    
    $versionList = $versionList | Sort-Object -Descending -Property DateMod
    
    $latestUsedVersion = $versionList[0].version.ToString()
   
    ROBOCOPY "$env:LOCALAPPDATA\BrightSign\BrightAuthor\$latestUsedVersion" "$env:LOCALAPPDATA\BrightSign\BrightAuthor\$version" /E

}


$BrightAuthorDir = "$env:LOCALAPPDATA\BrightSign\BrightAuthor\$version"

if(!(Test-Path -Path "$BrightAuthorDir\UserPreferences.xml")) {
    ROBOCOPY "V:" "$BrightAuthorDir\" "UserPreferences.xml" /XC /XN /XO
} elseif(Test-Path -Path "$BrightAuthorDir\UserPreferences.xml") {
    Write-Host "Preferences already exist. Exiting"
    return   
}

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$workbook = $excel.workbooks.Open("V:\BrightAuthor_user_specs.xlsx")

$s1 = $workbook.sheets | where {$_.name -eq 'Sheet1'}

$UserRow = ($s1.UsedRange.Rows) | Where-Object {$_.value2 -contains "$env:USERNAME"}

$Settings = New-Object -TypeName psobject -Property @{
    User = $UserRow.value2[1,1]
    Location = $UserRow.value2[1,2]
    ContentFolder = $UserRow.value2[1,3]
    PublishFolder = $UserRow.value2[1,4]
    PublishParameter = $UserRow.value2[1,5]
}


$prefs = Get-Content $BrightAuthorDir\UserPreferences.xml

$PublishParameters = $Settings.PublishParameter
$PublishFolder = $Settings.PublishFolder

ForEach ($line in $prefs) {
    if ($line.contains("<SimpleNetworkingURL />")) { #if empty
        $prefs | ForEach-Object {$_ -replace "$line","    <SimpleNetworkingURL>$PublishParameters</SimpleNetworkingURL>"} | Set-Content $BrightAuthorDir\UserPreferences.xml -Encoding UTF8
        $prefs = Get-Content $BrightAuthorDir\UserPreferences.xml
    }
    if ($line.Contains("<PublishTarget>")) {
        $prefs | ForEach-Object {$_ -replace "$line","    <PublishTarget>simpleNetworking</PublishTarget>"} | Set-Content $BrightAuthorDir\UserPreferences.xml -Encoding UTF8
        $prefs = Get-Content $BrightAuthorDir\UserPreferences.xml
    }
        
    if ($line.Contains("<EnableBonjour>True</EnableBonjour>")) {
        $prefs | ForEach-Object {$_ -replace "$line","    <EnableBonjour>False</EnableBonjour>"} | Set-Content $BrightAuthorDir\UserPreferences.xml -Encoding UTF8
        $prefs = Get-Content $BrightAuthorDir\UserPreferences.xml
    }

    if ($line.Contains("<DisplayMinimumFWVersionWarning>True</DisplayMinimumFWVersionWarning>")) {
        $prefs | ForEach-Object {$_ -replace "$line","    <DisplayMinimumFWVersionWarning>False</DisplayMinimumFWVersionWarning>"} | Set-Content $BrightAuthorDir\UserPreferences.xml -Encoding UTF8
        $prefs = Get-Content $BrightAuthorDir\UserPreferences.xml
    }         
}

if(!(Test-Path -Path "HKCU:\Software\BrightSign\BrightAuthor")) {
    New-Item -Path "HKCU:\Software\BrightSign\BrightAuthor" -Force
    Set-ItemProperty -Path "HKCU:\Software\BrightSign\BrightAuthor" -Name "PresentationsSFN" -Value "$PublishFolder" -Force
    Set-ItemProperty -Path "HKCU:\Software\BrightSign\BrightAuthor" -Name "Presentations" -Value "$PublishFolder" -Force
}


$workbook.Close()
$excel.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel)

#$time = Get-Date
#New-Item -Path "$env:USERPROFILE\" -Name "test.txt" -ItemType File -Force -Value "$time,`n $BrightAuthorDir,`n $latestversion"

#[System.GC]::Collect()
#[System.GC]::WaitForPendingFinalizers()