[System.Collections.ArrayList]$AppObjList = @()

$ColID = "MU1000EB"
$ColName = "User Self Service Test"
$LocalDispName = "Acrobat DC PSAppDeploy"

## Get Applications within a Collection
$Apps = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "select * from SMS_DeploymentSummary where SMS_DeploymentSummary.CollectionName = ""$ColName"""

foreach($App in $Apps) {
    $AssignmentID = $App.AssignmentID
    $AppName = $app.ApplicationName
    if(Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "select * from SMS_ApplicationAssignment where SMS_ApplicationAssignment.AssignmentID = ""$AssignmentID""") {
        $AppAssignment = Get-CimInstance -ComputerName wlb-sysctr-02 -Namespace root\SMS\site_MU1 -Query "select * from SMS_ApplicationAssignment where SMS_ApplicationAssignment.AssignmentID = ""$AssignmentID"""
        
        # Set-CimInstance -InputObject $x -Property @{NotifyUser="False"}

        $AppObj = New-Object -TypeName PSObject -Property @{   
            ApplicationName = $AppAssignment.ApplicationName
            NotifyUser = $AppAssignment.NotifyUser
            
        }
        $AppObjList.Add($AppObj)
    }
}

