Function Reset-NetworkAdapter() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]$Interface
    )

    netsh.exe interface set interface $Interface admin=disable
    netsh.exe interface set interface $Interface admin=enable
}
