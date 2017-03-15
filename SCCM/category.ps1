# Gets "Administrative categories" and "User categories"
$ApplicationCategories = @(gwmi -Namespace root\sms\site_$site -ComputerName $server -Class SMS_CategoryInstance | ? {@("AppCategories","CatalogCategories") -icontains $_.CategoryTypeName})
Write-Host "I found $($ApplicationCategories.Count) Application Categories"
# Gets application<->category relationships for the categories found above
# NOTE: This WMI Class is large so to reduce overhead it must be queried with a Filter and as little as possible
$CategoryRelationships = @($ApplicationCategories | % {gwmi -Namespace root\sms\site_$site -ComputerName $server -Class SMS_CategoryInstanceMembership -Filter "CategoryInstanceID = $($_.CategoryInstanceID)"})
Write-Host "I found $($CategoryRelationships.Count) Category Relationships"
# Get a list of applications from the server that have categories
$ServerApplicationsWithCategories =  @($CategoryRelationships | % {$_.ObjectKey} | % {gwmi -Namespace root\sms\site_$site -ComputerName $server -Class SMS_Application -Filter "CI_UniqueID = '$_'"} | Sort-Object ModelID -Unique)
Write-Host "I found $($ServerApplicationsWithCategories.Count) Server Applications With Categories"
# Show results
foreach ($Application in $ServerApplicationsWithCategories) {
    Write-Host "`t$($Application.LocalizedDisplayName)"
    foreach ($Relationship in @($CategoryRelationships | ? {$_.ObjectKey -eq $Application.CI_UniqueID})) {
        $CategoryName = $($Categories | ? {$Relationship.CategoryInstanceID -eq $_.CategoryInstanceID} | % {$_.LocalizedCategoryInstanceName})
        Write-Host "`t`t$CategoryName"
    }
}
# Get a list of applications locally that have categories
$LocalApplicationsWithCategories =  @($CategoryRelationships | % { @($_.ObjectKey.Split("/"))[0..1] -join "/"} | % {gwmi -Namespace root\CCM\ClientSDK -Class CCM_Application -Filter "Id = '$_'"} | Sort-Object -Unique)
Write-Host "I found $($LocalApplicationsWithCategories.Count) Local Applications With Categories"
# Show results
foreach ($Application in $LocalApplicationsWithCategories) {
    Write-Host "`t$($Application.Name)"
    foreach ($Relationship in @($CategoryRelationships | ? {"$($_.ObjectKey)" -ilike "$($Application.Id)*"})) {
        $CategoryName = $($Categories | ? {$Relationship.CategoryInstanceID -eq $_.CategoryInstanceID} | % {$_.LocalizedCategoryInstanceName})
        Write-Host "`t`t$CategoryName"
    }
}