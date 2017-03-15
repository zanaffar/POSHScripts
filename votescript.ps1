

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

        New-PSDrive -Name 'MB' -PSProvider 'FileSystem' -Root '\\hercules\migdata$\Test' -Credential $Credential
        New-Item -Path 'MB:\' -Name "$computer.txt" -ItemType File

        Write-Output "Working on $computer inside Invoke-Command" | Out-File "MB:\$computer.txt" -Append

        Write-Output "$Credential inside Invoke-Command. $($Credential.UserName) and $($Credential.Password)" | Out-File "MB:\$computer.txt" -Append

        $ie = New-Object -ComObject InternetExplorer.Application 
        $ie.visible = $false
        $ie.navigate("http://www.10best.com/awards/travel/best-new-hotel-2016/the-asbury-asbury-park-n-j/")
        
        $i = 0

        while(($ie.ReadyState -ne 4) -or ($i -ge 10)) { 
            
            Write-Output "ReadyState is $($ie.ReadyState) and i is $i. Still getting ready..." | Out-File "MB:\$computer.txt" -Append
            start-sleep -s 1
            $i++ 
        }
                
        Write-Output "ReadyState is $($ie.ReadyState) and i is $i. IE is now ready." | Out-File "MB:\$computer.txt" -Append

        Write-Output "Grabbing awardVoteButton element." | Out-File "MB:\$computer.txt" -Append
        $button = $ie.Document.getElementById('awardVoteButton')
        Write-Output "Got awardVoteButton element." | Out-File "MB:\$computer.txt" -Append

        try{
            Write-Output "Clicking the Button." | Out-File "MB:\$computer.txt" -Append
            $button.click()
            Write-Output "Clicked the Button." | Out-File "MB:\$computer.txt" -Append
        } catch {
            Write-Output $_.ErrorMessage | Out-File "MB:\$computer.txt" -Append
        }

        Write-Output "Quitting IE." | Out-File "MB:\$computer.txt" -Append
        $ie.quit()
        Write-Output "IE closed." | Out-File "MB:\$computer.txt" -Append

    } -ArgumentList @($computer, $Credential)

    Remove-PSSession $s

}