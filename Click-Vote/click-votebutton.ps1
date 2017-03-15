function Click-VoteButton {
    Param
    (
        # Param1 help description
        [string[]]$ComputerName,
        [pscredential]$Credential                
    )

    $sb = {
        param (
        $Computer,
        $Credential
        )

        Write-Output "Working on $Computer"
        Write-Output "$Credential"

        #[System.Collections.ArrayList]$ComputerObjectList = @()
        $s = New-PSSession -ComputerName $computer -Credential $Credential

        Invoke-Command -Session $s -ScriptBlock {
            $computer = $args[0]
            $Credential = $args[1]

            #New-PSDrive -Name 'MB' -PSProvider 'FileSystem' -Root '\\hercules\migdata$\Test' -Credential $Credential
            New-PSDrive -Name 'MB' -PSProvider 'FileSystem' -Root 'C:\Logs' -Credential $Credential

            New-Item -Path 'MB:\' -Name "$computer.log" -ItemType File

            Write-Output "Working on $computer inside Invoke-Command" | Out-File "MB:\$computer.log" -Append

            Write-Output "$Credential inside Invoke-Command. $($Credential.UserName) and $($Credential.Password)" | Out-File "MB:\$computer.log" -Append

            $ie = New-Object -ComObject InternetExplorer.Application 
            $ie.visible = $false
            $ie.navigate("http://www.10best.com/awards/travel/best-new-hotel-2016/the-asbury-asbury-park-n-j/")
            $i = 0
            while($true) { 
            
                if(($ie.ReadyState -ne 4) -or ($i -lt 10)){
                    Write-Output "ReadyState is $($ie.ReadyState) and i is $i. Still getting ready..." | Out-File "MB:\$computer.log" -Append
                
                    #start-sleep -s 1 
                    $i++
                } else {
                    break
                }
            }
                
            Write-Output "ReadyState is $($ie.ReadyState) and i is $i. IE is now ready." | Out-File "MB:\$computer.log" -Append

            Write-Output "Grabbing awardVoteButton element." | Out-File "MB:\$computer.log" -Append
            $button = $ie.Document.getElementById('awardVoteButton')
            Write-Output "Got awardVoteButton element." | Out-File "MB:\$computer.log" -Append

            try{
                Write-Output "Clicking the Button." | Out-File "MB:\$computer.log" -Append
                $button.click()
                Write-Output "Clicked the Button." | Out-File "MB:\$computer.log" -Append
            } catch {
                Write-Output $_.ErrorMessage | Out-File "MB:\$computer.log" -Append
            }

            Write-Output "Quitting IE." | Out-File "MB:\$computer.log" -Append
            $ie.quit()
            Write-Output "IE closed." | Out-File "MB:\$computer.log" -Append

        } -ArgumentList @($computer, $Credential)

        Remove-PSSession $s

    }

    $max = 10
    $jobs = @()


    foreach($computer in $ComputerName) {

        if(Test-Connection -ComputerName $computer -Count 1) {
            $jobs += Start-Job -ScriptBlock $sb -ArgumentList $computer,$Credential
            $running = @($jobs | Where-Object {$_.State -eq 'Running'})

            #Throttle
            while ($running.Count -ge $max) {
                $finished = Wait-Job -Job $jobs -Any
                $running = @($jobs | Where-Object {$_.State -eq 'Running'})
            }
        }
    }

    Wait-Job -Job $jobs > $null

    [System.Collections.ArrayList]$ComputerObjectList = @()
    $ComputerObjectList += $jobs | ForEach-Object {$_ | Receive-Job}

}

$computers = Get-Content -Path 'C:\users\mbado\scripts\Reg Scan\bh101.txt'
#$computers = 'BH101-06WL52656'
#$creds = Get-Credential

#Click-VoteButton -ComputerName $computers -Credential $creds

<#
Invoke-Command -ComputerName $computers {
    try{
        $procs = Get-Process -Name iexplore,wsmprovhost -IncludeUserName -ErrorAction SilentlyContinue | Where-Object {$_.UserName -eq 'MONMOUTH0\mbado'}
        $procs | Stop-Process

    } catch {}
}
#>