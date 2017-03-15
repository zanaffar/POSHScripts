#

# Script name: Create_User_Collections.ps1

#

# Purpose: Creates User Collections based on AD Group Name, uses .csv

# as input

#

# Author: Marc Westerink

#

# Reference: http://technet.microsoft.com/library/jj821754(v=sc.20).aspx

# http://technet.microsoft.com/library/jj850093(v=sc.20).aspx

# http://technet.microsoft.com/library/jj850149(v=sc.20).aspx

# http://technet.microsoft.com/library/jj821926(v=sc.20).aspx

#

#

#Create the required ‘global’ variables

$ConfigMgrModulePath=“D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1”

$ConfigMgrSiteCode=“P01:”

#Connecting to site

Import-Module $ConfigMgrModulePath

Set-Location $ConfigMgrSiteCode

#Creating the User Collections

 Import-CSV E:\Install\CMName.csv | %{

#Create the required ‘local’ variables

$AllUsers=“All Users”

$RefreshType=“ConstantUpdate”

$DomainName=“DOMAIN1”

$UCInstallName=“‘”+$DomainName+‘\\’+$_.CMName+“‘”

$UCUninstallName=“Uninstall “+$_.CMName

$QueryExpression=‘”select SMS_R_USER.ResourceID,SMS_R_USER.ResourceType,SMS_R_USER.Name,SMS_R_USER.UniqueUserName,SMS_R_USER.WindowsNTDomain from SMS_R_User where SMS_R_User.SecurityGroupName=’

#Create the User Collection with a query rule

New-CMUserCollection -LimitingCollectionName $AllUsers -Name $_.CMName -RefreshType $RefreshType

Add-CMUserCollectionQueryMembershipRule -CollectionName $_.CMName -RuleName $_.CMName -QueryExpression $QueryExpression$UCInstallName

#Create the ‘uninstall’ User Collection with 2 rules: include All Users and exclude the User Collection

New-CMUserCollection -LimitingCollectionName $AllUsers -Name $UCUninstallName -RefreshType $RefreshType

Add-CMUserCollectionIncludeMembershipRule -CollectionName $UCUninstallName -IncludeCollectionName $AllUsers

Add-CMUserCollectionExcludeMembershipRule -CollectionName $UCUninstallName -ExcludeCollectionName $_.CMName

}