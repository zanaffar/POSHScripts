$OU = 'Advancement Services'

$SearchBase = (Get-ADObject -Filter "OU -eq `"$OU`"").DistinguishedName

$computerList = (Get-ADComputer -Filter "ObjectClass -eq 'computer'" -SearchBase $SearchBase).name

workflow Invoke-CommandParallel {

    param (
	    [Parameter(Mandatory = $true)]
	    [Alias('Computer')]
	    [String[]]$ComputerName,
	    [Parameter(Mandatory = $true)]
	    [String[]]$ScriptBlock
	    #[Parameter(Mandatory = $false)]
	    #[String]$LogPath = 'C:\Logs\INIinfo',
	    #[Parameter(Mandatory = $false)]
	    #[Switch]$PerUser
	)
    
    foreach -parallel ($Computer in $ComputerName) {
        
        if(Test-Connection -ComputerName $Computer -Count 1 -Quiet) {

            InlineScript {
                $Computer = $Using:Computer
                $ScriptBlock = $Using:ScriptBlock

                Invoke-Command -ComputerName $Computer -ScriptBlock {
                    Write-Output "Starting Job on $env:COMPUTERNAME"
                    & ([scriptblock]::Create($args[0]))
                    Write-Output "Finished Job on $env:COMPUTERNAME"
                } -ArgumentList $ScriptBlock 
            }
        }
    }


}

