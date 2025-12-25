<#
    .SYNOPSIS
        Registers rig (R Installation Manager) shell completion for PowerShell
    .LINK
        https://github.com/r-lib/rig
#>

if (Get-Command rig -Type Application -ErrorAction SilentlyContinue) {
    $RigInstallPath = Split-Path -Path (Get-Command rig).Source -Parent
    $RigCompletion = Join-Path -Path $RigInstallPath -ChildPath '_rig.ps1'

    if (Test-Path -Path $RigCompletion -PathType Leaf) {
        try {
            & $RigCompletion
            Write-Verbose 'rig shell completion registered successfully.'
        } catch {
            Write-Warning "Failed to register rig shell completion: $_"
        }
    } else {
        Write-Debug 'rig completion script not found; skipping rig completion registration.'
    }

    Remove-Variable -Name RigInstallPath, RigCompletion -ErrorAction SilentlyContinue
} else {
    Write-Debug 'rig command not found; skipping rig completion registration.'
}
