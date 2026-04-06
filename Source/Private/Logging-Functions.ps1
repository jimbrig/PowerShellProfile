# Logging-Functions.ps1
# Functions for logging during profile initialization

function Write-ProfileLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$Component = "General",

        [Parameter()]
        [string]$LogPath
    )

    $timestamp = Get-Date -Format "HH:mm:ss.fff"

    # If we have a stopwatch, include elapsed time
    if ($Global:mainStopwatch) {
        $elapsed = $Global:mainStopwatch.Elapsed.TotalSeconds
        $entry = "$timestamp [$Component] ($elapsed s): $Message"
    } else {
        $entry = "$timestamp [$Component]: $Message"
    }

    # Add to global log array if it exists
    if ($Global:debugLog -is [System.Collections.ArrayList] -or $Global:debugLog -is [array]) {
        $Global:debugLog += $entry
    }

    # Write to console with verbose stream
    Write-Verbose $entry

    # Write to log file if path is provided
    if ($LogPath) {
        $entry | Out-File -FilePath $LogPath -Append
    }
}

function Initialize-DebugLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogPath
    )

    # Create or clear the log file
    "" | Out-File -FilePath $LogPath -Force

    # Initialize the global log array
    $Global:debugLog = @()

    # Start the main stopwatch for timing
    $Global:mainStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Log initial system information
    Write-ProfileLog -Message "Starting profile debugging" -Component "System" -LogPath $LogPath
    Write-ProfileLog -Message "PowerShell Version: $($PSVersionTable.PSVersion)" -Component "System" -LogPath $LogPath
    Write-ProfileLog -Message "OS: $([System.Environment]::OSVersion.VersionString)" -Component "System" -LogPath $LogPath
    Write-ProfileLog -Message "Host: $($Host.Name)" -Component "System" -LogPath $LogPath
}

function Measure-ProfileBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [hashtable]$Timings,

        [Parameter()]
        [switch]$Silent
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        & $ScriptBlock
    }
    catch {
        Write-Warning "Error in block '$Name': $_"
        if ($Global:debugLog) {
            Write-ProfileLog -Message "Error in block '$Name': $_" -Component "Error"
        }
        throw
    }
    finally {
        $sw.Stop()
    }

    # Store timing if hashtable is provided
    if ($Timings -is [hashtable]) {
        $Timings[$Name] = $sw.Elapsed
    }

    # Output timing information unless silent
    if (-not $Silent) {
        Write-Host "  $Name completed in $($sw.Elapsed.TotalSeconds) seconds" -ForegroundColor Green
    }

    # Log timing if debug logging is enabled
    if ($Global:debugLog) {
        Write-ProfileLog -Message "$Name took $($sw.Elapsed.TotalSeconds) seconds" -Component "Timing"
    }
}
