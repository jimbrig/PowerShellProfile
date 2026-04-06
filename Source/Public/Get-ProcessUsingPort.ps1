Function Get-ProcessUsingPort {
    <#
    .SYNOPSIS
        Get the process using a specific port.
    .DESCRIPTION
        This function gets the process using a specific port.
    .PARAMETER Port
        The port number.
    .EXAMPLE
        Get-ProcessUsingPort -Port 80

        # Get the process using port 80. Should return the "system" process.
    .LINK
        Get-Proccess
    .LINK
        Get-NetTCPConnection
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [Int]$Port
    )

    Process {
        Get-Process -Id (Get-NetTCPConnection -LocalPort $Port).OwningProcess | Out-More
    }
}
