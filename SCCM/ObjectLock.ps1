#ManagementScope scope = new ManagementScope(\\siteservername\root\sms\site_ABC)
[System.Management.ManagementScope]$scope = [System.Management.ManagementScope]::new("\\wlb-sysctr-02\root\sms\site_mu1")
#RequestLock(scope)


[System.Management.ManagementPath]$path = [System.Management.ManagementPath]::new("SMS_ObjectLock")
[wmiclass]$objectLock = [wmiclass]::new($scope, $path, $null)

[System.Management.ManagementBaseObject]$inParams = $objectLock.GetMethodParameters("RequestLock")
$inParams["ObjectRelPath"] = "SMS_Application.CI_ID=17039588"
$inParams["RequestTransfer"] = $true

[System.Management.InvokeMethodOptions]$options = [System.Management.InvokeMethodOptions]::new()
$options.Context.Add("ObjectLockContext", [guid]::NewGuid().ToString())
$options.Context.Add("MachineName", "RequestingComputer")

[System.Management.ManagementBaseObject]$result = $objectLock.InvokeMethod("RequestLock", $inParams, $options)

#RequestLock($scope)

<#
Function RequestLock ($scope) 
     {
         #ManagementPath path = new ManagementPath("SMS_ObjectLock");
         [System.Management.ManagementPath]$path = [System.Management.ManagementPath]::new("SMS_ObjectLock")
         #ManagementClass objectLock = new ManagementClass(scope, path, null); 
         [wmiclass]$objectLock = [wmiclass]::new($scope, $path, $null)
         #Get-WmiObject -ComputerName wlb-sysctr-02 -Namespace root\sms\site_MU1 -Class SMS_ObjectLock
         
         #ManagementBaseObject inParams = objectLock.GetMethodParameters("RequestLock");
         #inParams["ObjectRelPath"] = "SMS_ConfigurationItem.CI_ID=30";
         #inParams["RequestTransfer"] = true; 

         [System.Management.ManagementBaseObject]$inParams = $objectLock.GetMethodParameters("RequestLock")
         $inParams["ObjectRelPath"] = "SMS_Application.CI_ID=17039588"
         $inParams["RequestTransfer"] = $true

         #InvokeMethodOptions options = new InvokeMethodOptions();
         #options.Context.Add("ObjectLockContext", Guid.NewGuid().ToString());
         #options.Context.Add("MachineName", "RequestingComputer");

         [System.Management.InvokeMethodOptions]$options
         $options.Context.Add("ObjectLockContext", [guid]::NewGuid().ToString())
         $options.Context.Add("MachineName", "RequestingComputer")

         #ManagementBaseObject result = objectLock.InvokeMethod("RequestLock", inParams, options);   
         [System.Management.ManagementBaseObject]$result = $objectLock.InvokeMethod("RequestLock", $inParams, $options)
     }
     #>