[System.Collections.ArrayList]$CompObjList = @()

$SearchBases = $null
$computerList = $null

$computerName = "MU56273"
$OU = "Labs"

if($OU){
    $SearchBases = (Get-ADObject -Filter "OU -eq `"$OU`"").DistinguishedName
}

if($SearchBases) {
    foreach($SearchBase in $SearchBases) {
        $computerList = Get-ADComputer -Filter "ObjectClass -eq 'computer'" -SearchBase $SearchBase -Properties pwdLastSet,DistinguishedName
        
        foreach($item in $computerList) {
            
            $formatOUString = ($item.DistinguishedName).Split(",")
            $formatOUString = $formatOUString[1..($formatOUString.length)]
            $formatOUString = [string]::Join(",", $formatOUString)

            $propHash = [ordered]@{
                ComputerName = $item.Name
                pwdLastSet = [datetime]::FromFileTimeUtc($item.pwdLastSet)
                OU =  $formatOUString
            }

            $compObj = New-Object -TypeName psobject -Property $propHash

            $CompObjList.Add($compObj) | Out-Null
        }     
    }

} else {
    $computerList = Get-ADComputer -Filter "Name -eq `"$computerName`""
}


$CompObjList | Out-GridView