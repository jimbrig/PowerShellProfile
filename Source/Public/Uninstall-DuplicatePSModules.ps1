Function Uninstall-DuplicatePSModules {
    <#
    #>
    [CmdletBinding()]
    Param()

    Process {
        Get-InstalledPSResource | ForEach-Object {
            $latestVersion = $PSItem.Version
            Write-Host "$($PSItem.Name) - $($PSItem.Version)" -ForegroundColor Green
            Get-InstalledPSResource $PSItem.Name -Version * |
                Where-Object Version -NE $latestVersion |
                    ForEach-Object {
                        Write-Host "- Uninstalling version $($PSItem.Version)..." -ForegroundColor Magenta -NoNewline
                        $PSItem | Uninstall-PSResource -SkipDependencyCheck
                        Write-Host "Completed."
                    }
                }
    }
}
