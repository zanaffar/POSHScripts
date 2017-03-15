Add-Type @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {

    public static class UserInput {

        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@

#for ( $i = 0; $i -lt 10; $i++ ) {
#    Write-Host ("Last input " + [PInvoke.Win32.UserInput]::LastInput)
#    Write-Host ("Idle for " + [PInvoke.Win32.UserInput]::IdleTime)
#    Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5)
#}

$Last = [PInvoke.Win32.UserInput]::LastInput
$Idle = [PInvoke.Win32.UserInput]::IdleTime
$LastStr = $Last.ToLocalTime().ToString('MM/dd/yyyy hh:mm tt')
$lPath = 'C:\Logs\' + $env:COMPUTERNAME + '.log'
New-Item -Path $lPath -Force
#Write-Output ('Current User: ' + $env:USERNAME)
#Write-Output ('Last user keyboard/mouse input: ' + $LastStr)
#Write-Output ('Idle for: ' + [PInvoke.Win32.UserInput]::IdleTime)

Write-Output ('Current User - ' + $env:USERNAME) | Out-File -FilePath $lPath -Append
Write-Output ('Last user keyboard/mouse input - ' + $LastStr) | Out-File -FilePath $lPath -Append
Write-Output ('Idle for - ' + $Idle.Days + ' days, ' + $Idle.Hours + ' hours, ' + $Idle.Minutes + ' minutes, ' + $Idle.Seconds + ' seconds.') | Out-File -FilePath $lPath -Append
Write-Output ('Idle for - ' + [PInvoke.Win32.UserInput]::IdleTime) | Out-File -FilePath $lPath -Append

$strResult = Get-Content -Path $lPath
$strUserName = ($strResult[0].Split("-"))[1].Trim()
$strLastInput = ($strResult[1].Split("-"))[1].Trim()
$strIdleTime = ($strResult[2].Split("-"))[1].Trim()

$objLastInput = [datetime]$strLastInput
$objIdleTime = [PSCustomObject]@{
    IdleTimeString = $strIdleTime
    IdleTime = ((Get-Date) - $objLastInput)
}

$objUser = New-Object System.Security.Principal.NTAccount("$strUserName")
$strSID = ($objUser.Translate([System.Security.Principal.SecurityIdentifier]).Value)
$objSID = New-Object System.Security.Principal.SecurityIdentifier("$strSID")
$objDomainUser = $objSID.Translate([ System.Security.Principal.NTAccount])

$objResult = [PSCustomObject]@{
    User = $objUser
    DomainUser = $objDomainUser
    SID = $objSID
    UserName = $strUserName
    LastInput = $objLastInput | Get-Date -Format G
    IdleTimeString = $objIdleTime.IdleTimeString
    IdleTime = $objIdleTime
}