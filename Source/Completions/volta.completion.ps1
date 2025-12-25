<#
    .SYNOPSIS
        Registers Volta shell completion for PowerShell
    .LINK
        https://docs.volta.sh/guide/
#>

if (Get-Command volta -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression -Command $(volta completions powershell | Out-String)
        Write-Verbose 'Volta shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register Volta shell completion: $_"
    }
} else {
    Write-Debug 'volta command not found; skipping Volta completion registration.'
}
