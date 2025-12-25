<#
    .SYNOPSIS
        Registers s-search shell completion for PowerShell
    .LINK
        https://github.com/zquestz/s
#>

if (Get-Command s -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression -Command $(s --completion powershell | Out-String)
        Write-Verbose 's-search shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register s-search shell completion: $_"
    }
} else {
    Write-Debug 's command not found; skipping s-search completion registration.'
}
