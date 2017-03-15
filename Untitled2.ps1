[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Data Entry Form"
$objForm.Size = New-Object System.Drawing.Size(300,200) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objTextBox.Text;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$x=$objTextBox.Text;$objForm.Close()})
$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(280,20) 
$objLabel.Text = "Please enter the information in the space below:"
$objForm.Controls.Add($objLabel) 

$objTextBox = New-Object System.Windows.Forms.TextBox 
$objTextBox.Location = New-Object System.Drawing.Size(10,40) 
$objTextBox.Size = New-Object System.Drawing.Size(260,20) 
$objForm.Controls.Add($objTextBox) 

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()

$x=$objTextBox.Text

Function Get-PendingUpdate { 
<#    
  .SYNOPSIS   
    Retrieves the updates waiting to be installed from WSUS   
  .DESCRIPTION   
    Retrieves the updates waiting to be installed from WSUS  
  .PARAMETER Computer 
    Computer or computers to find updates for.   
  .EXAMPLE   
   Get-PendingUpdates 
    
   Description 
   ----------- 
   Retrieves the updates that are available to install on the local system 
  .NOTES 
  Author: Boe Prox                                           
  Date Created: 05Mar2011                                           
#> 
      
#Requires -version 2.0   
[CmdletBinding( 
    DefaultParameterSetName = 'computer' 
    )] 
param( 
    [Parameter( 
        Mandatory = $False, 
        ParameterSetName = '', 
        ValueFromPipeline = $True)] 
        [string[]]$Computer               
    )     
Begin { 
    $scriptdir = { Split-Path $MyInvocation.ScriptName –Parent } 
    Write-Verbose "Location of function is: $(&$scriptdir)" 
    #Create container for Report 
    Write-Verbose "Creating report collection" 
    $report = @()     
    } 
Process { 
    ForEach ($c in $Computer) { 
        Write-Verbose "Computer: $($c)" 
        If (Test-Connection -ComputerName $c -Count 1 -Quiet) { 
            Try { 
            #Create Session COM object 
                Write-Verbose "Creating COM object for WSUS Session" 
                $updatesession =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$c)) 
                } 
            Catch { 
                Write-Warning "$($Error[0])" 
                Break 
                } 
 
            #Configure Session COM Object 
            Write-Verbose "Creating COM object for WSUS update Search" 
            $updatesearcher = $updatesession.CreateUpdateSearcher() 
 
            #Configure Searcher object to look for Updates awaiting installation 
            Write-Verbose "Searching for WSUS updates on client" 
            $searchresult = $updatesearcher.Search("IsInstalled=0")     
             
            #Verify if Updates need installed 
            Write-Verbose "Verifing that updates are available to install" 
            If ($searchresult.Updates.Count -gt 0) { 
                #Updates are waiting to be installed 
                Write-Verbose "Found $($searchresult.Updates.Count) update\s!" 
                #Cache the count to make the For loop run faster 
                $count = $searchresult.Updates.Count 
                 
                #Begin iterating through Updates available for installation 
                Write-Verbose "Iterating through list of updates" 
                For ($i=0; $i -lt $Count; $i++) { 
                    #Create object holding update 
                    $update = $searchresult.Updates.Item($i) 
                     
                    #Verify that update has been downloaded 
                    If ($update.IsDownLoaded -eq "True") {  
                        $temp = "" | Select Computer, Title, KB,IsDownloaded 
                        $temp.Computer = $c 
                        $temp.Title = ($update.Title -split('\('))[0] 
                        $temp.KB = (($update.title -split('\('))[1] -split('\)'))[0] 
                        $temp.IsDownloaded = "True" 
                        $report += $temp                
                        } 
                    Else { 
                        $temp = "" | Select Computer, Title, KB,IsDownloaded 
                        $temp.Computer = $c 
                        $temp.Title = ($update.Title -split('\('))[0] 
                        $temp.KB = (($update.title -split('\('))[1] -split('\)'))[0] 
                        $temp.IsDownloaded = "False" 
                        $report += $temp 
                        } 
                    } 
                 
                } 
            Else { 
                #Nothing to install at this time 
                Write-Verbose "No updates to install." 
                 
                #Create Temp collection for report 
                $temp = "" | Select Computer, Title, KB,IsDownloaded 
                $temp.Computer = $c 
                $temp.Title = "NA" 
                $temp.KB = "NA" 
                $temp.IsDownloaded = "NA" 
                $report += $temp 
                } 
            } 
        Else { 
            #Nothing to install at this time 
            Write-Warning "$($c): Offline" 
             
            #Create Temp collection for report 
            $temp = "" | Select Computer, Title, KB,IsDownloaded 
            $temp.Computer = $c 
            $temp.Title = "NA" 
            $temp.KB = "NA" 
            $temp.IsDownloaded = "NA" 
            $report += $temp             
            } 
        }  
    } 
End { 
    Write-Output $report 
    }     
}

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

Copy-Item $dir\Get-PendingUpdate.ps1 -Destination \\$x\c$\Get-PendingUpdate.ps1
Invoke-Command -ComputerName $x {
    cd c:\
    . .\get-pendingupdate.ps1
    }

$updates = Get-PendingUpdate -Computer $x

$updates | Out-GridView