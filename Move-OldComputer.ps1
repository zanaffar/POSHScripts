Import-Module ActiveDirectory

function Move-OldComputers {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[timespan]$TimeSpan
	)

    Begin
    {
    }
    Process
    {
        $computers = Search-ADAccount -ComputersOnly -AccountInactive -TimeSpan $TimeSpan
        $computers.count
        $TargetOU = "OU=Disabled Computers,DC=dktestad,DC=root"
        $LogPath = "C:\Scripts\computers.log"
        <#
        ForEach ($computer in $computers){            
            #Move-ADObject $computer -TargetPath "$TargetOU" -WhatIf
            Add-Content -Path "$LogPath" -Value "Found $($computer.Name), disabling"
            $desc="Contact Support, disabled on $(Get-Date) - $($computer.Name)"
            #Set-ADComputer $computer -Description $desc -Enabled $false -Whatif
            Add-Content -Path "$LogPath" -Value "$($Computer.Name) not in Active Directory"
        } #>
    }
    End
    {
    }
}