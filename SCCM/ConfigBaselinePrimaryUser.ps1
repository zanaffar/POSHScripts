$policyName = "Client Cache Size 20480"
$deviceAffinity = $false
$notAtom = $true

$primaryUser = (Get-WmiObject -Namespace "root\ccm\policy\machine" -Class "ccm_UserAffinity").ConsoleUser
$objUser = New-Object System.Security.Principal.NTAccount ("$primaryUser")
$strSID = (($objUser.Translate([System.Security.Principal.SecurityIdentifier])).Value).Replace("-","_")
$policies = Get-WmiObject -Namespace "root\ccm\Policy\$strSID" -Class "CCM_DCMCIAssignment"

foreach ($policy in $policies) {
    if ($policy.AssignmentName -like "$policyName*") {
        $deviceAffinity = $true
    }
}

$processor = (Get-WmiObject -Class win32_processor).name
if($processor -like "*Atom*"){
    $notAtom = $false
}

if($deviceAffinity -and $notAtom) {
    $ccmcachesize = (Get-WmiObject -Namespace root\ccm\SoftMgmtAgent -Class CacheConfig).size
    write-host $ccmcachesize
} else {
    Write-Host "Machine does not meet requirements for this policy"
    exit 1
}