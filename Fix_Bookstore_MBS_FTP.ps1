## Fixes the MBS FTP Site in CrossFTP for the Bookstore ##

function Get-LoggedOnUser { 
        #Requires -Version 2.0             
        [CmdletBinding()]             
         Param              
           (                        
            [Parameter(Mandatory=$false, 
                       Position=0,                           
                       ValueFromPipeline=$true,             
                       ValueFromPipelineByPropertyName=$true)]             
            [String[]]$ComputerName = $env:COMPUTERNAME 
           )#End Param 
 
        Begin             
        {             
         Write-Host "`n Checking Users . . . " 
         $i = 0 
         $MyParams = @{ 
             Class       = "Win32_process"  
             Filter      = "Name='Explorer.exe'"  
             ErrorAction = "Stop" 
            } 
        }#Begin           
        Process             
        { 
            $ComputerName | Foreach-object { 
            $Computer = $_ 
     
            $MyParams["ComputerName"] = $Computer 
            try 
                { 
                    $processinfo = @(Get-WmiObject @MyParams) 
                    if ($Processinfo) 
                        {     
                            $Processinfo | ForEach-Object {  
                                New-Object PSObject -Property @{ 
                                    ComputerName=$Computer 
                                    LoggedOn    =$_.GetOwner().User 
                                    SID         =$_.GetOwnerSid().sid} } |  
                            Select-Object ComputerName,LoggedOn,SID 
                        }#If 
                } 
            catch 
                { 
                    "Cannot find any processes running on $computer" | Out-Host 
                } 
             }#Forech-object(ComputerName)        
             
        }#Process 
        End 
        { 
 
        }#End 
 
        }#Get-LoggedOnUsers 

## Get the currently logged on user ##
$User = (Get-LoggedOnUser).LoggedOn

## The encrypted MBS FTP Site password ##
$MBS_FTP_Password = "t0/0cpTnmEt0owo/ysTUnQ=="

## Path to the sites.xml CrossFTP file ##
$CrossFTP_SitesXMLPath = "$env:SystemDrive\Users\$user\.crossftp\sites.xml"

## Parse the sites.xml file. Find the entry for MBS FTP Site and replace the password ##
[xml]$SitesXML = Get-Content -Path "$CrossFTP_SitesXMLPath"
$MBS_FTP_Site = ($SitesXML.bookmarks.category.site | Where-Object {$_.hName -eq 'taonlinesys.mbsbooks.com'})
$MBS_FTP_Site.pw = $MBS_FTP_Password

## Save the XML ##
$SitesXML.Save($CrossFTP_SitesXMLPath)

$SitesString = (Get-Content -Path "$CrossFTP_SitesXMLPath" -Raw).tostring().Replace("`"0`">`r`n","`"0`">") | Out-File -FilePath "$CrossFTP_SitesXMLPath" -Encoding default -Force
$SitesString = (Get-Content -Path "$CrossFTP_SitesXMLPath" -Raw).tostring().Replace(">    <","><") | Out-File -FilePath "$CrossFTP_SitesXMLPath" -Encoding default -Force
$SitesString = (Get-Content -Path "$CrossFTP_SitesXMLPath" -Raw).tostring().Replace(">      <","><") | Out-File -FilePath "$CrossFTP_SitesXMLPath" -Encoding default -Force