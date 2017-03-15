$input = "C:\Users\mbado\Desktop\print-03_config.xlsx"
$output = "C:\Users\mbado\Desktop\printmod.txt"

# ----------------------------------------------------- 
# This section allows the script to ignore SSL errors.

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
# ----------------------------------------------------- 

# ----------------------------------------------------- 
# This section allows the script to ignore incorrect Headers in pages.


$netAssembly = [Reflection.Assembly]::GetAssembly([System.Net.Configuration.SettingsSection])

if($netAssembly)
{
    $bindingFlags = [Reflection.BindingFlags] "Static,GetProperty,NonPublic"
    $settingsType = $netAssembly.GetType("System.Net.Configuration.SettingsSectionInternal")

    $instance = $settingsType.InvokeMember("Section", $bindingFlags, $null, $null, @())

    if($instance)
    {
        $bindingFlags = "NonPublic","Instance"
        $useUnsafeHeaderParsingField = $settingsType.GetField("useUnsafeHeaderParsing", $bindingFlags)

        if($useUnsafeHeaderParsingField)
        {
            $useUnsafeHeaderParsingField.SetValue($instance, $true)
        }
    }
}
# ----------------------------------------------------- 


# ----------------------------------------------------- 
# Not too sure what this part does, but it goes along with
# the next part which loads an Excel file and reads one of
# its columns into an array to get the list of IPs.

function Release-Ref ($ref) { 
([System.Runtime.InteropServices.Marshal]::ReleaseComObject( 
[System.__ComObject]$ref) -gt 0) 
[System.GC]::Collect() 
[System.GC]::WaitForPendingFinalizers() 
} 
# ----------------------------------------------------- 
# Read the Excel file here. 

$arrExcelValues = @() 
 
$objExcel = new-object -comobject excel.application  
$objExcel.Visible = $False  
$objWorkbook = $objExcel.Workbooks.Open($input) 
$objWorksheet = $objWorkbook.Worksheets.Item(1) 
 
$i = 2 
 
Do { 
    $arrExcelValues += $objWorksheet.Cells.Item($i, 6).Value() -replace "IP_|,[.1234567890]*"
    $i++ 
} 
While ($objWorksheet.Cells.Item($i,6).Value() -ne $null) 
 
$a = $objExcel.Quit()
 
foreach ($objItem in $arrExcelValues) { 
        write-host $objItem 
} 
 
$a = Release-Ref($objWorksheet) 
$a = Release-Ref($objWorkbook) 
$a = Release-Ref($objExcel)

$URI_list = @("10.8.0.121","10.8.1.182") #$arrExcelValues
# ----------------------------------------------------- 


