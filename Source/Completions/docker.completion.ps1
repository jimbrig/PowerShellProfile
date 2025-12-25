<#
    .SYNOPSIS
        Registers Docker shell completion for PowerShell
    .LINK
        https://github.com/matt9ucci/DockerCompletion
#>

if (Get-Command docker -ErrorAction SilentlyContinue) {
    if (Get-InstalledPSResource -Name DockerCompletion -ErrorAction SilentlyContinue) {
        try {
            Import-Module DockerCompletion -ErrorAction Stop
            Write-Verbose 'DockerCompletion module imported successfully.'
        } catch {
            Write-Warning "Failed to import DockerCompletion module: $_"
        }
    } else {
        Write-Debug 'DockerCompletion module not installed; skipping Docker completion registration.'
    }
} else {
    Write-Debug 'docker command not found; skipping Docker completion registration.'
}
