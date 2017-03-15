[System.Collections.ArrayList]$ColObjList = @()

$Device = "MU56273"

$DeviceMembership = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -ClassName SMS_FullCollectionMembership -Filter "Name='$($Device)'" 
#$DeviceMembership | Out-GridView

foreach($Collection in $DeviceMembership) {
    $ColMembersObj = New-Object -TypeName PSObject -Property @{   
        DeviceName = $Collection.Name
        Collection = (Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -ClassName SMS_Collection -Filter "CollectionID='$($Collection.CollectionID)'" | Select-Object Name).Name
    }
    if ($ColMembersObj.Collection -like "SWD*") {
        $ColObjList.Add($ColMembersObj) | Out-Null
    }
}

$ColObjList | Out-GridView