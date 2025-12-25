Function Invoke-ProfileReload {
    <#
    .SYNOPSIS
        Reloads the PowerShell Profile
    .DESCRIPTION
        This function reloads the PowerShell profile scripts across all locations and scopes:
        - $PROFILE.AllUsersAllHosts
        - $PROFILE.AllUsersCurrentHost
        - $PROFILE.CurrentUserAllHosts
        - $PROFILE.CurrentUserCurrentHost

        Useful for applying changes made to the profile without restarting the session.
    #>
    [CmdletBinding()]
    [Alias('Reload-Profile')]
    Param()

    $PROFILE | ForEach-Object {
        if (Test-Path $_) {
            Write-Verbose "Reloading Profile: '$_'"
            . $_
        }
    }
}
