$SearchDir = 'C:\Windows'

Write-Output ''
Write-Output 'Starting GC search ...'
$GC_Time = Measure-Command {$GC_FileList = Get-ChildItem $SearchDir -file -Recurse}
Write-Output "Total seconds = $($GC_Time.TotalSeconds)"
Write-Output "Item count    = $($GC_FileList.Count)"
Write-Output ''

Write-Output 'Starting SIOD search ...'
$SIOD_Time = Measure-Command {$SIOD_FileList = [System.IO.Directory]::EnumerateFiles($SearchDir, '*.*', 'AllDirectories')}
Write-Output "Total seconds = $($SIOD_Time.TotalSeconds)"
Write-Output "Item count    = $(($SIOD_FileList | Measure-Object).Count)"
Write-Output ''

Write-Output 'Starting RC search ...'
$RC_Time = Measure-Command {$RC_FileList = robocopy $SearchDir a: /NODD /MIR /FP /NC /NDL /NJH /NJS /L /NP /NS }
Write-Output "Total seconds = $($RC_Time.TotalSeconds)"
Write-Output "Item count    = $($RC_FileList.Count)"
Write-Output ''


Write-Output 'Time relative to GC ...'
$RC_Ratio = "{0, 10:N2}" -f ($GC_Time.TotalSeconds / $RC_Time.TotalSeconds)
Write-Output "    RC   = $RC_Ratio"
$SIOD_Ratio = "{0, 10:N2}" -f ($GC_Time.TotalSeconds / $SIOD_Time.TotalSeconds)
Write-Output "    SIOD = $SIOD_Ratio"