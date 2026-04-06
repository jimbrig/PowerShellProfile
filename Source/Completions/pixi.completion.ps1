<#
    .SYNOPSIS
        Registers Pixi CLI Tab Completion for PowerShell
    .LINK
        https://pixi.prefix.dev/v0.62.2/installation/#__tabbed_3_3
#>

if (Get-Command pixi -ErrorAction SilentlyContinue) {
    try {
        (& pixi completion --shell powershell) | Out-String | Invoke-Expression
        Write-Verbose 'Pixi CLI shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register Pixi CLI shell completion: $_"
    }
} else {
    Write-Debug 'pixi command not found; skipping Pixi CLI completion registration.'
}