foreach ($URI in $URI_list)
{
    Write-Host "Current URI is: " $URI

    Try
    {
        $WebRequest = Invoke-WebRequest -Uri $URI -TimeoutSec 5 -ErrorAction Continue
    }
    Catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $ErrorCounter = 1
    }

    if ($ErrorCounter -eq 0)
    {
        foreach ($x in $WebRequest)
        {                   
            if (($x.RawContent -like "*laserjet*")  -or ($x.RawContent -like "*officejet*") -or ($x.RawContent -like "*deskjet*") -or ($x.RawContent -like "*hewlett*"))
            {
                # Write-Host "This is an HP printer"
                Try
                {
                    $result = $x.ParsedHtml.title
                }
                Catch
                {
                    $ErrorMessage = $_.Exception.Message
                    $ErrorCounter = 1
                }

                if ($ErrorCounter -eq 0)
                {                    
                    if (($result -like "*laserjet*") -or ($result -like "*officejet*") -or ($result -like "*deskjet*"))
                    {
                        $model = $result -replace "$URI"

                    }       
                    elseif ($result.length -le 0)
                    {                                       
                        $model = $x.Headers.Server -split("; ")
                        $model = $model[1] 
                        $model = $model -replace "$URI"
                        
                    }
                    elseif ($result -like "*hewlett*")
                    {                        
                        $model = "Some ancient HP printer"
                    }
                    else
                    {
                        $model = $x.AllElements | Where Class -eq 'product' | Select innerHTML
                        $model = $model[1] -replace "@|{|}|innerHTML="
                        $model = $model -replace "$URI"
                    }                        
                }
            }
            elseif ($x.rawcontent -like "*brother*")
            {
                # Write-Host "This is a Brother printer"
                Try
                {
                    $result = $x.ParsedHtml.title
                }
                Catch
                {
                    $ErrorMessage = $_.Exception.Message
                    $ErrorCounter = 1
                }

                if ($ErrorCounter -eq 0)
                {                    
                    if ($result.length -gt 0)
                    {                                       
                        $model = $result -replace "$URI"
                    }
                    else
                    {                        
                        $model = "Looks like a Brother printer... maybe?"                        
                    }
                }
            }
            elseif ($x.RawContent -like "*Web Image Monitor*")
            {
                $model = "RICOH Printer of some sort"
                 
                #Look for links to other pages here
                #$strURI = "10.8.0.121"
                #$webRequest = Invoke-WebRequest $strURI
                #function iterate_links(
                #{
                    $strWebRequest = $x.rawcontent | out-string
                    $arrLinks = ([regex]::Matches($strWebRequest, 'href="'))
                    $arrLinksResult = @()
                    $intLinksCount = $arrLinks.count
                    $i = 0
                    Write-Host "arrLinks: " $arrLinks
                    Write-host "intLinksCount: " $intLinksCount
                    
                    
                    while (($i -lt $intLinksCount) -or ($model -ne "RICOH Printer of some sort"))
                    {
                        $strCurrentMatch = $arrLinks[$i]
                        $intStart = $strCurrentMatch.Index + $strCurrentMatch.Length
                        $intEnd = $strWebRequest.IndexOf('"', $intStart)
                        $intLength  = $intEnd - $intStart
                        $arrLinksResult += $strWebRequest.Substring($intStart, $intLength)
                        $i++
                        Write-Host "arrLinksResult: " $arrLinksResult
                   
                    }

                    foreach ($strNewURI in $arrLinksResult)
                    {

                        $strNewURI = $URI + $strNewURI
                        Write-Host "strNewURI: " $strNewURI
                        $linksWebRequest = Invoke-WebRequest $strNewURI
                        $model = ($linksWebRequest.ParsedHtml.getElementsByTagName('*') | Where-Object {$_.className -eq "modelName"}).innerText
                        Write-Host "Ricoh model: " $model
                        <#
                        $strLinksWebRequest = $linksWebRequest.rawcontent | out-string
                        $strLinksWebRequest = $strLinksWebRequest -replace '\n|\r|  '
                        $strLinksWebRequest = $strLinksWebRequest -replace '  '

                        if (($strLinksWebRequest -like "*laserjet*") -or ($strLinksWebRequest -like "*officejet*") -or ($newRawContent -like "*deskjet*"))
                        {
                            if ($strLinksWebRequest -like "*laserjet*")
                            {
                                $intStart = $strLinksWebRequest.IndexOf([regex]::Matches($strLinksWebRequest,"[lL]aser[jJ]et")) 
                                $strModelStart = ""
                                $j = 0

                                while ($strModelStart -ne ">")
                                {
                                    $strModelStart = $strLinksWebRequest[$intStart - $j]
                                    $intModelStartIndex = $intStart - $j + 1
                                    $j++
                                }

                                $j = 0
                                $strModelEnd = ""

                                while ($strModelEnd -ne "<")
                                {
                                    $strModelEnd = $strLinksWebRequest[$intStart + $j]
                                    $intModelEndIndex = $intStart + $j
                                    $j++
                                }

                                $intLength = $intModelEndIndex - $intModelStartIndex
                                $model = $strLinksWebRequest.substring($intModelStartIndex, $intLength)
                            }
                        
                        } #>
                    }
                #}
                
                
            }
            else
            {
                $model = "No idea what printer this is..."
                #Look for links to other pages here
                #$strURI = "10.8.0.121"
                #$webRequest = Invoke-WebRequest $strURI
                $strWebRequest = $x.rawcontent | out-string
                $arrLinks = ([regex]::Matches($strWebRequest, 'src="/'))
                $arrLinksResult = @()
                $intLinksCount = $arrLinks.count
                $i = 0

                while (($i -lt $intLinksCount) -or ($model -ne "No idea what printer this is..."))
                {
                    $strCurrentMatch = $arrLinks[$i]
                    $intStart = $strCurrentMatch.Index + $strCurrentMatch.Length
                    $intEnd = $strWebRequest.IndexOf('"', $intStart)
                    $intLength  = $intEnd - $intStart
                    $arrLinksResult += $strWebRequest.Substring($intStart, $intLength)
                    $i++
                }

                foreach ($strNewURI in $arrLinksResult)
                {

                    $strNewURI = $URI + "/" + $strNewURI
                    $linksWebRequest = Invoke-WebRequest $strNewURI
                    $strLinksWebRequest = $linksWebRequest.rawcontent | out-string
                    $strLinksWebRequest = $strLinksWebRequest -replace '\n|\r|  '
                    $strLinksWebRequest = $strLinksWebRequest -replace '  '

                    if (($strLinksWebRequest -like "*laserjet*") -or ($strLinksWebRequest -like "*officejet*") -or ($newRawContent -like "*deskjet*"))
                    {
                        if ($strLinksWebRequest -like "*laserjet*")
                        {
                            $intStart = $strLinksWebRequest.IndexOf([regex]::Matches($strLinksWebRequest,"[lL]aser[jJ]et")) 
                            $strModelStart = ""
                            $j = 0

                            while ($strModelStart -ne ">")
                            {
                                $strModelStart = $strLinksWebRequest[$intStart - $j]
                                $intModelStartIndex = $intStart - $j + 1
                                $j++
                            }

                            $j = 0
                            $strModelEnd = ""

                            while ($strModelEnd -ne "<")
                            {
                                $strModelEnd = $strLinksWebRequest[$intStart + $j]
                                $intModelEndIndex = $intStart + $j
                                $j++
                            }

                            $intLength = $intModelEndIndex - $intModelStartIndex
                            $model = $strLinksWebRequest.substring($intModelStartIndex, $intLength)
                        }
                        elseif ($strLinksWebRequest -like "*officejet*")
                        {
                            $intStart = $strLinksWebRequest.IndexOf([regex]::Matches($strLinksWebRequest,"[oO]ffice[jJ]et")) 
                            $strModelStart = ""
                            $j = 0

                            while ($strModelStart -ne ">")
                            {
                                $strModelStart = $strLinksWebRequest[$intStart - $j]
                                $intModelStartIndex = $intStart - $j + 1
                                $j++
                            }

                            $j = 0
                            $strModelEnd = ""

                            while ($strModelEnd -ne "<")
                            {
                                $strModelEnd = $strLinksWebRequest[$intStart + $j]
                                $intModelEndIndex = $intStart + $j
                                $j++
                            }

                            $intLength = $intModelEndIndex - $intModelStartIndex
                            $model = $strLinksWebRequest.substring($intModelStartIndex, $intLength)
                        }
                        elseif ($strLinksWebRequest -like "*deskjet*")
                        {
                            $intStart = $strLinksWebRequest.IndexOf([regex]::Matches($strLinksWebRequest,"[dD]esk[jJ]et")) 
                            $strModelStart = ""
                            $j = 0

                            while ($strModelStart -ne ">")
                            {
                                $strModelStart = $strLinksWebRequest[$intStart - $j]
                                $intModelStartIndex = $intStart - $j + 1
                                $j++
                            }

                            $j = 0
                            $strModelEnd = ""

                            while ($strModelEnd -ne "<")
                            {
                                $strModelEnd = $strLinksWebRequest[$intStart + $j]
                                $intModelEndIndex = $intStart + $j
                                $j++
                            }

                            $intLength = $intModelEndIndex - $intModelStartIndex
                            $model = $strLinksWebRequest.substring($intModelStartIndex, $intLength)
                        }
                    }
                }
                
            }
                              
        $model = "IP " + $URI + ": " +  $model
        $model = $model -replace "`n|`r"
        $model = $model -replace "&nbsp;"
        $model | Out-File $output -Append

        #Write-Host $result
                                        
        }        
    }
    else
    {
        $result = "IP " + $URI + ": Printer model unknown due to error: " + $ErrorMessage
        $result | Out-File $output -Append
    }

    $ErrorCounter = 0
}