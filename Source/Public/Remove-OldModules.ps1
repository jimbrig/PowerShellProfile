Function Remove-OldModules {
    <#
    .SYNOPSIS
        Removes old versions of installed PowerShell modules, keeping only the latest.
    .DESCRIPTION
        Queries all installed PowerShell modules and removes older versions while preserving
        the most recent version of each module. Supports interactive selection, -WhatIf,
        -Confirm, -Verbose, and -Force parameters. Uses Get-InstalledPSResource and
        Uninstall-PSResource for modern PowerShell resource management.
    .PARAMETER Interactive
        Prompt the user to interactively select which modules to clean up using Out-ConsoleGridView.
    .PARAMETER Force
        Bypasses secondary confirmation for bulk operations and forces removal even if
        issues are encountered. Does not bypass -WhatIf/-Confirm (ShouldProcess).
    .PARAMETER PassThru
        When specified, outputs a result object for each processed module with Name, Version,
        LatestVersion, Status, and Error properties.
    .PARAMETER Include
        Optional wildcard patterns to include specific modules by name.
    .PARAMETER Exclude
        Optional wildcard patterns to exclude specific modules by name.
    .PARAMETER Scope
        Specifies the scope of modules to process: CurrentUser, AllUsers, or Both (default).
        AllUsers scope requires administrator privileges.
    .NOTES
        Requires PowerShellGet v3+ (PSResourceGet) for Get-InstalledPSResource and Uninstall-PSResource.
        Run as administrator to remove modules installed in AllUsers scope.
    .INPUTS
        None. This command does not accept pipeline input.
    .OUTPUTS
        System.Management.Automation.PSCustomObject when -PassThru is specified; otherwise, no output.
    .EXAMPLE
        Remove-OldModules
        Removes all old module versions after confirmation.
    .EXAMPLE
        Remove-OldModules -Interactive
        Prompts the user with a console grid to select which modules to clean up.
    .EXAMPLE
        Remove-OldModules -WhatIf
        Shows what would be removed without making any changes.
    .EXAMPLE
        Remove-OldModules -Force
        Removes all old module versions without secondary confirmation prompts.
    .EXAMPLE
        Remove-OldModules -Include 'Az.*' -Force
        Removes old versions of all Az modules without confirmation.
    .EXAMPLE
        Remove-OldModules -Exclude 'Pester','PSReadLine' -PassThru
        Removes old versions except for Pester and PSReadLine, returning result objects.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [switch]$Interactive,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$PassThru,

        [Parameter()]
        [string[]]$Include,

        [Parameter()]
        [string[]]$Exclude,

        [Parameter()]
        [ValidateSet('CurrentUser', 'AllUsers', 'Both')]
        [string]$Scope = 'Both'
    )

    begin {
        Write-Verbose '[BEGIN]: Remove-OldModules'

        # check for required commands
        if (-not (Get-Command -Name Get-InstalledPSResource -ErrorAction SilentlyContinue)) {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new('Get-InstalledPSResource not found. Install PowerShellGet v3+ (Microsoft.PowerShell.PSResourceGet).'),
                    'MissingCommand',
                    [System.Management.Automation.ErrorCategory]::NotInstalled,
                    $null
                )
            )
        }

        Write-Information 'Querying installed PowerShell modules...'

        # query installed modules
        $queryParams = @{}
        if ($Scope -eq 'CurrentUser') {
            $queryParams.Scope = 'CurrentUser'
        } elseif ($Scope -eq 'AllUsers') {
            $queryParams.Scope = 'AllUsers'
        }

        try {
            $allModules = Get-InstalledPSResource @queryParams -ErrorAction Stop |
            Where-Object { $_.Type -eq 'Module' }
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        if (-not $allModules -or @($allModules).Count -eq 0) {
            Write-Information 'No installed modules found.'
            return
        }

        # group modules by name and find those with multiple versions
        $moduleGroups = $allModules | Group-Object -Property Name | Where-Object { $_.Count -gt 1 }

        if (-not $moduleGroups -or @($moduleGroups).Count -eq 0) {
            Write-Information 'No modules with multiple versions found. Nothing to clean up.'
            return
        }

        # build list of old versions to remove
        $script:oldVersions = @()
        foreach ($group in $moduleGroups) {
            $sorted = $group.Group | Sort-Object -Property Version -Descending
            $latest = $sorted | Select-Object -First 1
            $older = $sorted | Select-Object -Skip 1

            foreach ($old in $older) {
                $script:oldVersions += [PSCustomObject]@{
                    Name              = $old.Name
                    Version           = $old.Version
                    LatestVersion     = $latest.Version
                    InstalledLocation = $old.InstalledLocation
                    Scope             = if ($old.InstalledLocation -match 'Program Files') { 'AllUsers' } else { 'CurrentUser' }
                    Resource          = $old
                }
            }
        }

        if (@($script:oldVersions).Count -eq 0) {
            Write-Information 'No old module versions found to remove.'
            return
        }

        Write-Information "Found $(@($script:oldVersions).Count) old module version(s) across $(@($moduleGroups).Count) module(s)."
    }

    process {
        Write-Verbose '[PROCESS]: Remove-OldModules'

        if (-not $script:oldVersions -or @($script:oldVersions).Count -eq 0) {
            return
        }

        # apply include/exclude filters
        $filtered = $script:oldVersions
        if ($Include) {
            $filtered = $filtered | Where-Object {
                $name = $_.Name
                $Include | Where-Object { $name -like $_ }
            }
        }
        if ($Exclude) {
            $filtered = $filtered | Where-Object {
                $name = $_.Name
                -not ($Exclude | Where-Object { $name -like $_ })
            }
        }

        if (-not $filtered -or @($filtered).Count -eq 0) {
            Write-Information 'No modules matched the specified filters.'
            return
        }

        # interactive selection if requested
        if ($Interactive) {
            if (-not (Get-Command -Name Out-ConsoleGridView -ErrorAction SilentlyContinue)) {
                Write-Warning 'Interactive mode requires ConsoleGuiTools (Out-ConsoleGridView). Proceeding non-interactively.'
                $Interactive = $false
            }
        }

        if ($Interactive) {
            $gridData = $filtered | ForEach-Object {
                [PSCustomObject]@{
                    Name          = $_.Name
                    Version       = $_.Version.ToString()
                    LatestVersion = $_.LatestVersion.ToString()
                    Scope         = $_.Scope
                }
            } | Sort-Object -Property Name, Version

            $title = "Select old module versions to remove ($(@($gridData).Count) found) - Space=toggle, Enter=accept, Esc=cancel"
            $selected = $gridData | Out-ConsoleGridView -Title $title -OutputMode Multiple

            if (-not $selected -or @($selected).Count -eq 0) {
                Write-Information 'No modules selected.'
                return
            }

            # map back to original objects
            $filtered = foreach ($sel in $selected) {
                $script:oldVersions | Where-Object {
                    $_.Name -eq $sel.Name -and $_.Version.ToString() -eq $sel.Version
                }
            }
        }

        $total = @($filtered).Count
        Write-Information "Removing $total old module version(s)..."

        # secondary confirmation for bulk operations unless -Force
        if (-not $Interactive -and $total -ge 3) {
            $caption = 'Confirm bulk removal'
            $message = "You are about to remove $total old module versions. Proceed?"
            if (-not $Force -and -not $PSCmdlet.ShouldContinue($message, $caption)) {
                Write-Information 'Operation cancelled by user.'
                return
            }
        }

        $results = @()
        $index = 0

        foreach ($mod in $filtered) {
            $index++
            $pct = [int](($index / $total) * 100)
            Write-Progress -Activity 'Removing old module versions' -Status "$($mod.Name) v$($mod.Version) ($index/$total)" -PercentComplete $pct

            $target = "$($mod.Name) v$($mod.Version) [latest: v$($mod.LatestVersion)]"

            if ($PSCmdlet.ShouldProcess($target, 'Uninstall')) {
                try {
                    $uninstallParams = @{
                        Name        = $mod.Name
                        Version     = $mod.Version.ToString()
                        ErrorAction = 'Stop'
                    }

                    if ($Force) {
                        $uninstallParams.SkipDependencyCheck = $true
                    }

                    Uninstall-PSResource @uninstallParams
                    Write-Verbose "Removed $($mod.Name) v$($mod.Version)"

                    $results += [PSCustomObject]@{
                        Name          = $mod.Name
                        Version       = $mod.Version
                        LatestVersion = $mod.LatestVersion
                        Status        = 'Removed'
                        Error         = $null
                    }
                } catch {
                    $err = $_
                    Write-Error -Message "Failed to remove $($mod.Name) v$($mod.Version): $($err.Exception.Message)" -Category OperationStopped -TargetObject $mod

                    $results += [PSCustomObject]@{
                        Name          = $mod.Name
                        Version       = $mod.Version
                        LatestVersion = $mod.LatestVersion
                        Status        = 'Failed'
                        Error         = $err.Exception.Message
                    }
                }
            } else {
                $results += [PSCustomObject]@{
                    Name          = $mod.Name
                    Version       = $mod.Version
                    LatestVersion = $mod.LatestVersion
                    Status        = 'Skipped'
                    Error         = $null
                }
            }
        }

        Write-Progress -Activity 'Removing old module versions' -Completed

        if ($PassThru) {
            $results
        }
    }

    end {
        Write-Verbose '[END]: Remove-OldModules'

        if ($script:oldVersions -and @($script:oldVersions).Count -gt 0) {
            Write-Information 'Remove-OldModules completed.'
        }
    }
}
