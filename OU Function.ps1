[string]$sourceOU = 'OU=Workstations,DC=monmouth,DC=edu'
[string]$destinationOU = 'OU=Test,OU=Labs,DC=monmouth,DC=edu'
[string]$exclude = 'Test'
[bool]$rename = $true

function rename($rename) {
    if($rename) {
        $oldName = Read-Host "Enter fully qualified name of the OU you wish to rename in the copy process. Example: OU=Information Management,$sourceOU"
        $newName = Read-Host "Enter the new name for this OU. Example: 'Max's New OU'   <--- This will be created in $destinationOU... like so: OU=Max's New OU,$desintationOU."
        $prompt = Read-Host "Rename another OU? Type y or n"
            if($prompt -eq 'y') {
                $rename = $true
            } else {
                $rename = $false
            }
        $renameObj = New-Object -TypeName PSObject -Property @{
            oldName = $oldName
            newName = $newName
        }

        $renameList.Add($renameObj)

    }
    rename($rename)
}

function CopyOUs($sourceOU,$destinationOU,$exclude,$rename) {
    
    [System.Collections.ArrayList]$OUs = @()
    [System.Collections.ArrayList]$AcademicOUs = @()
    [System.Collections.ArrayList]$StaffOUs = @()
    [System.Collections.ArrayList]$SplitOUs = @()
    [System.Collections.ArrayList]$renameList = @()
    $source = = Get-ADOrganizationalUnit -Filter '*' -SearchBase $sourceOU -SearchScope Subtree | Where-Object {($_.distinguishedName -notlike "*$exclude*")} | Select-Object DistinguishedName

    #$workstationsOUs = Get-ADOrganizationalUnit -Filter '*' -SearchBase 'OU=Workstations,DC=monmouth,DC=edu' -SearchScope Subtree | Where-Object {($_.distinguishedName -notlike '*Test*')} | Select-Object DistinguishedName
    
    rename($rename)


    foreach($OU in $source) {
        $OU = $OU.DistinguishedName.ToString()
    
        if($OU -like "*\*") {
            $OU = $OU.Replace("\,","\")
        }
        $numLevels = $OU.Split(",") | Measure-Object | Select-Object Count
        $SplitOUs = ($OU.Split(","))

        $finalOU = ($OU.Split(","))[0]
        $parentOU = [system.String]::Join(",", ($SplitOUs)[1..($numLevels.Count -4)])

        if(($OU -like "*\*") -or ($finalOU -like "*\*")) {
            $OU = $OU.Replace("\",",")
            $finalOU = $finalOU.Replace("\",",")
        }
        
        if($renameList -gt 0) {
            if($OU -like '*OU=Academic,*') {
                #$OU = $OU.Replace('OU=Academic,','OU=Monmouth PCs,')
                $OUobj = New-Object -TypeName PSObject -Property @{   
                    OU = $OU    
                    Levels = $numLevels.Count
                    Designation = "Academic"
                    #newOU = $OU.Replace('OU=Academic,OU=Workstations,DC=monmouth,DC=edu','OU=Monmouth PCs')
                    finalOU = $finalOU
                    oldParentOU = $parentOU
                    newParentOU = $parentOU.Replace('OU=Academic','OU=Test')
                }
        
            }
        }
        #if($OU -like '*OU=Academic,*') {
        #    #$OU = $OU.Replace('OU=Academic,','OU=Monmouth PCs,')
        #    $OUobj = New-Object -TypeName PSObject -Property @{   
        #        OU = $OU    
        #        Levels = $numLevels.Count
        #        Designation = "Academic"
        #        #newOU = $OU.Replace('OU=Academic,OU=Workstations,DC=monmouth,DC=edu','OU=Monmouth PCs')
        #        finalOU = $finalOU
        #        oldParentOU = $parentOU
        #        newParentOU = $parentOU.Replace('OU=Academic','OU=Test')
        #    }
       # 
        #} else {
        #    #$OU = $OU.Replace('OU=Staff,','OU=Monmouth PCs,')
        #    $OUobj = New-Object -TypeName PSObject -Property @{   
        #        OU = $OU    
        #        Levels = $numLevels.Count
        #        Designation = "Staff"
        #        #newOU = $OU.Replace('OU=Staff,OU=Workstations,DC=monmouth,DC=edu','OU=Monmouth PCs')
        #        finalOU = $finalOU
        #        oldParentOU = $parentOU
        #        newParentOU = $parentOU.Replace('OU=Staff','OU=Test')
        #    }
        #
        #}
        $OUs.Add($OUobj) | Out-Null
    

        #$OU = $OU.Replace(',OU=Workstations,DC=monmouth,DC=edu','')
    #    $newOUs.Add($OU)
       # $newOU = 
    }
    #$OUs | Where-Object {$_.Levels -gt 4} | Sort-Object -Property Levels | Out-GridView
    $FilteredOUs = $OUs | Where-Object {($_.Levels -gt 4)} | Sort-Object -Property Levels
    $FilteredOUs | Out-GridView
    #$newOrgUnit = "OU=Test"
    $TestPath = "OU=Test,OU=Labs,DC=monmouth,DC=edu"
    if(!([adsi]::Exists("LDAP://$TestPath"))) {
        New-ADOrganizationalUnit -Name "Test" -Path "OU=Labs,DC=monmouth,DC=edu" -ProtectedFromAccidentalDeletion $false -Verbose
    }
    for($i = 0; $i -lt $FilteredOUs.Count; $i++) {
        $finalOU = $FilteredOUs[$i].finalOU.replace("OU=","")
        $parentOU = $FilteredOUs[$i].newParentOU
        New-ADOrganizationalUnit -Name "$finalOU" -Path "$parentOU,OU=Labs,DC=monmouth,DC=edu" -ProtectedFromAccidentalDeletion $false
        Write-Host "-Name '$finalOU' -Path '$parentOU,OU=Labs,DC=monmouth,DC=edu'"
}


}

