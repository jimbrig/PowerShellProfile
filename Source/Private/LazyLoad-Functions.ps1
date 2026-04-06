# LazyLoad-Functions.ps1
# Functions for lazy-loading PowerShell completions

function Register-LazyCompletion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    Write-Verbose "Checking if $CommandName is available for immediate completion registration"

    # Check if the command is available
    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        Write-Verbose "$CommandName is not available, skipping completion registration"
        return
    }

    # Resolve the full path to ensure it's captured correctly
    $resolvedScriptPath = $ScriptPath
    if (-not [System.IO.Path]::IsPathRooted($resolvedScriptPath)) {
        $resolvedScriptPath = Resolve-Path $ScriptPath -ErrorAction SilentlyContinue
        if (-not $resolvedScriptPath) {
            Write-Warning "Could not resolve script path: $ScriptPath"
            return
        }
    }

    Write-Verbose "Resolved script path: $resolvedScriptPath"

    # Command is available, load the completion script immediately
    try {
        . $resolvedScriptPath
        Write-Verbose "Successfully loaded completion script for $CommandName from $resolvedScriptPath"
    } catch {
        Write-Warning "Failed to load completion script for $CommandName from $resolvedScriptPath : $_"
    }
}
