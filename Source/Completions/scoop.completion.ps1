<#
    .SYNOPSIS
        Registers scoop shell completion for PowerShell
    .LINK
        https://scoop.sh/
#>

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    if (Get-InstalledPSResource -Name scoop-completion -ErrorAction SilentlyContinue) {
        try {
            Import-Module scoop-completion -ErrorAction Stop
            Write-Verbose 'scoop-completion module imported successfully.'
        } catch {
            Write-Warning "Failed to import scoop-completion module: $_"
        }
    } else {
        Write-Debug 'scoop-completion module not installed; skipping scoop completion registration.'
    }
} else {
    Write-Debug 'scoop command not found; skipping scoop completion registration.'
}
