# Stop Cisco Processes and Service
Stop-Service -Name vpnagent -Force
Stop-Process -Name vpnagent, vpnui, msiexec  -Force

# Delete the Cisco folder from Program Files
Remove-Item -Path ${env:ProgramFiles(x86)}\Cisco -Force

# Clean up the Registry
Remove-ItemProperty -Path 'HKEY_CLASSES_ROOT:\CLSID\{548A1F06-AECE-4506-8ABB-5E3D3A99B67B}' -Name 'InProcServer32\C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnapi.dll' -Force
Remove-ItemProperty -Path 'HKEY_CLASSES_ROOT:\CLSID\{C15C0F4F-DDFB-4591-AD53-C9A71C9C15C0}' -Name 'InProcServer32\C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnapi.dll' -Force
Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store' -Name 'C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnui.exe' -Force
Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Installer\Folders' -Name 'C:\Program Files (x86)\Cisco\Cisco AnyConnect VPN Client' -Force
Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Installer\Folders' -Name 'C:\Program Files (x86)\Cisco' -Force
Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Installer\Folders' -Name 'C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client' -Force
Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Installer\Folders' -Name 'C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\res' -Force
Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Installer\Folders' -Name 'C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\Plugins' -Force
Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Cisco AnyConnect Secure Mobility Client' -Name 'C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\Uninstall.exe -remove' -Force
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name '"C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnui.exe"' -Force
Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\services\vpnagent' -Name 'ImagePath - "c:\program files (x86)\cisco\cisco anyconnect secure mobility client\vpnagent.exe"' -Force