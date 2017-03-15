$SiteCode = "MU1"

$query = "SELECT SMS_Application.LocalizedDisplayName
FROM SMS_Application
join SMS_ObjectContainerItem
on SMS_Application.ModelName = SMS_ObjectContainerItem.InstanceKey
WHERE SMS_Application.LocalizedDisplayName = ""BeyondTrust PowerBroker Client for Windows 5.5.1"""

#where SMS_FullCollectionMembership.Name = ""$Member"""

$SMS_ObjectContainerItem = Get-WMIObject -ComputerName wlb-sysctr-02 -Namespace "root\sms\site_$SiteCode" -Class SMS_ObjectContainerItem #| Select-Object -Property ContainerNodeID,MemberID,ObjectTypeName
$SMS_ObjectContainerNode = Get-WMIObject -ComputerName wlb-sysctr-02 -Namespace "root\sms\site_$SiteCode" -Class SMS_ObjectContainerNode #| Select-Object -Property ContainerNodeID,Name,ObjectTypeName,ParentContainerNodeID
#$apps = Get-WmiObject -ComputerName wlb-sysctr-02 -Namespace "root\sms\site_$SiteCode" -Query 'SELECT * FROM SMS_Application WHERE SMS_Application.IsEnabled = "True" AND SMS_Application.IsExpired = "False" AND SMS_Application.IsLatest = "True"' | Select-Object -Property LocalizedDisplayName,Manufacturer,ModelName
$apps = Get-WmiObject -ComputerName wlb-sysctr-02 -Namespace "root\sms\site_$SiteCode" -Query 'SELECT * FROM SMS_Application' | Select-Object -Property LocalizedDisplayName,Manufacturer,ModelName

$Collections = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "select SMS_Collection.CollectionID,SMS_Collection.Name from SMS_Collection join SMS_FullCollectionMembership on SMS_Collection.CollectionID = SMS_FullCollectionMembership.CollectionID where SMS_FullCollectionMembership.Name = ""$Member""" | Select-Object CollectionID,Name

<#
$ColID = "MU1000EB"
$Members = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "Select SMS_FullCollectionMembership.Name from SMS_FullCollectionMembership where SMS_FullCollectionMembership.CollectionID = ""$ColID""" | Select-Object Name | Sort-Object Name


foreach($Member in $Members){
$Member = $Member.Name
$query = "select SMS_Collection.CollectionID,SMS_Collection.Name
from SMS_Collection
join SMS_FullCollectionMembership
on SMS_Collection.CollectionID = SMS_FullCollectionMembership.CollectionID
where SMS_FullCollectionMembership.Name = ""$Member"""

Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace "root\sms\site_$SiteCode" -Query $query
}
#>
$filter = "ParentContainerNodeId = $FolderNodeId"
$filter += " And ObjectTypeName = 'SMS_ApplicationLatest'"

$folders = Get-WMIObject -ComputerName wlb-sysctr-02 -Namespace "root\sms\site_$SiteCode" -Class SMS_ObjectContainerNode | Select-Object -Property ContainerNodeID,Name,ObjectTypeName,ParentContainerNodeID

foreach($folder in $folders){
    $
}

$apps = Get-WmiObject -ComputerName wlb-sysctr-02 -Namespace "root\sms\site_$SiteCode" -Query 'SELECT * FROM SMS_Application WHERE SMS_Application.IsEnabled = "True" AND SMS_Application.IsExpired = "False"'