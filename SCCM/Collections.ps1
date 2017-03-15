#809C8298-306A-4B15-8C13-E87F6547F137
#16777217

#$SWD_Collections = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -ClassName SMS_ObjectContainerItem | Where-Object {$_.ContainerNodeID -eq "16777217"}

#foreach ($SWD_Collection in $SWD_Collections) {
#    $InstanceKey = $SWD_Collection.InstanceKey
#    Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -ClassName SMS_Collection | Where-Object {$_.CollectionID -eq $InstanceKey}
#}
[System.Collections.ArrayList]$ColObjList = @()

$ColName = "SWD_SharePointDesigner2010_Install*"

$SWD_Collections = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -ClassName SMS_Collection | Where-Object {$_.Name -like $ColName -and $_.LocalMemberCount -lt 970} | Select-Object CollectionID,Name,LocalMemberCount,LastMemberChangeTime
#$SWD_Collections | Out-GridView


foreach ($Collection in $SWD_Collections) {
    $ColMembersObj = New-Object -TypeName PSObject -Property @{   
        CollectionID = $Collection.CollectionID
        Name = $Collection.Name
        MemberCount = $Collection.LocalMemberCount
        Members = (Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -ClassName SMS_FullCollectionMembership -Filter "CollectionID='$($Collection.CollectionID)'" | Select-Object Name).Name
    }
    $ColObjList.Add($ColMembersObj) | Out-Null
}

$ColObjList | Out-GridView