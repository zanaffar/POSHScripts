[CmdletBinding()]
Param(
      #The target domain
      [parameter(Position=1)]
      [ValidateScript({Get-ADDomain $_})] 
      [String]$Domain = "monmouth.edu"
      )

[System.Collections.ArrayList]$OUsCol = @()

#Craete a variable for the domain DN
$DomainDn = (Get-ADDomain -Identity $Domain).DistinguishedName

#Create user counter
$i = 0

$SearchBase = 'OU=Workstations,DC=monmouth,DC=edu'

#Get-ADOrganizationalUnit dumps the OU structure in a logical order (thank you cmdlet author!) 
$Ous = Get-ADOrganizationalUnit -Filter * -SearchBase $SearchBase -SearchScope Subtree -Server $Domain -Properties ParentGuid -ErrorAction SilentlyContinue | 
       Select Name,DistinguishedName,ParentGuid 

foreach ($Ou in $Ous){

    #Convert the parentGUID attribute (stored as a byte array) into a proper-job GUID
    $ParentGuid = ([GUID]$Ou.ParentGuid).Guid

    #Attempt to retrieve the object referenced by the parent GUID
    $ParentObject = Get-ADObject -Identity $ParentGuid -Server $Domain -ErrorAction SilentlyContinue
    
    $Ou.DistinguishedName = $OU.DistinguishedName.Replace("\,","\.")

    if ($ParentObject) {
        

        if($Ou.DistinguishedName -like '*OU=Staff,OU=Workstations,DC=monmouth,DC=edu') {
            $Designation = 'Staff'
        } elseif ($Ou.DistinguishedName -like '*OU=Academic,OU=Workstations,DC=monmouth,DC=edu') {
            $Designation = 'Academic'
        } else {
            $Designation = $null
        }

        if((($Ou.DistinguishedName.Split(',')).count) -ge '5'){
            $FirstLevelParent = $Ou.DistinguishedName.Split(',')[($Ou.DistinguishedName.Split(',')).count - 5]
        } else {
            $FirstLevelParent = $null
        }

        if(($Ou.DistinguishedName.Split(',')).count -ge '5') {
            $numLevels = ($Ou.DistinguishedName.Split(',')).count - 4
        } else {
            $numLevels = $null
        }

        $Ou.DistinguishedName = $OU.DistinguishedName.Replace("\.","\,")

        #Create a custom PS object
        $OuInfo = [PSCustomObject]@{

            Name = $Ou.Name
            DistinguishedName = $Ou.DistinguishedName
            Level = $numLevels
            Designation = $Designation
            ParentDn = $ParentObject.DistinguishedName
            FirstLevelParent = $FirstLevelParent
            DomainDn = $DomainDn
        
            }   #End of $Properties...


        #Add the object to our array
        #$TotalOus += $OuInfo

        #Spin up a progress bar for each filter processed
        Write-Progress -Activity "Finding OUs in $DomainDn" -Status "Processed: $i" -PercentComplete -1

        #Increment the filter counter
        $i++

    }   #End of if ($ParentObject)

    $OUsCol.Add($OuInfo) | Out-Null

}   #End of foreach ($Ou in $Ous)

$OUsCol | Out-GridView

$OUfile = 'C:\UI++\OUFile.txt'
New-Item -Path $OUfile -Force

Write-Output "<!-- Staff OUs -->`n" | Out-File -FilePath $OUfile -Append
foreach ($item in ($OUsCol | Where-Object {$_.Designation -eq 'Staff'} | Sort-Object -Property FirstLevelParent,Level,Name)) {
    $indent = $("`t" * $item.Level)
    
    $DistinguishedName = ($item.DistinguishedName).Replace('&','&amp;').Replace(',OU=Workstations,DC=monmouth,DC=edu','').Replace('\,','\.')
    $Split = $DistinguishedName.Replace('OU=','').Split(',')
    $DistinguishedName = $DistinguishedName.Replace('\.','\,')
    $Levels = $Split.count
    if($Levels -ge '2') {
        $Option = [system.String]::Join("\", ($Split)[($Levels - 2)..0])
    } else {
        $Option = $item.name
    }
    $Option = ($item.name).Replace('&','&amp;')
    $Value = $DistinguishedName

    Write-Output "$indent<Choice Option=`"$Option`" Value=`"$Value`" />" | Out-File -FilePath $OUfile -Append
}
Write-Output "`n<!-- End Staff OUs -->`n" | Out-File -FilePath $OUfile -Append


Write-Output "`n<!-- Academic OUs -->`n" | Out-File -FilePath $OUfile -Append
foreach ($item in ($OUsCol | Where-Object {$_.Designation -eq 'Academic'} | Sort-Object -Property FirstLevelParent,Level,Name)) {
    $indent = $("`t" * $item.Level)
    
    $DistinguishedName = ($item.DistinguishedName).Replace('&','&amp;').Replace(',OU=Workstations,DC=monmouth,DC=edu','').Replace('\,','\.')
    $Split = $DistinguishedName.Replace('OU=','').Split(',')
    $DistinguishedName = $DistinguishedName.Replace('\.','\,')
    $Levels = $Split.count
    if($Levels -ge '2') {
        $Option = [system.String]::Join("\", ($Split)[($Levels - 2)..0])
    } else {
        $Option = $item.name
    }
    $Option = ($item.name).Replace('&','&amp;')
    $Value = $DistinguishedName

    Write-Output "$indent<Choice Option=`"$Option`" Value=`"$Value`" />" | Out-File -FilePath $OUfile -Append
}
Write-Output "`n<!-- End Academic OUs -->`n" | Out-File -FilePath $OUfile -Append
