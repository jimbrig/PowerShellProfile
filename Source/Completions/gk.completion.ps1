<#
    .SYNOPSIS
        Registers GitKraken CLI Tab Completion for PowerShell
    .LINK
        https://gitkraken.github.io/gk-cli/docs/gk_completion.html
#>

if (Get-Command gk -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression -Command $(gk completion powershell | Out-String)
        Write-Verbose 'GitKraken CLI shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register GitKraken CLI shell completion: $_"
    }
} else {
    Write-Debug 'gk command not found; skipping GitKraken CLI completion registration.'
}
