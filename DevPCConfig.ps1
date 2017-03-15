<#
Before running make sure WMF 5.0 and xOneGet has been installed:
http://gallery.technet.microsoft.com/DSC-Resource-Kit-All-c449312d (unpack xPSDesiredStateConfiguration resources)
Install-Module xOneGet -Scope AllUsers
#>
Configuration DevPCConfig
{ 
    param ($MachineName, $CurrentUserSID)
 
    Import-DscResource -Name MSFT_xOneGet -ModuleName xOneGet
    Import-DscResource -Name MSFT_xWindowsOptionalFeature -ModuleName xPSDesiredStateConfiguration
    #Import-DscResource -Name PSHOrg_cPSGet -ModuleName cPSGet

    Node $MachineName 
    { 
        xWindowsOptionalFeature IIS-WebServerRole
        {
            Name   = "IIS-WebServerRole"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-WebServer
        {
            Name   = "IIS-WebServer"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-CommonHttpFeatures
        {
            Name   = "IIS-CommonHttpFeatures"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-HttpRedirect
        {
            Name   = "IIS-HttpRedirect"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-BasicAuthentication
        {
            Name   = "IIS-BasicAuthentication"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-WindowsAuthentication
        {
            Name   = "IIS-WindowsAuthentication"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-HttpTracing
        {
            Name   = "IIS-HttpTracing"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-ApplicationDevelopment
        {
            Name   = "IIS-ApplicationDevelopment"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-ISAPIFilter
        {
            Name   = "IIS-ISAPIFilter"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-ISAPIExtensions
        {
            Name   = "IIS-ISAPIExtensions"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature NetFx4Extended-ASPNET45
        {
            Name   = "NetFx4Extended-ASPNET45"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-NetFxExtensibility45
        {
            Name   = "IIS-NetFxExtensibility45"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-ASPNET45
        {
            Name   = "IIS-ASPNET45"
            Ensure = "Enable"
        }
 
        xWindowsOptionalFeature IIS-WebSockets
        {
            Name   = "IIS-WebSockets"
            Ensure = "Enable"
        }
  
        # Configure console sessions
        foreach ($shellPath in 'System32','SysWOW64')
        {
            Registry "ConsoleFaceName_$shellPath"
            {
                Ensure    = "Present"
                Key       = "HKEY_USERS\$CurrentUserSID\Console\%SystemRoot%_${shellPath}_WindowsPowerShell_v1.0_powershell.exe"
                ValueName = "FaceName"
                ValueData = "Consolas"
                ValueType = "String"
            }
            Registry "ConsoleFontFamily_$shellPath"
            {
                Ensure    = "Present"
                Key       = "HKEY_USERS\$CurrentUserSID\Console\%SystemRoot%_${shellPath}_WindowsPowerShell_v1.0_powershell.exe"
                Hex       = $true
                ValueName = "FontFamily"
                ValueData = "0x36"
                ValueType = "DWord"
            }
            Registry "ConsoleFontSize_$shellPath"
            {
                Ensure    = "Present"
                Key       = "HKEY_USERS\$CurrentUserSID\Console\%SystemRoot%_${shellPath}_WindowsPowerShell_v1.0_powershell.exe"
                Hex       = $true
                ValueName = "FontSize"
                ValueData = "0xe0000"
                ValueType = "DWord"
            }
            Registry "ConsoleQuickEdit_$shellPath"
            {
                Ensure    = "Present"
                Key       = "HKEY_USERS\$CurrentUserSID\Console\%SystemRoot%_${shellPath}_WindowsPowerShell_v1.0_powershell.exe"
                Hex       = $true
                ValueName = "QuickEdit"
                ValueData = "0x1"
                ValueType = "DWord"
            }
            Registry "ConsoleScreenBufferSize_$shellPath"
            {
                Ensure    = "Present"
                Key       = "HKEY_USERS\$CurrentUserSID\Console\%SystemRoot%_${shellPath}_WindowsPowerShell_v1.0_powershell.exe"
                Hex       = $true
                ValueName = "ScreenBufferSize"
                ValueData = "0x270f0078"
                ValueType = "DWord"
            }
            Registry "ConsoleWindowSize_$shellPath"
            {
                Ensure    = "Present"
                Key       = "HKEY_USERS\$CurrentUserSID\Console\%SystemRoot%_${shellPath}_WindowsPowerShell_v1.0_powershell.exe"
                Hex       = $true
                ValueName = "WindowSize"
                ValueData = "0x320078"
                ValueType = "DWord"
            }
            Registry "ConsoleScreenColors_$shellPath"
            {
                Ensure    = "Present"
                Key       = "HKEY_USERS\$CurrentUserSID\Console\%SystemRoot%_${shellPath}_WindowsPowerShell_v1.0_powershell.exe"
                Hex       = $true
                ValueName = "ScreenColors"
                ValueData = "0x4f"
                ValueType = "DWord"
            }
            Registry "ConsoleColorTable04_$shellPath"
            {
                Ensure    = "Present"
                Key       = "HKEY_USERS\$CurrentUserSID\Console\%SystemRoot%_${shellPath}_WindowsPowerShell_v1.0_powershell.exe"
                Hex       = $true
                ValueName = "ColorTable04"
                ValueData = "0x32"
                ValueType = "DWord"
            }
            Registry "ConsoleColorTable05_$shellPath"
            {
                Ensure    = "Present"
                Key       = "HKEY_USERS\$CurrentUserSID\Console\%SystemRoot%_${shellPath}_WindowsPowerShell_v1.0_powershell.exe"
                Hex       = $true
                ValueName = "ColorTable05"
                ValueData = "0x00562401"
                ValueType = "DWord"
            }
            Registry "ConsoleColorTable06_$shellPath"
            {
                Ensure    = "Present"
                Key       = "HKEY_USERS\$CurrentUserSID\Console\%SystemRoot%_${shellPath}_WindowsPowerShell_v1.0_powershell.exe"
                Hex       = $true
                ValueName = "ColorTable06"
                ValueData = "0x00f0edee"
                ValueType = "DWord"
            }
        }
 
 <# Will have to wait until this bug is fixed:
    https://connect.microsoft.com/PowerShell/feedback/details/922914/wmf-5-may-preview-powershellget-nuget-exe-wont-launch-when-running-as-system
        cPSGet InstallPscx
        {
            Name   = "Pscx"
            Ensure = "Present"
        }
 
        cPSGet InstallPSReadline
        {
            Name   = "PSReadline"
            Ensure = "Present"
        }
#>
 
        xOneGet InstallDotPeek
        {
            PackageName = "dotPeek"
            Ensure      = "Present"
        }
 
        xOneGet InstallFiddler
        {
            PackageName = "fiddler4"
            Ensure      = "Present"
        }
 
        xOneGet InstallPerfView
        {
            PackageName = "PerfView"
            Ensure      = "Present"
        } 
    } 
} 
 
DevPCConfig -MachineName localhost -CurrentUserSID ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value) 
 