Function Get-DuplicatePSModules {
    <#
    .SYNOPSIS
        Get all installed PowerShell modules that have multiple versions installed.
    .DESCRIPTION
        Get all installed PowerShell modules that have multiple versions installed.
    .PARAMETER Uninstall
        Uninstall all but the latest version of the duplicate modules.
    .EXAMPLE
        Get-DuplicatePSModules -Uninstall
    #>
    [CmdletBinding()]
    Param (
        [Parameter()]
        [Switch]$Uninstall
    )

    Process {
        Get-InstalledPSresource | ForEach-Object {
            $latestVersion = $PSItem.Version

            Write-Host "$($PSItem.Name) - $($PSItem.Version)" -ForegroundColor Green

            Get-InstalledPSResource $PSItem.Name -Version * |
                Where-Object { $_.Version -NE $latestVersion } |
                ForEach-Object {
                    Write-Host "- $($_.Name) - $($_.Version)" -ForegroundColor Magenta
                    if ($Uninstall) {
                        $PSItem | Uninstall-PSResource -SkipDependencyCheck
                    }
                }
        }
    }
}
