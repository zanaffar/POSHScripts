[System.Collections.ArrayList]$MachineObjList = @()


$UserName = 'monmouth0\\mbado'


$UserAffinity = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "select * from SMS_UserMachineRelationship where SMS_UserMachineRelationship.UniqueUserName = '`"`"'"

foreach($Machine in $UserAffinity) {
    
    $PrimaryDevice = $null

    if($Machine.Types -eq "1"){
        $PrimaryDevice = $true
    }

    $MachineObj = New-Object -TypeName PSObject -Property @{   
        UserName = $Machine.UniqueUserName
        MachineName = $Machine.ResourceName
        Sources = $Machine.sources
        PrimaryDevice = $PrimaryDevice
            
    }
    $MachineObjList.Add($MachineObj)
    
}

$MachineObjList | Out-GridView
#>

<#
## Max ##
$mymachines = @("MU56273","MU56294","HV56273W10","HV56273")
$mymachine1 = "MU56273"
$mymachine2 = "MU56294"
$mymachine3 = "HV56273W10"
$mymachine4 = "HV56273"

$comp1 = "IM202-WW53866"
$comp2 = "MU57517"

$query = "Select * From SMS_UserMachineRelationship
Where SMS_UserMachineRelationship.UniqueUserName = ""$UserName""
and SMS_UserMachineRelationship.Types = '1' 
and SMS_UserMachineRelationship.ResourceName != ""$mymachine1""
and SMS_UserMachineRelationship.ResourceName != ""$mymachine2""
and SMS_UserMachineRelationship.ResourceName != ""$mymachine3""
and SMS_UserMachineRelationship.ResourceName != ""$mymachine4""
"

$x = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "$query"

$x | ForEach-Object { Invoke-CimMethod -InputObject $_ -MethodName "RemoveType" -Arguments @{ TypeID = "1" }}
#>

<#
## Mick ##
$mymachine1 = "MU50672"
$mymachine2 = "MU53088-VM"

$query = "Select * From SMS_UserMachineRelationship
Where SMS_UserMachineRelationship.UniqueUserName = ""$UserName""
and SMS_UserMachineRelationship.Types = '1' 
and SMS_UserMachineRelationship.ResourceName != ""$mymachine1""
and SMS_UserMachineRelationship.ResourceName != ""$mymachine2""
"

$x = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "$query"

$x | ForEach-Object { Invoke-CimMethod -InputObject $_ -MethodName "RemoveType" -Arguments @{ TypeID = "1" }}
#>

<#
## Sue ##
$mymachine1 = "MU51751"

$query = "Select * From SMS_UserMachineRelationship
Where SMS_UserMachineRelationship.UniqueUserName = ""$UserName""
and SMS_UserMachineRelationship.Types = '1' 
and SMS_UserMachineRelationship.ResourceName != ""$mymachine1""
"

$x = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "$query"

$x | ForEach-Object { Invoke-CimMethod -InputObject $_ -MethodName "RemoveType" -Arguments @{ TypeID = "1" }}
#>

<#
## Billy ##
$mymachine1 = "MU52074"
$mymachine2 = "MU55670"
$mymachine3 = "MU51428"

$query = "Select * From SMS_UserMachineRelationship
Where SMS_UserMachineRelationship.UniqueUserName = ""$UserName""
and SMS_UserMachineRelationship.Types = '1' 
and SMS_UserMachineRelationship.ResourceName != ""$mymachine1""
and SMS_UserMachineRelationship.ResourceName != ""$mymachine2""
and SMS_UserMachineRelationship.ResourceName != ""$mymachine3""
"

$x = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "$query"

$x | ForEach-Object { Invoke-CimMethod -InputObject $_ -MethodName "RemoveType" -Arguments @{ TypeID = "1" }}
#>

