$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

cd $dir
. .\Get-PendingUpdate.ps1
Get-PendingUpdate -Computer localhost