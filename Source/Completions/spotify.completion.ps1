<#
    .SYNOPSIS
        Registers Spotify TUI (spt) shell completion for PowerShell
    .LINK
        https://github.com/Rigellute/spotify-tui
#>

if (Get-Command spt -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression -Command $(spt --completions power-shell | Out-String)
        Write-Verbose 'Spotify TUI (spt) shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register Spotify TUI shell completion: $_"
    }
} else {
    Write-Debug 'spt command not found; skipping Spotify TUI completion registration.'
}
