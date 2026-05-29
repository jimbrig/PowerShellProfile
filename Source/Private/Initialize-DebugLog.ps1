# Initialize-DebugLog.ps1
# Initializes the debug log file.

Function Initialize-DebugLog {
    <#
    .SYNOPSIS
        Initializes the debug log file.
    .DESCRIPTION
        This function initializes the debug log file and starts the stopwatch.
    .PARAMETER LogPath
        The path to the debug log file.
    .EXAMPLE
        Initialize-DebugLog -LogPath "C:\Logs\DebugLog.log"
        This will initialize the debug log file and start the stopwatch.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogPath
    )

    if (-not(is.null($LogPath) -or $LogPath -eq '')) {
        '' | Out-File -FilePath $LogPath -Force
    }

    $Global:DebugLog = @()
    $Global:Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-ProfileLog -Message 'Starting profile debugging' -Component 'System' -LogPath $LogPath
    Write-ProfileLog -Message "PowerShell Version: $($PSVersionTable.PSVersion)" -Component 'System' -LogPath $LogPath
    Write-ProfileLog -Message "OS: $([System.Environment]::OSVersion.VersionString)" -Component 'System' -LogPath $LogPath
    Write-ProfileLog -Message "Host: $($Host.Name)" -Component 'System' -LogPath $LogPath
}
