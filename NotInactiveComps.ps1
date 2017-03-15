## Get list of computers NOT inactive for X days
$comps = Get-ADComputer -Filter 'Name -like "*"' -SearchBase "OU=Computer Support,OU=Information Support,OU=Information Management,OU=Staff,OU=Workstations,DC=monmouth,DC=edu"
$inactivecomps = Search-ADAccount -SearchBase "OU=Computer Support,OU=Information Support,OU=Information Management,OU=Staff,OU=Workstations,DC=monmouth,DC=edu" -AccountInactive -TimeSpan 10

$active = @()

foreach($comp in $comps){
    Write-Output "Working on $($comp.name)"
    if($($comp.name) -notin $($inactivecomps.name)) { 
        $active += $comp 
    }
}