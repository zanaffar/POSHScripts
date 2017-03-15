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