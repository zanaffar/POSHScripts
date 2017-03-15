$workstationsOUs = Get-ADOrganizationalUnit -Filter '*' -SearchBase 'OU=Workstations,DC=monmouth,DC=edu' -SearchScope Subtree | Where-Object {($_.distinguishedName -notlike '*Test*')} | Select-Object DistinguishedName
[System.Collections.ArrayList]$OUs = @()
[System.Collections.ArrayList]$AcademicOUs = @()
[System.Collections.ArrayList]$StaffOUs = @()
[System.Collections.ArrayList]$SplitOUs = @()

foreach($OU in $workstationsOUs) {
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
    $finalOUStr = $finalOU.Remove(0,3)

    if($OU -like '*OU=Academic,*') {
        #$OU = $OU.Replace('OU=Academic,','OU=Monmouth PCs,')
        $OUobj = New-Object -TypeName PSObject -Property @{   
            OU = $OU    
            Levels = $numLevels.Count
            Designation = "Academic"
            #newOU = $OU.Replace('OU=Academic,OU=Workstations,DC=monmouth,DC=edu','OU=Monmouth PCs')
            finalOU = $finalOU
            oldParentOU = $parentOU
            Nested = ($numLevels.Count - 4)
            String = "            <DataItem>`n              <Setter Property=`"DisplayName`">$finalOUstr</Setter>`n              <Setter Property=`"OU`">$OU</Setter>`n            </DataItem>`n"
        }
        
    } else {
        #$OU = $OU.Replace('OU=Staff,','OU=Monmouth PCs,')
        $OUobj = New-Object -TypeName PSObject -Property @{   
            OU = $OU    
            Levels = $numLevels.Count
            Designation = "Staff"
            #newOU = $OU.Replace('OU=Staff,OU=Workstations,DC=monmouth,DC=edu','OU=Monmouth PCs')
            finalOU = $finalOU
            oldParentOU = $parentOU
            Nested = ($numLevels.Count - 4)
            String = "            <DataItem>`n              <Setter Property=`"DisplayName`">$finalOUstr</Setter>`n              <Setter Property=`"OU`">$OU</Setter>`n            </DataItem>`n"
        }
        
    }
    $OUs.Add($OUobj) | Out-Null
    

    #$OU = $OU.Replace(',OU=Workstations,DC=monmouth,DC=edu','')
#    $newOUs.Add($OU)
   # $newOU = 
}

$OUs = $OUs | Sort-Object 
foreach($OU in $OUs) {
    
}

#$OUs.String | Set-Content -Path "C:\Users\mbado\Desktop\OU.xml"