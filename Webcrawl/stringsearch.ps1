$strURI = "10.8.0.121"
$webRequest = Invoke-WebRequest $strURI
$strWebRequest = $webRequest.rawcontent | out-string
$arrLinks = ([regex]::Matches($strWebRequest, 'src="/'))
$arrLinksResult = @()
$intLinksCount = $arrLinks.count
$arrLinks[0]
$i = 0
while ($i -lt $intLinksCount)
{
    $strCurrentMatch = $arrLinks[$i]
    $intStart = $strCurrentMatch.Index + $strCurrentMatch.Length
    $intEnd = $strWebRequest.IndexOf('"', $intStart)
    $intLength  = $intEnd - $intStart
    $arrLinksResult += $strWebRequest.Substring($intStart, $intLength)
    $i++
}
$arrLinksResult.Count

foreach ($strNewURI in $arrLinksResult)
{

    $strNewURI = $strURI + "/" + $strNewURI
    Write-Host "Current URI is: " $strNewURI
    $linksWebRequest = Invoke-WebRequest $strNewURI
    $strLinksWebRequest = $linksWebRequest.rawcontent | out-string
    $strLinksWebRequest = $strLinksWebRequest -replace '\n|\r|  '
    $strLinksWebRequest = $strLinksWebRequest -replace '  '
    if (($strLinksWebRequest -like "*laserjet*") -or ($strLinksWebRequest -like "*officejet*") -or ($newRawContent -like "*deskjet*"))
    {
        if ($strLinksWebRequest -like "*laserjet*")
        {
            $intStart = $strLinksWebRequest.IndexOf([regex]::Matches($strLinksWebRequest,"[lL]aser[jJ]et")) 
            
            Write-Host "LaserJet is at position: " $intStart
            $strModelStart = ""
            $j = 0
            while ($strModelStart -ne ">")
            {
                $strModelStart = $strLinksWebRequest[$intStart - $j]
                Write-Host "truestart at " ($intStart - $j) " is " $strModelStart
                $intModelStartIndex = $intStart - $j + 1
                $j++
            }
            $j = 0
            $strModelEnd = ""
            while ($strModelEnd -ne "<")
            {
                $strModelEnd = $strLinksWebRequest[$intStart + $j]
                Write-Host "trueend at " ($start + $j) " is " $strModelEnd
                $intModelEndIndex = $intStart + $j
                $j++
            }

            $intLength = $intModelEndIndex - $intModelStartIndex
            Write-Host "Length: " $intLength
            $model = $strLinksWebRequest.substring($intModelStartIndex, $intLength)
            Write-Host "Model: " $model

        }
    }
}