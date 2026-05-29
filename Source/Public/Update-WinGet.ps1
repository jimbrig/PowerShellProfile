Function Update-WinGet {
    [CmdletBinding()]
    Param(
        [Switch]$Admin,
        [Switch]$Interactive
    )

    try {
        if (Get-PSResource -Name WingetTools -ErrorAction SilentlyContinue) {
            Import-Module WingetTools
        } else {
            Install-Module WingetTools -Force -SkipPublisherCheck
        }

        if ($Interactive) {
            Write-Host 'Launching Interactive Winget Upgrade...' -ForegroundColor Cyan
            Get-WGUpgrade | Out-ConsoleGridView | Invoke-WGUpgrade
        } else {
            winget upgrade --all
        }
    } catch {
        Write-Error "Failed to update WinGet: $_"
    }
}
