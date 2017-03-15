$complist = @('MU52109','mu52211','mu52213')

foreach ($comp in $complist){
$group = 'HelpDesk Loaner Laptops'
$adcomp = Get-ADComputer -Identity $comp
Add-ADGroupMember -Identity $group -Members $adcomp
Move-ADObject -Identity $adcomp -TargetPath 'OU=HelpDesk Loaner Laptops,OU=HelpDesk,OU=Information Support,OU=Information Management,OU=Staff,OU=Workstations,DC=monmouth,DC=edu'
}