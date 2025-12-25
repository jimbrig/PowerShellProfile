$out = "network_diagnosis_$(Get-Date -Format yyyyMMdd_HHmmss).txt"
function Run($title, [ScriptBlock]$sb) {
    "===== $title =====" | Out-File $out -Append -Encoding utf8
    try {
        & $sb 2>&1 | Out-File $out -Append -Encoding utf8
    } catch {
        $_ | Out-File $out -Append -Encoding utf8
    }
    '' | Out-File $out -Append -Encoding utf8
}

Run 'Timestamp and Host' { Get-Date; hostname; Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber }
Run 'Get-NetAdapter (all)' { Get-NetAdapter -IncludeHidden | Select-Object Name, InterfaceDescription, InterfaceAlias, Status, LinkSpeed, MacAddress, MediaConnectionState, ifIndex, InterfaceOperationalStatus | Format-List * }
Run 'Physical Adapters' { Get-NetAdapter -Physical | Select-Object Name, InterfaceDescription, InterfaceAlias, Status, LinkSpeed, MacAddress, MediaConnectionState, ifIndex | Format-Table -AutoSize }
Run 'Identify likely Ethernet and Wi-Fi adapters' { Get-NetAdapter -Physical | Select-Object Name, InterfaceDescription, InterfaceAlias, Status, LinkSpeed, MacAddress, ifIndex | Where-Object { $_.InterfaceDescription -match 'Ethernet|LAN' -or $_.Name -match 'Ethernet|LAN|eth' -or $_.InterfaceAlias -match 'Ethernet' -or $_.InterfaceDescription -match 'Wireless|Wi-Fi|WLAN' -or $_.Name -match 'Wi-Fi|Wireless|WLAN' } | Format-Table -AutoSize }
Run 'IP Configuration (all)' { Get-NetIPConfiguration -All | Format-List * }
Run 'IP Addresses' { Get-NetIPAddress | Select-Object InterfaceIndex, InterfaceAlias, AddressFamily, IPAddress, PrefixLength, AddressState | Format-Table -AutoSize }
Run 'IP Interfaces' { Get-NetIPInterface | Select-Object ifIndex, InterfaceAlias, AddressFamily, Dhcp, RouterDiscovery, NeighborDiscovery, NetAdapterInterfaceDescr, AutoconfigurationEnabled, ConnectionState | Format-Table -AutoSize }
Run 'Routes' { Get-NetRoute | Sort-Object DestinationPrefix | Format-Table -AutoSize }
Run 'DNS Client Server Addresses' { Get-DnsClientServerAddress | Format-List * }
Run 'Adapter Statistics' { Get-NetAdapterStatistics | Format-List * }
Run 'Adapter Advanced Properties' { Get-NetAdapterAdvancedProperty -AllProperties | Format-List * }
Run 'Adapter Bindings' { Get-NetAdapterBinding -IncludeAll | Format-List * }
Run 'PNP Network Devices' { Get-PnpDevice -Class Net | Select-Object Status, FriendlyName, InstanceId, Manufacturer | Format-List * }
Run 'Network Adapter Drivers (WMI)' { Get-CimInstance Win32_NetworkAdapter | Select-Object Name, NetConnectionStatus, Manufacturer, PNPDeviceID, MACAddress, NetEnabled | Format-List * }
Run 'Firewall Profiles' { Get-NetFirewallProfile | Format-List * }
Run 'Windows Event Log (last 7 days, network-related messages)' { $tf = (Get-Date).AddDays(-7); Get-WinEvent -FilterHashtable @{LogName = 'System'; StartTime = $tf } | Where-Object { $_.Message -match '(?i)ethernet|network adapter|network|NIC|link|dhcp|driver|media disconnected|media connected|wlan|wifi' } | Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message | Format-List * }
Run 'ipconfig /all' { ipconfig /all }
Run 'netsh interface show interface' { netsh interface show interface }
Run 'netsh interface ip show config' { netsh interface ip show config }
Run 'ARP table' { arp -a }
$ethAdapters = Get-NetAdapter -Physical | Where-Object { $_.InterfaceDescription -match 'Ethernet|LAN' -or $_.Name -match 'Ethernet|LAN|eth' -or $_.InterfaceAlias -match 'Ethernet' }
$wifiAdapters = Get-NetAdapter -Physical | Where-Object { $_.InterfaceDescription -match 'Wireless|Wi-Fi|WLAN' -or $_.Name -match 'Wi-Fi|Wireless|WLAN' -or $_.InterfaceAlias -match 'Wi-Fi|Wireless|WLAN' }
Run 'Detected Ethernet Adapters' { $ethAdapters | Select-Object Name, InterfaceDescription, InterfaceAlias, Status, LinkSpeed, ifIndex | Format-Table -AutoSize }
Run 'Detected Wi-Fi Adapters' { $wifiAdapters | Select-Object Name, InterfaceDescription, InterfaceAlias, Status, LinkSpeed, ifIndex | Format-Table -AutoSize }
function TestForAdapter($adapter) {
    $cfg = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
    if ($null -ne $cfg) {
        $gw = $cfg.IPv4DefaultGateway.NextHop
        "Interface: $($adapter.Name) (ifIndex $($adapter.ifIndex))" | Out-Output
        "Status: $($adapter.Status)" | Out-Output
        "LinkSpeed: $($adapter.LinkSpeed)" | Out-Output
        "IPv4 Addresses: $($cfg.IPv4Address.IPAddress -join ', ')" | Out-Output
        "IPv6 Addresses: $($cfg.IPv6Address.IPAddress -join ', ')" | Out-Output
        "DNS Servers: $($cfg.DnsServer.ServerAddresses -join ', ')" | Out-Output
        if ($gw) {
            Run "Ping gateway for adapter $($adapter.Name) ($gw)" { Test-NetConnection -ComputerName $gw -InformationLevel Detailed }
        } else {
            "No IPv4 gateway detected for adapter $($adapter.Name)" | Out-File $out -Append -Encoding utf8
        }
        Run "Ping 8.8.8.8 from system (for adapter $($adapter.Name))" { Test-NetConnection -ComputerName 8.8.8.8 -InformationLevel Detailed }
        Run "Ping google.com (DNS + connectivity) from system (for adapter $($adapter.Name))" { Test-NetConnection -ComputerName google.com -InformationLevel Detailed }
        Run 'Resolve DNS for google.com' { Resolve-DnsName google.com -ErrorAction SilentlyContinue }
        Run 'Trace route to google.com' { Test-NetConnection -ComputerName google.com -TraceRoute -InformationLevel Detailed }
    } else {
        "No IP configuration found for adapter $($adapter.Name)" | Out-File $out -Append -Encoding utf8
    }
}
function Out-Output($text) { $text | Out-File $out -Append -Encoding utf8 }
foreach ($a in $ethAdapters) { TestForAdapter $a }
foreach ($a in $wifiAdapters) { TestForAdapter $a }
Run 'Compare Ethernet vs Wi-Fi default gateway and DNS' { $ethAdapters | ForEach-Object { Get-NetIPConfiguration -InterfaceIndex $_.ifIndex | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DnsServer } ; $wifiAdapters | ForEach-Object { Get-NetIPConfiguration -InterfaceIndex $_.ifIndex | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DnsServer } }
Run 'Check interface administrative state' { Get-NetAdapter | Select-Object Name, ifIndex, Status, AdminStatus, MediaConnectionState | Format-Table -AutoSize }
Run 'List network services status (DHCP client, DNS client, NetBT)' { Get-Service Dnscache, Dhcp, 'NetBT' -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType | Format-Table -AutoSize }
Run 'Output saved to' { $out }
