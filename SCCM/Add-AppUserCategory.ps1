
Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" # Import the ConfigurationManager.psd1 module 
Set-Location "MU1:" # Set the current location to be the site code.

$site = 'MU1'
$server = 'wlb-sysctr-02'

## Get Collection ID ##
$collID = (Get-CMCollection -Name 'SWUG_PreApproved_Install').CollectionID

## Get Applications in Deployments in Collection ##
$apps = (Get-CMDeployment -CollectionName 'SWUG_PreApproved_Install').SoftwareName

## Process each App, enumerate User Categories, and add new category ##

foreach($app in $apps) {
    $application = Get-CMApplication -Name $app
    $xml = [xml]$application.SDMPackageXML
    $categories = $xml.AppMgmtDigest.Application.DisplayInfo.Info.UserCategories.Tag
    $category_names = @()

    foreach($category in $categories) {
    
        $category_name = (Get-CimInstance -ComputerName $server -Namespace "root\SMS\site_$site" -Query "SELECT LocalizedCategoryInstanceName FROM SMS_CategoryInstance WHERE SMS_CategoryInstance.CategoryInstance_UniqueID = '$category'").LocalizedCategoryInstanceName
        $category_names += $category_name

    }

    $category_names += 'Pre-Approved'

    Set-CMApplication -InputObject $application -UserCategory $category_names -Verbose
}


<#
## Add Admin Categories to App ##
$x = Get-CMApplication -Name 'Adobe Presenter 7.0.7'
$y = $x.LocalizedCategoryInstanceNames
$y += "Pre-Approved"
Set-CMApplication -InputObject $x -AppCategory $y -Verbose
#>