<#
    .SYNOPSIS
        Registers Azure Developer CLI (azd) shell completion for PowerShell
    .LINK
        https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/
#>

if (Get-Command azd -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression -Command $(azd completion powershell | Out-String)
        Write-Verbose 'Azure Developer CLI (azd) shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register Azure Developer CLI shell completion: $_"
    }
} else {
    Write-Debug 'azd command not found; skipping Azure Developer CLI completion registration.'
}
