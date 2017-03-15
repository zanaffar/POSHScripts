function Get-WMINamespace($namespace) 
{
    $names = Get-WmiObject -Namespace $namespace -Class "__Namespace" |  Where-Object {($_.name -ne 'directory') -and ($_.name -ne 'Symantec') -and ($_.name -ne 'Microsoft') -and ($_.name -ne 'virtualization') -and ($_.name -ne 'HP') -and ($_.name -ne 'HyperVCluster') -and ($_.name -ne 'RSOP') } | Select Name

    if(!($names)) {
        Write-Host "----------end of tree----------"
    } else {
        
        foreach ($name in $names) {
            
            
            $counter = 0
            $namespace_old = $namespace
            
            $name = $name.name
            $namespace_current = "$namespace_old\$name"
            Write-Host "$namespace_current"

            Write-Host "*******"
            Get-WmiObject -Namespace "$namespace_current" -List
            Write-Host "*******"
            $namespace_new = "$namespace\$name"

            Get-WMINamespace($namespace_new)
            
        }
    }

#        if($name -ne $null) {
 #           $namespace = "$namespace\$name"  
  #          Get-WMINamespace($namespace)          
   #     } else {
    #        Get-WMINamespace($namespace)
     #       }
     
     #   }
}

Get-WMINamespace("ROOT")

# Get-WmiObject -Namespace "root" -Class "__Namespace" | Select Name | foreach {

#    $name = $_.name
#    Write-Host "root\$name"

#    Get-WmiObject -Namespace "root\$name" -Class "__Namespace" | Select Name | foreach {
        
#        $name2 = $_.name
#        Write-Host "root\$name\$name2"

#        Get-WmiObject -Namespace "root\$name\$name2" -Class "__Namespace" | Select Name | foreach {
        
#            $name3 = $_.name
#            Write-Host "root\$name\$name2\$name3"
#            }
#        }    
#}