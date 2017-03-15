#$names = Get-WmiObject -Namespace "root" -Class "__Namespace" |  Where-Object {($_.name -ne 'directory') -and ($_.name -ne 'Symantec') -and ($_.name -ne 'Microsoft') -and ($_.name -ne 'virtualization') -and ($_.name -ne 'HP') -and ($_.name -ne 'HyperVCluster') -and ($_.name -ne 'RSOP') } | Select Name


$names = Get-WmiObject -Namespace "root" -Class "__Namespace" |  Where-Object {$_.name -eq 'cimv2'} | Select Name
$names = $names.name

$classes = Get-WmiObject -Namespace "root\$names" -List

foreach ($class in $classes) {
    
    $a = Get-WmiObject -Class $class.name
    foreach ($b in $a) {
      #  if ($class.__Path -like '*Win32_PnPEntity*') {
      #      $class.__PATH
      #      $class.Properties.GetEnumerator()
      #  }
        if($b.Properties.GetEnumerator().value -like '*Intel(R) 8 Series/C220 Series  SMBus Controller - 8C22*') {
            $b | Out-File C:\users\mbado\Desktop\wmi.txt
        }
    }
}