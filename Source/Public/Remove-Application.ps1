Function Remove-Application() {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline)]
        $Application
    )
    Begin {}

    Process {
        if ($_ -is [PSCustomObject]) {
            $AppToRemove = $_
        } else {
            $AppToRemove = Get-Applications | Where-Object { $_.DisplayName -match $Application }
        }

        switch ($true) {
            { $AppToRemove.QuietUninstallString } {
                Write-Output "Running Quiet Uninstall String: $($AppToRemove.QuietUninstallString)"
                & $AppToRemove.QuietUninstallString
            }
            { $AppToRemove.UninstallString } {
                Write-Output "Running Uninstall String: $($AppToRemove.UninstallString)"
                & $AppToRemove.UninstallString
            }
            DEFAULT { Write-Error "No Uninstall String is provided for this application." }
        }
    }
}
