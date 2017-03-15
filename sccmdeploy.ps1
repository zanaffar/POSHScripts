<#
took some input for this script from http://blogs.msdn.com/b/one_line_of_code_at_a_time/archive/2012/01/17/microsoft-system-center-configuration-manager-2012-package-conversion-manager-plugin.aspx
This script can change some basic settings for ConfigMgr 2012 Applications or their DeploymentTypes.
In this version I can set some basic stuff regarding content behaviour.
You can, as an alternative, always try the Set-CMDeploymentType, but that one has a bug regarding the Fallback to unprotected DPs.
#>
param(
[string]$SiteCode="MU1",
[string]$MPServer="wlb-sysctr-02",
[string]$ApplicationName="Adobe Acrobat 11.0.11"
)
function Get-ExecuteWqlQuery($siteServerName, $query)
{
  $returnValue = $null
  $connectionManager = new-object Microsoft.ConfigurationManagement.ManagementProvider.WqlQueryEngine.WqlConnectionManager
  if($connectionManager.Connect($siteServerName))
  {
      $result = $connectionManager.QueryProcessor.ExecuteQuery($query)
      foreach($i in $result.GetEnumerator())
      {
        $returnValue = $i
        break
      }
      $connectionManager.Dispose()
  }
  $returnValue
}
function Get-ApplicationObjectFromServer($appName,$siteServerName)
{
    $resultObject = Get-ExecuteWqlQuery $siteServerName "select thissitecode from sms_identification"
    $siteCode = $resultObject["thissitecode"].StringValue
    $path = [string]::Format("\\{0}\ROOT\sms\site_{1}", $siteServerName, $siteCode)
    $scope = new-object System.Management.ManagementScope -ArgumentList $path
    $query = [string]::Format("select * from sms_application where LocalizedDisplayName='{0}' AND ISLatest='true'", $appName.Trim())
    $oQuery = new-object System.Management.ObjectQuery -ArgumentList $query
    $obectSearcher = new-object System.Management.ManagementObjectSearcher -ArgumentList $scope,$oQuery
    $applicationFoundInCollection = $obectSearcher.Get()
    $applicationFoundInCollectionEnumerator = $applicationFoundInCollection.GetEnumerator()
    if($applicationFoundInCollectionEnumerator.MoveNext())
    {
        $returnValue = $applicationFoundInCollectionEnumerator.Current
        $getResult = $returnValue.Get()
        $sdmPackageXml = $returnValue.Properties["SDMPackageXML"].Value.ToString()
        [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($sdmPackageXml)
    }
}
 function Load-ConfigMgrAssemblies()
 {
     $AdminConsoleDirectory = "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin"
     $filesToLoad = "Microsoft.ConfigurationManagement.ApplicationManagement.dll","AdminUI.WqlQueryEngine.dll", "AdminUI.DcmObjectWrapper.dll"
     Set-Location $AdminConsoleDirectory
     [System.IO.Directory]::SetCurrentDirectory($AdminConsoleDirectory)
      foreach($fileName in $filesToLoad)
      {
         $fullAssemblyName = [System.IO.Path]::Combine($AdminConsoleDirectory, $fileName)
         if([System.IO.File]::Exists($fullAssemblyName ))
         {
             $FileLoaded = [Reflection.Assembly]::LoadFrom($fullAssemblyName )
         }
         else
         {
              Write-Host ([System.String]::Format("File not found {0}",$fileName )) -backgroundcolor "red"
         }
      }
 }
Load-ConfigMgrAssemblies
$application = [wmi](Get-WmiObject SMS_Application -Namespace root\sms\site_$($SiteCode) |  where {($_.LocalizedDisplayName -eq "$($ApplicationName)") -and ($_.IsLatest)}).__PATH
$applicationXML = Get-ApplicationObjectFromServer "$($ApplicationName)" $MPServer
if ($applicationXML.DeploymentTypes -ne $null)
    {
        foreach ($a in $applicationXML.DeploymentTypes)
            {
                #change content properties
                $a.Installer.Contents[0].Location = "\\srv1\sources\Software\RE" # new UNC path to source location
                $a.Installer.Contents[0].FallbackToUnprotectedDP = $false #can be $true or $false
                $a.Installer.Contents[0].OnSlowNetwork = "DoNothing" # can be "Download" or "DoNothing"
                $a.Installer.Contents[0].PeerCache = $false # can be $true or $false
                $a.Installer.Contents[0].PinOnClient = $true #keep persistent on client, can be true or false
                #change basic DeploymentType properties
                #$a.Installer.InstallCommandLine = "msiexec /i `"RES-WM-2012.msi`"" #new commandline if you like
            }
    }
$newappxml = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::Serialize($applicationXML, $false)
$application.SDMPackageXML = $newappxml
$application.Put() | Out-Null