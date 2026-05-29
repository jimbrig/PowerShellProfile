# Write-ProfileLog.ps1
# Writes a log entry for profile loading.

Function Write-ProfileLog {
    <#
    .SYNOPSIS
        Writes a log entry for profile loading.
    .DESCRIPTION
        This function writes a log entry with a timestamp, component name, and message. If a global stopwatch is available,
        it includes elapsed time since the profile loading started. The log entry is written to the verbose stream and optionally to a log file.
    .PARAMETER Message
        The log message to write.
    .PARAMETER Component
        The component name associated with the log message. Default is 'General'.
    .PARAMETER LogPath
        Optional path to a log file where the entry will be appended.
    .EXAMPLE
        Write-ProfileLog -Message "Loaded Aliases component." -Component "Aliases"
    .EXAMPLE
        Write-ProfileLog -Message "Profile loading started." -LogPath "Profile.log"
        This will write the log entry to the specified log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$Component = 'General',

        [Parameter()]
        [ValidateSet('Verbose', 'Debug', 'Information', 'Warning', 'Error', 'Fatal')]
        [string]$Stream = 'Verbose',

        [Parameter()]
        [switch]$Console,

        [Parameter()]
        [string]$LogPath
    )

    $timestamp = Get-Date -Format 'HH:mm:ss.fff'

    # If we have a stopwatch, include elapsed time
    if ($Global:Stopwatch) {
        $elapsed = $Global:Stopwatch.Elapsed.TotalSeconds
        $entry = "$timestamp [$Component] ($elapsed s): $Message"
    } else {
        $entry = "$timestamp [$Component]: $Message"
    }

    # Add to global log array if it exists
    if ($Global:DebugLog -is [System.Collections.ArrayList] -or $Global:DebugLog -is [array]) {
        $Global:DebugLog += $entry
    }

    if ($Console) {
        Write-Host $entry -ForegroundColor White
    }

    # Write to console with verbose stream
    switch ($Stream) {
        'Verbose' { Write-Verbose $entry }
        'Debug' { Write-Debug $entry }
        'Information' { Write-Information $entry }
        'Warning' { Write-Warning $entry }
        'Error' { Write-Error $entry }
        'Fatal' { Write-Fatal $entry }
    }

    # Write to log file if path is provided
    if ($LogPath) {
        $entry | Out-File -FilePath $LogPath -Append
    }
}
