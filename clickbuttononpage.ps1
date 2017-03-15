workflow Click-Button {
    Param
    (
        # Param1 help description
        [string[]]$ComputerName,
        [pscredential]$Credential                
    )
    
    #$ComputerName = Get-Content -Path "C:\Users\mbado\Scripts\Reg Scan\bh101.txt"  
    #$ComputerName

    
    ForEach -parallel ($computer in $ComputerName) {
    
        $computer

        InlineScript {
            Invoke-Command -ComputerName $Using:computer -ScriptBlock {
                $Credential = $args[1]
                $args[0]
                New-PSDrive -Name 'MB' -PSProvider 'FileSystem' -Root '\\mu56273\UI' -Credential $Credential
                $compname = $args[0]
                cd MB:
                #$ie = New-Object -ComObject InternetExplorer.Application 
                #$ie.visible = $false
                #$ie.navigate("http://www.10best.com/awards/travel/best-new-hotel-2016/the-asbury-asbury-park-n-j/")

                #while($ie.ReadyState -ne 4) { start-sleep -s 1 }

                #$button = $ie.Document.getElementById('awardVoteButton')
                #$button.click()
                #$ie.quit()

                #systeminfo | Out-File -FilePath "\\mu56273\UI\$compname.txt" -Append
            } -ArgumentList @($using:computer, $using:Credential)
        } 
    } 
}