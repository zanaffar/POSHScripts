## Read Primary User from WMI ##

$UDA_Users = (Get-CimInstance -Namespace 'root/ccm/Policy/Machine/ActualConfig' -ClassName 'CCM_UserAffinity').ConsoleUser

(Get-CimInstance -ComputerName 'MU53892' -Namespace 'root/ccm/Policy/Machine/ActualConfig' -ClassName 'CCM_UserAffinity').ConsoleUser | ForEach-Object {$_.split('\')[1]}