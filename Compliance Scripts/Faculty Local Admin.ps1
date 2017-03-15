$logfile = 'C:\compliance.log'

Write-Output "Enumerating User Device Affinity using WMI" | Out-File -FilePath $logfile -Append
$UDA_Users = (Get-CimInstance -Namespace 'root/ccm/Policy/Machine/ActualConfig' -ClassName 'CCM_UserAffinity').ConsoleUser
Write-Output "$UDA_Users" | Out-File -FilePath $logfile -Append

foreach($UDA_User in ($UDA_Users | Where-Object {($_ -notlike "$env:COMPUTERNAME\*")})) {
    Write-Output "Working on $UDA_User" | Out-File -FilePath $logfile -Append
    $Username = $UDA_User.split('\')[1]
    
    Write-Output "Searching monmouth.edu for $Username" | Out-File -FilePath $logfile -Append
    $User = Get-ADUser -Identity "$Username" -Server 'monmouth.edu' -ErrorAction SilentlyContinue | Where-Object {$_.DistinguishedName -like '*OU=Faculty,DC=monmouth,DC=edu'}

    if($User) {
        Write-Output "$Username is Faculty on monmouth.edu" | Out-File -FilePath $logfile -Append
        if((!($UDA_User -in (Get-LocalGroupMember -Group Administrators).Name))) {
            Write-Output "$UDA_User is not in the Administrators group. Return $false" | Out-File -FilePath $logfile -Append
            return $false
        } else { 
            Write-Output "$UDA_User is part of the Adminstrators group. Don't return anything." | Out-File -FilePath $logfile -Append
        }            
    } else {
        Write-Output "$Username is not Faculty on monmouth.edu." | Out-File -FilePath $logfile -Append

        Write-Output "Searching hawkdom2 for $Username" | Out-File -FilePath $logfile -Append
        $User = Get-ADUser -Identity "$Username" -Server 'hawkdom2' -ErrorAction SilentlyContinue | Where-Object {$_.DistinguishedName -like '*OU=Faculty,DC=hawkdom2,DC=monmouth,DC=edu'}

        if($User) {
            Write-Output "$Username is Faculty on hawkdom2" | Out-File -FilePath $logfile -Append
            if((!($UDA_User -in (Get-LocalGroupMember -Group Administrators).Name))) {
                Write-Output "$UDA_User is not in the Administrators group. Return $false" | Out-File -FilePath $logfile -Append
                return $false
            } else { 
                Write-Output "$UDA_User is part of the Adminstrators group. Don't return anything." | Out-File -FilePath $logfile -Append
            }
        } else {
            Write-Output "$Username is not Faculty on hawkdom2." | Out-File -FilePath $logfile -Append
        }
    } 
}
return $true
