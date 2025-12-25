
$FirewallData = Import-PowerShellDataFile -Path "$PSScriptRoot\..\Configuration\FirewallRules.psd1"

$ProgramRules = $FirewallData.Programs # will get rules setup to allow for both inbound and outbound
$Ports = $FirewallData.Ports           # will get rules setup to allow for both inbound and outbound (-Protocol TCP)
