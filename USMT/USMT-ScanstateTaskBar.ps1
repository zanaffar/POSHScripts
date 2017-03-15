[CmdletBinding(DefaultParameterSetName = 'Local',
			   SupportsShouldProcess = $true)]
param (
	#[Parameter(Mandatory=$false,ParameterSetName='Local')]
	[Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Remote')]
	[Alias('Computer')]
	[String[]]$ComputerName = "$env:COMPUTERNAME",
	[Parameter(Mandatory = $false, ParameterSetName = 'Local')]
	[Parameter(Mandatory = $false, ParameterSetName = 'Remote')]
	[String[]]$Users,
	[Parameter(Mandatory = $true, ParameterSetName = 'Remote')]
	[PSCredential]$Credential,
	[Parameter(Mandatory = $false, ParameterSetName = 'Local')]
	[Parameter(Mandatory = $false, ParameterSetName = 'Remote')]
	[Switch]$Force,
	[Switch]$Local,
	[Switch]$Remote
	)
<#
	.SYNOPSIS
		A brief description of the Name function.

	.DESCRIPTION
		A detailed description of the Name function.

	.PARAMETER  ParameterA
		The description of a the ParameterA parameter.

	.PARAMETER  ParameterB
		The description of a the ParameterB parameter.

	.EXAMPLE
		PS C:\> Name -ParameterA 'One value' -ParameterB 32
		'This is the output'
		This example shows how to call the Name function with named parameters.

	.EXAMPLE
		PS C:\> Name 'One value' 32
		'This is the output'
		This example shows how to call the Name function with positional parameters.

	.INPUTS
		System.String,System.Int32

	.OUTPUTS
		System.String

	.NOTES
		For more information about advanced functions, call Get-Help with any
		of the topics in the links listed below.

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

	.LINK
		about_functions_advanced_parameters

	.LINK
		about_functions_advanced_methods
#>
function USMT-ScanstateTaskBar {
	[CmdletBinding(DefaultParameterSetName = 'Local',
				   SupportsShouldProcess = $true)]
	param (
		#[Parameter(Mandatory=$false,ParameterSetName='Local')]
		[Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Remote')]
		[Alias('Computer')]
		[String[]]$ComputerName = "$env:COMPUTERNAME",
		[Parameter(Mandatory = $false, ParameterSetName = 'Local')]
		[Parameter(Mandatory = $false, ParameterSetName = 'Remote')]
		[String[]]$Users,
		[Parameter(Mandatory = $true, ParameterSetName = 'Remote')]
		[PSCredential]$Credential,
		[Parameter(Mandatory = $false, ParameterSetName = 'Local')]
		[Parameter(Mandatory = $false, ParameterSetName = 'Remote')]
		[Switch]$Force,
        [Switch]$Taskbar
		
	)
	begin {
		try {
			## Initialize Variables ##
			
			$date = Get-Date
			$month_number = $date.Month
			$Year = $date.Year
			
			switch ($date.Month) {
				1 {
					$month = 'January'
				}
				2 {
					$month = 'February'
				}
				3 {
					$month = 'March'
				}
				4 {
					$month = 'April'
				}
				5 {
					$month = 'May'
				}
				6 {
					$month = 'June'
				}
				7 {
					$month = 'July'
				}
				8 {
					$month = 'August'
				}
				9 {
					$month = 'September'
				}
				10 {
					$month = 'October'
				}
				11 {
					$month = 'November'
				}
				12 {
					$month = 'December'
				}
			}
			
		} catch {
		}
	}
	process {
		try {
			Foreach ($Computer in $ComputerName) {
                if($Taskbar) {
                    $dirMigData = '\\hercules\migdata$'
					$dir_ScanState = "$dirMigData\USMT_SCANSTATE"
					$dirDest = "$dir_ScanState\$Year\$($month_number)_$($month)"

                    New-Item -Path "$dirDest\$env:COMPUTERNAME\User Regs" -ItemType Directory -Force
                    $xUsers = (Get-ChildItem -Path "$env:SystemDrive\Users" | Where-Object {(Test-Path -Path "$($_.FullName)\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar")})

                    $userKeys = Get-ChildItem -Path 'Registry::HKEY_USERS' | Where-Object {
                        ($_.PSChildName -ne "S-1-5-19") -and `
                        ($_.PSChildName -ne "S-1-5-20") -and `
                        ($_.PSChildName -ne "S-1-5-18") -and `
                        ($_.PSChildName -ne ".DEFAULT") -and `
                        ($_.PSChildName -notlike "*classes")
                    }
                    Write-Output "1"
                    foreach($userKey in $userKeys) {

                        $sid = $userKey.PSChildName
                        $objSID = $null
                        $userKeyName = $null

                        # Convert SID to Username 
                        try {
                            $objSID = New-Object System.Security.Principal.SecurityIdentifier("$sid") -ErrorAction Stop
                            $userKeyName = $objSID.Translate([ System.Security.Principal.NTAccount]).Value.Split('\')[1]
                        } catch {
                            $ErrorMessage = $_.Exception.Message
                            $FailedItem = $_.Exception.ItemName
                        }   
    
                        if(!$objSID) { continue }

                        try {
                            $reg = Get-ItemProperty -Path "Registry::$($userKey.Name)\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Name 'Favorites' -ErrorAction Stop #-FilePath "C:\Users\mbado\desktop\taskbar\$($User.Name).reg" -Force
                            Write-Output "User Reg Name = $($UserKey.Name)"

                            & REG EXPORT "$($userKey.Name)\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" "$dirDest\$env:COMPUTERNAME\User Regs\$userKeyName.reg" '/y'
                            Write-Output "$dirDest\$env:COMPUTERNAME\User Regs\$userKeyName.reg"

                            #New-Item -Path "C:\Users\mbado\desktop\taskbar\" -Name "$($userKeyName).reg" -Value "$reg" -Force
                        } catch {
                            Write-Output "Reg entry for $($userKey.Name) ($userKeyName) does not exist"
                        }

    
                    }

                    foreach($User in $xUsers) {

                        $null = & REG LOAD "HKU\$($User.Name)" "$($User.FullName)\NTUSER.DAT"

                        if($?) {
                            try {
                                $reg = Get-ItemProperty -Path "Registry::HKEY_USERS\$($User.Name)\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Name 'Favorites' -ErrorAction Stop #-FilePath "C:\Users\mbado\desktop\taskbar\$($User.Name).reg" -Force
                                Write-Output "User Folder Name = $($User.Name)"
                                & REG EXPORT "HKU\$($User.Name)\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" "$dirDest\$env:COMPUTERNAME\User Regs\$($User.Name).reg" '/y'
                                Write-Output "$dirDest\$env:COMPUTERNAME\User Regs\$($User.Name).reg"
                                #New-Item -Path "C:\Users\mbado\desktop\taskbar\" -Name "$($User.Name).reg" -Value "$reg" -Force
                            } catch {
                                Write-Output "Reg entry for $($User.Name) does not exist"
                            }

                            # Unload the Default User registry hive
                            $unloaded = $false
                            $attempts = 0
                            Write-Output "1"
                            while (!$unloaded -and ($attempts -le 5)) {
                                [gc]::Collect() # necessary call to be able to unload registry hive
                                $null = & REG UNLOAD "HKU\$($User.Name)"
                                $unloaded = $?
                                $attempts += 1
                            }
                        }    
                    }

                    # Change reg file to HKEY_CURRENT_USERS
                    $regFiles = Get-ChildItem -Path "$dirDest\$env:COMPUTERNAME\User Regs" -Filter '*.reg'

                    foreach($regFile in $regFiles) {
                        $regContent = Get-Content -Path "$($regFile.FullName)"

                        foreach($line in $regContent) {
                            if ($line -like "*HKEY*") {
                                $lineStrings = $line.split('\')
                                $lineStrings[0] = '[HKEY_CURRENT_USER'
                                $lineStrings[1] = $null
                                $newlineString = [system.String]::Join('\', ($lineStrings[0,2+3..$lineStrings.Count]))
        
                                $regContent = $regContent | ForEach-Object {$_.replace("$line","$newLineString")}
                                $regContent | Out-File -FilePath "$($regFile.FullName)"
                            }
                        }
                    }

                }
				switch ($PSCmdlet.ParameterSetName) {
					Local {
						$ScanState_params = ''
						$dirMigData = '\\hercules\migdata$'
						$dir_ScanState = "$dirMigData\USMT_SCANSTATE"
						$dirDest = "$dir_ScanState\$Year\$($month_number)_$($month)"
						$dirUSMT = "$dirMigData\Backup_Commands\USMT10.0.14393\amd64"
						
						$ScanState_param1 = $ScanState_params += "$dirDest\$env:COMPUTERNAME"
						
						if ($Users) {
							$ScanState_user_param = $ScanState_params += " /ue:*\*"
							
							foreach ($User in $Users) {
								$ScanState_user = $ScanState_params += " /ui:$User"
							}
						}
						
						$ScanState_param2 = $ScanState_params += " /i:$dirUSMT\ed4newtest.xml"
						$ScanState_param3 = $ScanState_params += " /i:$dirUSMT\eddocs.xml"
						$ScanState_param4 = $ScanState_params += " /i:$dirUSMT\migapp.xml"
						
						if (!($Users)) {
							$ScanState_param5 = $ScanState_params += ' /uel:360'
						}
						
						$ScanState_param6 = $ScanState_params += ' /v:13'
						$ScanState_param7 = $ScanState_params += " /l:$dirDest\$env:COMPUTERNAME\scan.log"
						$ScanState_param8 = $ScanState_params += ' /c'
						
						if (!(Test-Path -path "$dirDest\$env:COMPUTERNAME")) {
							New-Item -ItemType directory -Path "$dirDest\$env:COMPUTERNAME"
						} else {
							
							if ($Force) {
								$Renamed = $false
								while (!($Renamed)) {
									try {
										Rename-Item -Path "$dirDest\$env:COMPUTERNAME" -NewName ($env:COMPUTERNAME + '.old' + "$i") -ErrorAction Stop
										$Renamed = $true
										
									} catch {
										$i++
									}
									
								}
							}
						}
						#Write-Output $ScanState_params
						Invoke-Expression "$dirUSMT\scanstate.exe $ScanState_params"
					}
					
					Remote {
						$s = New-PSSession -ComputerName $Computer -Credential $Credential
						Invoke-Command -Session $s -ScriptBlock {
							$Credential = $args[0]
							$Year = $args[1].year
							$Month_number = $args[1].month
							$month = $args[2]
							$Users = $args[3]
							$Force = $args[4]
							
							New-PSDrive -Name 'Migdata' -PSProvider FileSystem -Root '\\hercules\migdata$' -Credential $Credential
							
							$ScanState_params = ''
							$dirMigData = '\\hercules\migdata$'
							$dir_ScanState = "$dirMigData\USMT_SCANSTATE"
							$dirDest = "$dir_ScanState\$year\$($month_number)_$($month)"
							$dirUSMT = "$dirMigData\Backup_Commands\USMT10.0.14393\amd64"
							
							if (!(Test-Path -path "$dirDest\$env:COMPUTERNAME")) {
								New-Item -ItemType directory -Path "$dirDest\$env:COMPUTERNAME"
							} else {
								
								if ($Force) {
									$Renamed = $false
									while (!($Renamed)) {
										try {
											Rename-Item -Path "$dirDest\$env:COMPUTERNAME" -NewName ($env:COMPUTERNAME + '.old' + "$i") -ErrorAction Stop
											$Renamed = $true
											
										} catch {
											$i++
										}
										
									}
								}
							}
							
							$ScanState_param1 = $ScanState_params += "$dirDest\$env:COMPUTERNAME"
							
							if ($Users) {
								$ScanState_user_param = $ScanState_params += " /ue:*\*"
								
								foreach ($User in $Users) {
									$ScanState_user = $ScanState_params += " /ui:$User"
								}
							}
							
							$ScanState_param2 = $ScanState_params += " /i:$dirUSMT\ed4newtest.xml"
							$ScanState_param3 = $ScanState_params += " /i:$dirUSMT\eddocs.xml"
							$ScanState_param4 = $ScanState_params += " /i:$dirUSMT\migapp.xml"
							
							if (!($Users)) {
								$ScanState_param5 = $ScanState_params += ' /uel:360'
							}
							
							$ScanState_param6 = $ScanState_params += ' /v:13'
							$ScanState_param7 = $ScanState_params += " /l:$dirDest\$env:COMPUTERNAME\scan.log"
							$ScanState_param8 = $ScanState_params += ' /c'
							#Write-Output $ScanState_params
							
							Invoke-Expression "$dirUSMT\scanstate.exe $ScanState_params"
							
							
						} -ArgumentList @($Credential, $date, $Month, $Users, $Force)
						
						Remove-PSSession $s
					}
				}
			}
		} catch {
		}
	}
	end {
		try {
		} catch {
		}
	}
}
<#
if ($Local) {
	#Write-Output $PSBoundParameters
	if ($PSBoundParameters.ContainsKey('Force')) {
		USMT-ScanstateTaskBar -Users $Users -Force
	} else {
		USMT-ScanstateTaskBar -Users $Users
	}
}

if ($PSBoundParameters.ContainsKey('ComputerName')) {
	if ($PSBoundParameters.ContainsKey('Force')) {
		USMT-ScanstateTaskBar -ComputerName $ComputerName -Users $Users -Credential $Credential -Force
	} else {
		USMT-ScanstateTaskBar -ComputerName $ComputerName -Users $Users -Credential $Credential
	}
}
#>