$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$nic = Get-WmiObject win32_networkadapterconfiguration -Filter 'ipenabled = "true"'


$nicArray = @(
"Intel(R) Ethernet Connection (3) I218-LM",
"Linksys Wireless-N USB Network Adapter WUSB300N",
"Broadcom 4313GN 802.11b/g/n 1x1 Wi-Fi Adapter",
"Intel(R) 82566DM-2 Gigabit Network Connection",
"Broadcom 802.11abgn Wireless SDIO Adapter",
"NVIDIA nForce 10/100/1000 Mbps Ethernet",
"Intel(R) Centrino(R) Advanced-N 6200 AGN",
"Intel(R) Centrino(R) Wireless-N 1030",
"Intel(R) 82567LM-3 Gigabit Network Connection",
"Intel(R) Ethernet X520 10GbE Dual Port KX4-KR Mezz",
"Intel(R) Dual Band Wireless-AC 7265",
"Intel(R) 82578DM Gigabit Network Connection",
"Intel(R) PRO/1000 XT Server Adapter",
"Intel(R) 82577LM Gigabit Network Connection",
"Realtek RTL8168D/8111D Family PCI-E Gigabit Ethernet NIC (NDIS 6.20)",
"ASIX AX88179 USB 3.0 to Gigabit Ethernet Adapter",
"Surface Ethernet Adapter",
"DisplayLink USB Gigabit Network Adapter",
"Intel(R) Centrino(R) Advanced-N 6205",
"Intel(R) 82579V Gigabit Network Connection",
"Intel(R) PRO/1000 MT Desktop Adapter",
"Intel(R) Ethernet Connection (2) I218-LM",
"Realtek RTL8139 Family PCI Fast Ethernet NIC",
"Broadcom BCM5708C NetXtreme II GigE (NDIS VBD Client)",
"Wireless G USB Adapter",
"Atheros AR8161/8165 PCI-E Gigabit Ethernet Controller (NDIS 6.20)",
"Intel(R) PRO/Wireless 2200BG Network Connection",
"Belkin USB Wireless Adaptor",
"Broadcom BCM943228HMB 802.11abgn 2x2 Wi-Fi Adapter",
"Ralink RT5390R 802.11b/g/n 1x1 Wi-Fi Adapter",
"Marvell Yukon 88E8072 PCI-E Gigabit Ethernet Controller",
"D-Link DGE-530T Gigabit Ethernet Adapter",
"Intel(R) Centrino(R) Ultimate-N 6300 AGN",
"Generic Marvell Yukon 88E8072 based Ethernet Controller",
"Realtek RTL8168B/8111B Family PCI-E Gigabit Ethernet NIC (NDIS 6.20)",
"Intel(R) Centrino(R) Advanced-N 6230",
"Broadcom BCM5709S NetXtreme II GigE (NDIS VBD Client)",
"Qualcomm Atheros AR9485 802.11b/g/n WiFi Adapter",
"Intel(R) WiFi Link 5100 AGN",
"Broadcom NetXtreme Gigabit Ethernet",
"Atheros AR9485 Wireless Network Adapter",
"Apple Mobile Device Ethernet",
"Intel(R) Ethernet Connection I217-V",
"Realtek RTL8188EE 802.11 b/g/n Wi-Fi Adapter",
"Microsoft Hyper-V Network Adapter",
"Intel 21140-Based PCI Fast Ethernet Adapter (Emulated)",
"Intel(R) Ethernet Connection I217-LM",
"Hyper-V Virtual Ethernet Adapter")

$nicString = [string]$nic.description

foreach ($element in $nicArray) {
    $nicName = [string]$element
    if ($nicString -eq $nicName) {        
            .\nvspbind.exe -d $nicName ms_tcpip6
        }
    
}

#ipconfig /release
#ipconfig /renew
