<#
    .SYNOPSIS
        Registers Obsidian CLI shell completion for PowerShell
    .LINK
        https://github.com/Yakitrak/obsidian-cli
#>

if (Get-Command obsidian-cli -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression -Command $(obsidian-cli completion powershell | Out-String)
        Write-Verbose 'Obsidian CLI shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register Obsidian CLI shell completion: $_"
    }
} else {
    Write-Debug 'obsidian-cli command not found; skipping Obsidian CLI completion registration.'
}
