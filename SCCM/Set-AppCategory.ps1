## Add App Categories ##
$x = Get-CMApplication -Name 'Adobe Presenter 7.0.7'
$y = $x.LocalizedCategoryInstanceNames
$y += "Pre-Approved"
Set-CMApplication -InputObject $x -AppCategory $y -Verbose