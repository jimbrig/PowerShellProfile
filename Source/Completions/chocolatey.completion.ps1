<#
    .SYNOPSIS
        Registers Chocolatey shell completion for PowerShell
    .LINK
        https://docs.chocolatey.org/en-us/choco/commands/
#>

if (Get-Command choco -ErrorAction SilentlyContinue) {
    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path $ChocolateyProfile -PathType Leaf) {
        try {
            Import-Module $ChocolateyProfile -ErrorAction Stop
            Write-Verbose 'Chocolatey profile module imported successfully.'
        } catch {
            Write-Warning "Failed to import Chocolatey profile module: $_"
        }
    } else {
        Write-Debug 'Chocolatey profile module not found; skipping Chocolatey completion registration.'
    }
} else {
    Write-Debug 'choco command not found; skipping Chocolatey completion registration.'
}
