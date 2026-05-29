Function Reset-NetworkStack() {
    [CmdletBinding()]
    param (
    )

    netsh.exe winsock reset
    netsh.exe int ip reset
    netsh.exe int ipv4 reset reset.log
    netsh.exe int ipv6 reset reset.log
    Write-Output "[-] You will need to restart this computer."
}
