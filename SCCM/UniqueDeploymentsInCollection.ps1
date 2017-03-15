[System.Collections.ArrayList]$ColObjList = @()
[System.Collections.ArrayList]$AppObjList = @()


$ColID = "MU1000EB"
$Members = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "Select SMS_FullCollectionMembership.Name from SMS_FullCollectionMembership where SMS_FullCollectionMembership.CollectionID = ""$ColID""" | Select-Object Name | Sort-Object Name

Foreach ($Member in $Members) {
    $Member = $Member.Name
    $Collections = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "select SMS_Collection.CollectionID,SMS_Collection.Name from SMS_Collection join SMS_FullCollectionMembership on SMS_Collection.CollectionID = SMS_FullCollectionMembership.CollectionID where SMS_FullCollectionMembership.Name = ""$Member""" | Select-Object CollectionID,Name
    $ColMembersObj = New-Object -TypeName PSObject -Property @{   
        MachineName = $Member
        Collections = $Collections.Name
        CollectionsID = $Collections.CollectionID
        }
    $ColObjList.Add($ColMembersObj) | Out-Null

}

$UniqueCollections = $ColObjList | Select-Object Collections -ExpandProperty Collections | Sort-Object -Unique

foreach ($Col in $UniqueCollections) {
    $Apps = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "select SMS_DeploymentInfo.TargetName from SMS_DeploymentInfo where SMS_DeploymentInfo.CollectionName = ""$Col""" | Select-Object TargetName
    $AppsMembersObj = New-Object -TypeName PSObject -Property @{   
        Collection = $Col
        Apps = $Apps.TargetName
    }
    $AppObjList.Add($AppsMembersObj) | Out-Null
}

$ExpandedApps = $AppObjList | Select-Object Apps -ExpandProperty Apps | Where-Object {($_ -notlike "Cumulative*") -and ($_ -notlike "Definition*") -and ($_ -notlike "Security*") -and ($_ -notlike "Update for*") -and ($_ -notlike "LABS*")} | Sort-Object -Unique
#$ExpandedApps | Where-Object {($_ -notlike "Cumulative*") -and ($_ -notlike "Definition*") -and ($_ -notlike "Security*") -and ($_ -notlike "Update for*") -and ($_ -notlike "LABS*")} | Sort-Object -Unique | Out-GridView
