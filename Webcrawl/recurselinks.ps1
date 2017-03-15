$URI_list = @(<#"10.8.0.121",#>"10.8.1.182") #$arrExcelValues

function iterate_links([Array]$arrayOfLinks)
{
    $i = 0

    Write-Host "Function Array of links: " $arrayOfLinks
    if ($arrayOfLinks.count -eq 0)
    {
        break
    }
    while ($i -lt $arrayOfLinks.count)
    {
        $URIWebRequest = <#$URI#>$arrayOfLinks[$i]
        Write-Host "Function URIWebRequest: " $URIWebRequest
        $strWebRequest = Invoke-WebRequest -URI $URIWebRequest 
        $strWebRequest = $strWebRequest.rawcontent | out-string
        #Write-Host $strWebRequest
        $arrLinks = ([regex]::Matches($strWebRequest, 'href="|src="'))
        $arrLinksResult = @()
        $intLinksCount = $arrLinks.count
        Write-Host "FUNCTION: There are " $intLinksCount " links on " $URIWebRequest
        $i = 0
        Write-Host "Function arrLinks: " $arrLinks
        Write-host "Function intLinksCount: " $intLinksCount

        while ($i -lt $intLinksCount)
        {
            $strCurrentMatch = $arrLinks[$i]
            $intStart = $strCurrentMatch.Index + $strCurrentMatch.Length
            $intEnd = $strWebRequest.IndexOf('"', $intStart)
            $intLength  = $intEnd - $intStart
            $strLinksResult = $strWebRequest.Substring($intStart, $intLength)
            
            if ($strLinksResult -notlike "*/*")
            {
                Write-Host "function strLinksResult doesn't contain a / :" $strLinksResult
                $j = 0
                $char = ""
                while ($char -ne "/")
                {
                    $j++
                    $char = $URIWebRequest[$URIWebRequest.length - $j]
                    Write-Host "Char is " $char " @ j=" $j
                    
                }
                Write-Host "function URIwebrequest was " $URIWebRequest
                $URIWebRequest = $URIWebRequest.substring(0,($URIWebRequest.length - $j)+1)
                Write-Host "function URIwebrequest is now " $URIWebRequest
            }
            if (($strLinksResult -like "*.htm*") -or ($strLinksResult -like "*.html*") -or ($strLinksResult -like "*.cgi*"))
            {
                Write-Host "adding " ($URIWebRequest + $strWebRequest.Substring($intStart, $intLength)) " into arrLinksResult"
                $arrLinksResult += $URIWebRequest + $strWebRequest.Substring($intStart, $intLength)
                
                Write-Host "Function arrLinksResult: " $arrLinksResult

                iterate_links($arrLinksResult)
            }
            else
            {
                Write-Host ($URIWebRequest + $strWebRequest.Substring($intStart, $intLength)) " is not being added into arrLinksResult"
                
            }
            $i++
        }
        $i++           
    }
    
      

}

foreach ($URI in $URI_list)
{
    $WebRequest = Invoke-WebRequest -Uri $URI -TimeoutSec 5 -ErrorAction Continue
    foreach ($x in $WebRequest)
    {
        
        
        $strWebRequest = $x.rawcontent | out-string
        $arrLinks = ([regex]::Matches($strWebRequest, 'href="'))
        $arrLinksResult = @()
        $intLinksCount = $arrLinks.count
        $i = 0
        Write-Host "arrLinks: " $arrLinks
        Write-host "intLinksCount: " $intLinksCount
                    
                    
        while ($i -lt $intLinksCount)
        {
            $strCurrentMatch = $arrLinks[$i]
            $intStart = $strCurrentMatch.Index + $strCurrentMatch.Length
            $intEnd = $strWebRequest.IndexOf('"', $intStart)
            $intLength  = $intEnd - $intStart
            $strLinksResult = $URI + $strWebRequest.Substring($intStart, $intLength)
            $arrLinksResult += $strLinksResult
            $i++
            Write-Host "arrLinksResult: " $arrLinksResult
            #iterate_links($arrLinksResult)
            iterate_links($arrLinksResult)       
        }
        
    }
}
#>