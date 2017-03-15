#Example 1
$ObjectRELPath = "SMS_Application.CI_ID=16777312"
$WMIConnection = [WMIClass]"\\Server100\root\SMS\Site_MU1:SMS_ObjectLock"
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