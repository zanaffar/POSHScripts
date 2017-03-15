$SiteServer = 'wlb-sysctr-02'
$Site = 'MU1'

$CCMAgent = Get-CimInstance -ComputerName "$SiteServer" -Namespace "Root/SMS/Site_$Site" -ClassName 'SMS_SCI_ClientComp' -Filter "ClientComponentName = 'Configuration Management Agent'"

$props = $CCMAgent.Props

for ($i = 0; $i -lt $props.count; $i++) {
    if ($props[$i].PropertyName -eq "ScriptExecutionTimeout") {
            $props[$i].Value = 602
            break
    }
}

$CCMAgent.Props = $Props
Set-CimInstance -InputObject $CCMAgent