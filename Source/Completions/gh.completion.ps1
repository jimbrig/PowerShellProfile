<#
    .SYNOPSIS
        Registers GitHub CLI (gh) shell completion for PowerShell
    .LINK
        https://cli.github.com/manual/gh_completion
#>

if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression -Command $(gh completion --shell powershell | Out-String)
        Write-Verbose 'GitHub CLI (gh) shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register GitHub CLI shell completion: $_"
    }
} else {
    Write-Debug 'gh command not found; skipping GitHub CLI completion registration.'
}
