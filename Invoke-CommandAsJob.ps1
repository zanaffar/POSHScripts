$OU = 'Advancement Services'

$SearchBase = (Get-ADObject -Filter "OU -eq `"$OU`"").DistinguishedName

$computerList = (Get-ADComputer -Filter "ObjectClass -eq 'computer'" -SearchBase $SearchBase).name

function Invoke-CommandAsJob {

    param (
	    [Parameter(Mandatory = $true)]
	    [Alias('Computer')]
	    [String[]]$ComputerName,
	    [Parameter(Mandatory = $true)]
	    [string]$ScriptBlock
	    #[Parameter(Mandatory = $false)]
	    #[String]$LogPath = 'C:\Logs\INIinfo',
	    #[Parameter(Mandatory = $false)]
	    #[Switch]$PerUser
	)
    
    #$sb = {$ScriptBlock}
    #    "Starting Job on $($args[0])"
    #    Invoke-Command -ComputerName $args[0] -ScriptBlock {$args[1]}
    #    "Ending Job on $($args[0])"
    #}

    ForEach ($Computer in $ComputerName) {
        
        if(Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
            Write-Output "Starting Job on $Computer"
            Start-Job -ScriptBlock {
                $Computer = $args[0]
                $ScriptBlock = $args[1]

                Invoke-Command -ComputerName $Computer -ScriptBlock {
                    Write-Output "Starting Job on $env:COMPUTERNAME"
                    & ([scriptblock]::Create($args[0]))
                    Write-Output "Finished Job on $env:COMPUTERNAME"
                } -ArgumentList $ScriptBlock
            
            } -ArgumentList $Computer,$ScriptBlock
            Get-Job | ? {$_.State -eq 'Complete' -and $_.HasMoreData} | % {Receive-Job $_}

        }
            
    }

    while((Get-Job -State Running).count){
        Get-Job | ? {$_.State -eq 'Complete' -and $_.HasMoreData} | % {Receive-Job $_}
        start-sleep -seconds 1
    }


}

