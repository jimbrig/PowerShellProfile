function Edit-PSProfile {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("CurrentUserCurrentHost", "CurrentUserAllHosts", "AllUsersCurrentHost", "AllUsersAllHosts")]
        [string]$Type = "CurrentUserCurrentHost",

        [switch]$OpenFolder,

        [string]$Editor
    )

    # Determine editor: use parameter, then $Env:EDITOR, else notepad.exe
    if (-not $Editor) {
        if ($Env:EDITOR) {
            $Editor = $Env:EDITOR
        } else {
            $Editor = "notepad.exe"
        }
    }

    $profilePath = $PROFILE.$Type

    # Ensure profile file exists
    if (-not (Test-Path -Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
        Write-Host "Created new profile at $profilePath"
    }

    # Open folder or file in editor
    if ($OpenFolder) {
        & $Editor (Split-Path -Parent $profilePath) *> $null
    } else {
        & $Editor $profilePath *> $null
    }

}
