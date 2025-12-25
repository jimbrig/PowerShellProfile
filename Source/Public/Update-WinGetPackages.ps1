Function Update-WinGetPackages {
    <#
    .SYNOPSIS
        Updates all available WinGet packages, optionally allowing interactive selection.
    .DESCRIPTION
        Queries WinGet for packages with available updates. Can optionally prompt the user with an interactive, in-console grid to select which packages to update. Supports -WhatIf, -Confirm, -Verbose, and -Force.
    .PARAMETER Interactive
        Prompt the user to interactively select which packages to update using Out-ConsoleGridView.
    .PARAMETER Force
        Update packages even if potential issues or warnings are encountered.
    .PARAMETER PassThru
        When specified, outputs a result object for each processed package with Id, Name, OldVersion, NewVersion, Status, and Error.
    .PARAMETER SelectionMode
        Controls selection behavior in the interactive grid. Multiple (default) or Single.
    .PARAMETER View
        Controls displayed columns: Default (includes Source) or Compact (hides Source to reduce truncation).
    .PARAMETER ChangeFilter
        Filter interactive grid by version change magnitude: All (default), Major, Minor, Patch, Unknown.
    .PARAMETER SortBy
        Sort interactive grid by: Name (default), Change, NewVersion, or Source.
    .PARAMETER Descending
        Sort descending when specified.
    .PARAMETER Include
        Optional wildcard patterns applied to Name or Id to include rows before showing the grid.
    .PARAMETER Exclude
        Optional wildcard patterns applied to Name or Id to exclude rows before showing the grid.
    .NOTES
        -Force follows the ShouldProcess guidance: it bypasses any additional safety confirmation (ShouldContinue) performed by this function
        for bulk updates and may be forwarded to underlying cmdlets if supported. It does not bypass -WhatIf/-Confirm (ShouldProcess).
    .INPUTS
        None. This command does not accept pipeline input.
    .OUTPUTS
        System.Management.Automation.PSCustomObject when -PassThru is specified; otherwise, no output.
    .EXAMPLE
        Update-WinGetPackages -Interactive
        Prompts the user with a console grid, then updates the selected packages.
    .EXAMPLE
        Update-WinGetPackages -Force
        Runs ALL available updates, forcing update even if warnings exist.
    .EXAMPLE
        Update-WinGetPackages -WhatIf
        Shows what would be updated, performs no changes.
    #>
    #Requires -Module Microsoft.WinGet.Client
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([pscustomobject])]
    param (
        [switch]$Interactive,
        [switch]$Force,
    [switch]$PassThru,
    [ValidateSet('Multiple','Single')][string]$SelectionMode = 'Multiple',
        [ValidateSet('Default','Compact')][string]$View = 'Default',
        [ValidateSet('All','Major','Minor','Patch','Unknown')][string]$ChangeFilter = 'All',
        [ValidateSet('Name','Change','NewVersion','Source')][string]$SortBy = 'Name',
    [switch]$Descending,
    [string[]]$Include,
    [string[]]$Exclude
    )

    begin {
        Write-Verbose '[BEGIN]: Update-WinGetPackages'
        Write-Information 'Querying updatable WinGet packages...'

        # Query packages in background to allow progress updates
        $queryJob = Start-Job -ScriptBlock {
            Get-WinGetPackage | Where-Object { $_.IsUpdateAvailable }
        }

        try {
            $activity = 'Querying updatable WinGet packages'
            $spinner = @('-', '\\', '|', '/')
            $i = 0
            while ($queryJob.State -eq 'Running') {
                $status = "Working $($spinner[$i % $spinner.Length])"
                Write-Progress -Activity $activity -Status $status
                Start-Sleep -Milliseconds 200
                $i++
            }
            Write-Progress -Activity $activity -Completed

            $updatable = Receive-Job -Job $queryJob -ErrorAction Stop
        }
        finally {
            if ($queryJob) { Remove-Job -Job $queryJob -Force -ErrorAction SilentlyContinue }
        }

        # De-duplicate by Id+Source to avoid duplicates across sources
        if ($updatable) {
            $updatable = $updatable | Sort-Object Id, Source -Unique
        }

        if (-not $updatable -or @($updatable).Count -eq 0) {
            Write-Information 'No packages with available updates.'
            return
        }
    }

    process {
        Write-Verbose '[PROCESS]: Update-WinGetPackages'
        # If interactive requested, ensure Out-ConsoleGridView is available; otherwise, fallback
        if ($Interactive -and -not (Get-Command -Name Out-ConsoleGridView -ErrorAction SilentlyContinue)) {
            Write-Warning 'Interactive mode requires ConsoleGuiTools (Out-ConsoleGridView). Proceeding non-interactively.'
            $Interactive = $false
        }
        # Interactive selection (Note: no -PassThru! Just capture output.)
        if ($Interactive) {
            function Get-VersionChange([string]$old, [string]$new) {
                try {
                    $vo = [version]$old
                    $vn = [version]$new
                    if ($vn.Major -ne $vo.Major) { return 'Major' }
                    if ($vn.Minor -ne $vo.Minor) { return 'Minor' }
                    if ($vn.Build -ne $vo.Build -or $vn.Revision -ne $vo.Revision) { return 'Patch' }
                    return 'Same'
                } catch {
                    return 'Unknown'
                }
            }

            function ConvertTo-Version([string]$s) {
                $out = $null
                if ([version]::TryParse($s, [ref]$out)) { return $out }
                return [version]'0.0.0.0'
            }

            # Build lookup to map selections back to original objects by Id|Source
            $lookup = @{}
            foreach ($p in $updatable) { $lookup["$($p.Id)|$($p.Source)"] = $p }

            # Apply include/exclude filters before annotation to reduce rows
            $prefiltered = $updatable
            if ($Include) {
                $prefiltered = $prefiltered | Where-Object { $nameId = "{0} {1}" -f $_.Name, $_.Id; $Include | Where-Object { $nameId -like $_ } }
            }
            if ($Exclude) {
                $prefiltered = $prefiltered | Where-Object { $nameId = "{0} {1}" -f $_.Name, $_.Id; -not ($Exclude | Where-Object { $nameId -like $_ }) }
            }

            # Annotate with computed fields for display
            $annotated = $prefiltered | ForEach-Object {
                $change = Get-VersionChange $_.InstalledVersion $_.AvailableVersion
                [pscustomobject]@{
                    Name              = $_.Name
                    Update            = '{0} -> {1}' -f $_.InstalledVersion, $_.AvailableVersion
                    Change            = $change
                    Id                = $_.Id
                    Source            = $_.Source
                    InstalledVersion  = $_.InstalledVersion
                    AvailableVersion  = $_.AvailableVersion
                }
            }

            # Filter by change magnitude if requested
            if ($ChangeFilter -ne 'All') {
                $annotated = $annotated | Where-Object { $_.Change -eq $ChangeFilter }
            }

            # Choose columns for view
            $gridColumns = if ($View -eq 'Compact') {
                'Name','Update','Change','Id'
            } else {
                'Name','Update','Change','Id','Source'
            }

            # Apply sort
            switch ($SortBy) {
                'Name'       { $gridData = $annotated | Sort-Object Name -Descending:$Descending }
                'Change'     {
                    $order = @{ 'Major' = 0; 'Minor' = 1; 'Patch' = 2; 'Same' = 3; 'Unknown' = 4 }
                    $gridData = $annotated | Sort-Object @{ Expression = { $order[$_.Change] } } -Descending:$Descending
                }
                'NewVersion' { $gridData = $annotated | Sort-Object @{ Expression = { ConvertTo-Version $_.AvailableVersion } } -Descending:$Descending }
                'Source'     { $gridData = $annotated | Sort-Object Source -Descending:$Descending }
            }

            # Project to desired columns for the grid
            $gridData = $gridData | Select-Object -Property $gridColumns

            $title = "Select packages to update ($(@($gridData).Count) shown) — Type to filter • Space=toggle • Enter=accept • Esc=cancel"
            $selected = $gridData | Out-ConsoleGridView -Title $title -OutputMode $SelectionMode
            if (-not $selected -or @($selected).Count -eq 0) {
                Write-Information 'No packages selected.'
                return
            }

            # Map back to original objects
            $selected = foreach ($s in @($selected)) { $lookup["$($s.Id)|$($s.Source)"] }
            $selected = $selected | Where-Object { $_ }
        } else {
            $selected = $updatable
        }

        $total = @($selected).Count
        Write-Information ("Updating {0} package(s)..." -f $total)

        # For non-interactive bulk operations, ask for a secondary confirmation unless -Force is specified
        if (-not $Interactive -and $total -ge 5) {
            $caption = 'Confirm bulk update'
            $message = "You are about to update $total packages. Proceed?"
            if (-not $Force -and -not $PSCmdlet.ShouldContinue($message, $caption)) {
                Write-Information 'Operation cancelled by user.'
                return
            }
        }

        $results = @()
        $index = 0
        foreach ($pkg in $selected) {
            $index++
            $pct = if ($total -gt 0) { [int](($index / $total) * 100) } else { 0 }
            Write-Progress -Activity 'Updating packages' -Status "$($pkg.Name) ($index/$total)" -PercentComplete $pct

            # ShouldProcess for -WhatIf and -Confirm
            if ($PSCmdlet.ShouldProcess("$($pkg.Name) [$($pkg.Id)]", 'Update')) {
                try {
                    $invokeArgs = @{ Id = $pkg.Id; ErrorAction = 'Stop' }
                    $updateCmd = Get-Command -Name Update-WinGetPackage -ErrorAction SilentlyContinue
                    if ($Force -and $updateCmd -and $updateCmd.Parameters.ContainsKey('Force')) {
                        $invokeArgs.Force = $true
                    }

                    Update-WinGetPackage @invokeArgs
                    Write-Information ("Updated {0}" -f $pkg.Name)
                    $results += [pscustomobject]@{
                        Id           = $pkg.Id
                        Name         = $pkg.Name
                        OldVersion   = $pkg.InstalledVersion
                        NewVersion   = $pkg.AvailableVersion
                        Status       = 'Updated'
                        Error        = $null
                    }
                } catch {
                    $err = $_
                    Write-Error -Message ("Failed to update {0}: {1}" -f $pkg.Name, $err.Exception.Message) -Category OperationStopped -TargetObject $pkg
                    $results += [pscustomobject]@{
                        Id           = $pkg.Id
                        Name         = $pkg.Name
                        OldVersion   = $pkg.InstalledVersion
                        NewVersion   = $pkg.AvailableVersion
                        Status       = 'Failed'
                        Error        = $err.Exception.Message
                    }
                }
            } else {
                $results += [pscustomobject]@{
                    Id           = $pkg.Id
                    Name         = $pkg.Name
                    OldVersion   = $pkg.InstalledVersion
                    NewVersion   = $pkg.AvailableVersion
                    Status       = 'Skipped'
                    Error        = $null
                }
            }
        }
        Write-Progress -Activity 'Updating packages' -Completed

        if ($PassThru) { $results }
    }

    end {
        Write-Verbose '[END]: Update-WinGetPackages'
        Write-Information 'Update-WinGetPackages completed.'
    }
}
