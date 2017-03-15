New-PSDrive -Name 'Logs' -PSProvider FileSystem -Root \\wlb-sysctr-02\RemoteControl$

Write-Output (& 'ipconfig' '/all') | Out-File -FilePath "Logs:\$env:COMPUTERNAME.txt"