<#
    .SYNOPSIS
        Registers yq (YAML CLI) shell completion for PowerShell
    .LINK
        https://mikefarah.gitbook.io/yq/commands/shell-completion#powershell
#>

if (Get-Command yq -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression -Command $(yq shell-completion powershell | Out-String)
        Write-Verbose 'yq shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register yq shell completion: $_"
    }
} else {
    Write-Debug 'yq command not found; skipping yq completion registration.'
}
