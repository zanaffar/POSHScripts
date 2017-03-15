﻿<#
.Synopsis
   This script creates packages/Applications based on their name
.DESCRIPTION
.EXAMPLE
    Add-CMCollectionBasedOnPackageName.ps1 -SiteCode pr1 -SiteServer localhost -FolderName test1 -LimitingCollectionName "All Systems" -PackageType Package -DeviceCollection
.EXAMPLE
    Add-CMCollectionBasedOnPackageName.ps1 -SiteCode pr1 -SiteServer localhost -FolderName "test 2" -LimitingCollectionName "All Systems" -PackageType Application -DeviceCollection
.EXAMPLE
    Add-CMCollectionBasedOnPackageName.ps1 -SiteCode pr1 -SiteServer localhost -FolderName "test 2" -LimitingCollectionName "All Users" -PackageType Application -UserCollection
.EXAMPLE
    Add-CMCollectionBasedOnPackageName.ps1 -SiteCode pr1 -SiteServer localhost -FolderName "test 2" -LimitingCollectionName "RAM 2010" -PackageType Application -UserCollection
.NOTES
    Developed by Kaido Järvemets
    Version 1.0

#>
[CMDLETBINDING()]
Param(
    [Parameter(Mandatory=$True,HelpMessage="Please Enter CM SiteCode",ParameterSetName='DeviceCollection')]
    [Parameter(Mandatory=$True,HelpMessage="Please Enter CM SiteCode",ParameterSetName='UserCollection')]
        $SiteCode,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter CM Site Server",ParameterSetName='DeviceCollection')]
    [Parameter(Mandatory=$True,HelpMessage="Please Enter CM Site Server",ParameterSetName='UserCollection')]
        $SiteServer,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter CM Folder Name",ParameterSetName='DeviceCollection')]
    [Parameter(Mandatory=$True,HelpMessage="Please Enter CM Folder Name",ParameterSetName='UserCollection')]
        $FolderName,
    [Parameter(Mandatory=$True,HelpMessage="Please Enter CM Limiting Collection Name",ParameterSetName='DeviceCollection')]
    [Parameter(Mandatory=$True,HelpMessage="Please Enter CM Limiting Collection Name",ParameterSetName='UserCollection')]
        $LimitingCollectionName,
    [Parameter(Mandatory=$True,ParameterSetName='DeviceCollection')]
    [Parameter(Mandatory=$True,ParameterSetName='UserCollection')]
    [ValidateSet("Application","Package")]
        $PackageType,
    [Parameter(Mandatory=$True,ParameterSetName='DeviceCollection')]
        [Switch]$DeviceCollection,
    [Parameter(Mandatory=$True,ParameterSetName='UserCollection')]
        [Switch]$UserCollection
    )

    Switch($PackageType)
    {
       "Application" {$ObjectType = 6000}
       "Package" {$ObjectType = 2}
    }

If([intPtr]::size -eq 4){
    $CurentLocation = Get-Location

    $FolderIDQuery = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_ObjectContainernode -Filter "Name='$FolderName' and ObjectType='$ObjectType'" -ComputerName $SiteServer

    $ItemsInFolder = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_ObjectContainerItem -Filter "ContainerNodeID='$($FolderIDQuery.ContainerNodeID)' and ObjectType='$ObjectType'" -ComputerName $SiteServer

    Import-Module $ENV:SMS_ADMIN_UI_PATH.replace("bin\i386","bin\ConfigurationManager.psd1")

    $SiteCode = Get-PSDrive -PSProvider CMSITE | Where-Object {$_.Name -eq $SiteCode}

    Set-Location "$($SiteCode):"

    foreach($item in $ItemsInFolder)
    {
        Switch($PackageType)
        {

            "Package"
            {
                $PackageNameQUery = Get-CMPackage -Id $item.InstanceKey

                If($DeviceCollection){
                    New-CMDeviceCollection -Name $PackageNameQUery.Name -LimitingCollectionName $LimitingCollectionName
                }
                If($UserCollection){
                    New-CMUserCollection -Name $PackageNameQUery.Name -LimitingCollectionName $LimitingCollectionName
                }
            }

            "Application"
            {
                $ApplicationNameQuery = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_ApplicationLatest -Filter "ModelName='$($Item.InstanceKey)'" -ComputerName $SiteServer
        
                If($DeviceCollection){
                    New-CMDeviceCollection -Name $ApplicationNameQuery.LocalizedDisplayName -LimitingCollectionName $LimitingCollectionName
                }
                If($UserCollection){
                    New-CMUserCollection -Name $ApplicationNameQuery.LocalizedDisplayName -LimitingCollectionName $LimitingCollectionName
                }
            }
        }
    }

    Set-Location $CurentLocation
}
Else{
    Write-host "Please Start x86 of Windows PowerShell" -ForegroundColor RED
}