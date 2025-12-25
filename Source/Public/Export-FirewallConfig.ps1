<#
    .SYNOPSIS
        Exports the current firewall configuration to a file.
    .DESCRIPTION
        Exports the current firewall configuration to a file.
    .PARAMETER OutputPath
        The path to export the firewall configuration to.
        Defaults to `Desktop\FirewallConfig.wfw` for the active user.
    .EXAMPLE
        Export-FirewallConfig -OutputPath "$env:USERPROFILE\Desktop\FirewallConfig.wfw"
#>
Function Export-FirewallConfig {
    #Requires -RunAsAdministrator
    [CmdletBinding()]
    param(
        [string]$OutputPath = "$env:USERPROFILE\Desktop\FirewallConfig.wfw"
    )

    try {
        netsh advfirewall export $OutputPath
        Write-Host "Firewall configuration exported to $OutputPath" -ForegroundColor Green
    } catch {
        Write-Error "Failed to export firewall configuration: $_"
    }

}
