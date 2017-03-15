[System.Management.ManagementScope]$scope = [System.Management.ManagementScope]::new("\\wlb-sysctr-02\root\sms\site_mu1")

## Release Lock ##
[System.Management.ManagementPath]$path = [System.Management.ManagementPath]::new("SMS_ObjectLock")
[wmiclass]$objectLock = [wmiclass]::new($scope, $path, $null)

[System.Management.ManagementBaseObject]$inParams = $objectLock.GetMethodParameters("ReleaseLock")
$inParams["ObjectRelPath"] = "SMS_Application.CI_ID=17039588"

[System.Management.InvokeMethodOptions]$options = [System.Management.InvokeMethodOptions]::new()
$options.Context.Add("ObjectLockContext", $guid)
$options.Context.Add("MachineName", "$env:COMPUTERNAME")

[System.Management.ManagementBaseObject]$result = $objectLock.InvokeMethod("ReleaseLock", $inParams, $options)
$objectLock.GetLockInformation("SMS_Application.CI_ID=17039588")

#$result

#834c86e6-31a8-4f35-8ce0-eb8893f28e2e

#Example 1
$ObjectRELPath = "SMS_Application.CI_ID=16777312"
$AssignedObjectLockContext = "15bbe22a-4420-4475-932d-6739ea4de4b0"

$WMIConnection = [WMIClass]"\\Server100\root\SMS\Site_PRI:SMS_ObjectLock"
    $ObjectLock = $WMIConnection.psbase.GetMethodParameters("ReleaseLock")
    $ObjectLock.ObjectRelPath = $ObjectRELPath

    $MethodOption = New-Object System.Management.InvokeMethodOptions
    $MethodOption.Context.Add("ObjectLockContext",$AssignedObjectLockContext)
    $MethodOption.Context.Add("MachineName",$ENV:ComputerName)
$WMIConnection.psbase.InvokeMethod("ReleaseLock",$ObjectLock,$MethodOption)


#Example 2
Function Disable-ObjectLock
{
    [CmdLetBinding()]
    Param(
    [Parameter(Mandatory=$True,HelpMessage="Please Enter Site Server Site code")]
              $SiteCode,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter Site Server Name")]
              $SiteServer,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter Object REL path")]
              $ObjectRELPath,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter Object Lock Context value")]
              $AssignedObjectLockContext
         )
    Try{
        $WMIConnection = [WMIClass]"\\$SiteServer\root\SMS\Site_$($SiteCode):SMS_ObjectLock"
            $ObjectLock = $WMIConnection.psbase.GetMethodParameters("ReleaseLock")
            $ObjectLock.ObjectRelPath = $ObjectRELPath

            $MethodOption = New-Object System.Management.InvokeMethodOptions
            $MethodOption.Context.Add("ObjectLockContext",$AssignedObjectLockContext)
            $MethodOption.Context.Add("MachineName",$ENV:ComputerName)
        $WMIConnection.psbase.InvokeMethod("ReleaseLock",$ObjectLock,$MethodOption)
    }
    Catch{
        $_.Exception.Message
    }
}
Disable-ObjectLock -SiteCode PRI -SiteServer Server100 -ObjectRELPath "SMS_Application.CI_ID=16777312" -AssignedObjectLockContext "b5483314-5c52-4cd8-bf56-c0dce1dc99fa"