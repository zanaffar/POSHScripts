$SiteServer = 'wlb-sysctr-02'
$Site = 'MU1'

$CCMAgent = Get-WmiObject -ComputerName "$SiteServer" -Namespace "root\sms\site_$Site" -Class 'SMS_SCI_ClientComp' | Where-Object {$_.ClientComponentName -eq 'Configuration Management Agent'}
$CCMAgent.Get()
$props = $CCMAgent.Props

for ($i = 0; $i -lt $props.count; $i++) {
    if ($props[$i].PropertyName -eq "ScriptExecutionTimeout") {
            $props[$i].Value = 601
            break
    }
}

$CCMAgent.Props = $Props
$CCMAgent.Put()