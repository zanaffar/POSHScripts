[System.Management.ManagementScope]$scope = [System.Management.ManagementScope]::new("\\wlb-sysctr-02\root\sms\site_mu1")

## Request Lock ##
[System.Management.ManagementPath]$path = [System.Management.ManagementPath]::new("SMS_ObjectLock")
[wmiclass]$objectLock = [wmiclass]::new($scope, $path, $null)

[System.Management.ManagementBaseObject]$inParams = $objectLock.GetMethodParameters("RequestLock")
$inParams["ObjectRelPath"] = "SMS_Application.CI_ID=16947730"
$inParams["RequestTransfer"] = $true

[System.Management.InvokeMethodOptions]$options = [System.Management.InvokeMethodOptions]::new()
$guid = [guid]::NewGuid().ToString()
$options.Context.Add("ObjectLockContext", $guid)
$options.Context.Add("MachineName", "$env:COMPUTERNAME")

[System.Management.ManagementBaseObject]$result = $objectLock.InvokeMethod("RequestLock", $inParams, $options)
$objectLock.GetLockInformation("SMS_Application.CI_ID=16947730")


#Example 1
$ObjectRELPath = "SMS_Application.CI_ID=16777312"
$WMIConnection = [WMIClass]"\\Server100\root\SMS\Site_PRI:SMS_ObjectLock"
    $ObjectLock = $WMIConnection.psbase.GetMethodParameters("GetLockInformation")
    $ObjectLock.ObjectRelPath = $ObjectRELPath
$WMIConnection.psbase.InvokeMethod("GetLockInformation",$ObjectLock,$null)

#Example 2
Function Get-ObjectLock
{
    [CmdLetBinding()]
    Param(
    [Parameter(Mandatory=$True,HelpMessage="Please Enter Site Server Site code")]
              $SiteCode,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter Site Server Name")]
              $SiteServer,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter Object REL path")]
              $ObjectRELPath
         )
    Try{
        $WMIConnection = [WMIClass]"\\$SiteServer\root\SMS\Site_$($SiteCode):SMS_ObjectLock"
            $ObjectLock = $WMIConnection.psbase.GetMethodParameters("GetLockInformation")
            $ObjectLock.ObjectRelPath = $ObjectRELPath
        $WMIConnection.psbase.InvokeMethod("GetLockInformation",$ObjectLock,$null)           
    }
    Catch{
        $_.Exception.Message
    }
}
Get-ObjectLock -SiteCode PRI -SiteServer Server100 -ObjectRELPath "SMS_Application.CI_ID=16777312"