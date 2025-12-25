<#
    .SYNOPSIS
        Registers oh-my-posh shell completion for PowerShell
    .LINK
        https://ohmyposh.dev/docs/installation/powershell
#>

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression -Command $(oh-my-posh completion powershell | Out-String)
        Write-Verbose 'oh-my-posh shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register oh-my-posh shell completion: $_"
    }
} else {
    Write-Debug 'oh-my-posh command not found; skipping oh-my-posh completion registration.'
}
