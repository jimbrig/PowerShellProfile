Function Get-EnvironmentVariables {
    <#
        .SYNOPSIS
            Retrieves environment variables for both the current user and the system.
        .DESCRIPTION
            This function fetches environment variables from User, System,
            and Process scopes.
            It provides flexible filtering, formatting, and output options to help
            with system configuration analysis, troubleshooting, and documentation.

            Enhanced PATH variable analysis features include:
            - Identifying invalid or non-existent paths
            - Detecting duplicate entries
            - Comparing User and System PATH variables
            - Exporting PATH analysis to a file
        .PARAMETER Scope
            Specifies which scope(s) of environment variables to retrieve.
            Valid values: "All", "User", "System", "Process"
            Default: "All"
        .PARAMETER Filter
            Filters variables by name or value containing the specified string.
        .PARAMETER AsObject
            Returns a raw object instead of formatted output for pipeline processing.
        .PARAMETER IncludeProcessVars
            Includes current process environment variables in the output.
        .PARAMETER OutputFormat
            Specifies the format for displaying results.
            Valid values: "Table", "List", "Grid", "CSV", "JSON", "PathAnalysis"
            Default: "Table"
        .PARAMETER SkipAdminCheck
            Skips the administrative privilege check for system variables.
        .PARAMETER AnalyzePath
            Performs detailed analysis on PATH variables, checking for invalid paths and duplicates.
        .PARAMETER ComparePath
            Compares User and System PATH variables to identify common and unique entries.
        .PARAMETER ExportPathAnalysisTo
            Specifies a file path to export PATH analysis results in JSON format.
        .EXAMPLE
            Get-EnvironmentVariables
            Retrieves and displays all environment variables in table format.
        .EXAMPLE
            Get-EnvVars -Scope User
            Retrieves only user environment variables using the alias: Get-EnvVars.
        .EXAMPLE
            Get-EnvVars -Filter PATH
            Retrieves all environment variables with "PATH" in either name or value.
        .EXAMPLE
            Get-EnvVars -OutputFormat Grid
            Displays environment variables in an interactive grid view.
        .EXAMPLE
            Get-EnvVars -AsObject | Where-Object { $_.Name -eq "PATH" }
            Returns environment variables as objects for pipeline filtering.
        .EXAMPLE
            Get-EnvVars -IncludeProcessVars -OutputFormat List
            Shows all variables including process-specific ones in list format.
        .EXAMPLE
            Get-EnvVars -OutputFormat JSON | Set-Content -Path "env_vars.json"
            Exports environment variables to a JSON file.
        .EXAMPLE
            Get-EnvVars -AnalyzePath -OutputFormat PathAnalysis
            Performs detailed analysis on PATH variables and displays results in a specialized format.
        .EXAMPLE
            Get-EnvVars -ComparePath
            Compares User and System PATH variables to identify common and unique entries.
        .EXAMPLE
            Get-EnvVars -AnalyzePath -ExportPathAnalysisTo "C:\Temp\path_analysis.json"
            Performs PATH analysis and exports the results to a JSON file.
        .NOTES
            Author: Jimmy Briggs <jimmy.briggs@noclocks.dev>
            Version: 1.1
            Last Modified: 2025-03-16
            Requirements: Windows PowerShell 5.1 or PowerShell Core 6.0+

            Handles non-administrative scenarios by warning when System variables
            might not be fully accessible and providing a workaround.

            For full functionality, run PowerShell as an administrator.
    #>
    [Alias("Get-EnvVars", "envvars")]
    [OutputType([System.Collections.Generic.List[PSObject]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification = "Function name is plural for clarity")]
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, HelpMessage = "Scope of environment variables to retrieve")]
        [ValidateSet("All", "User", "System", "Process")]
        [string]$Scope = "All",

        [Parameter(HelpMessage = "Filter variables by name or value")]
        [string]$Filter,

        [Parameter(HelpMessage = "Return raw object instead of formatted output")]
        [switch]$AsObject,

        [Parameter(HelpMessage = "Include process-specific variables")]
        [switch]$IncludeProcessVars,

        [Parameter(HelpMessage = "Output format for results")]
        [ValidateSet("Table", "List", "Grid", "CSV", "JSON", "PathAnalysis")]
        [string]$OutputFormat = "Table",

        [Parameter(HelpMessage = "Skip administrative privilege check")]
        [switch]$SkipAdminCheck,

        [Parameter(HelpMessage = "Analyze PATH variables in detail")]
        [switch]$AnalyzePath,

        [Parameter(HelpMessage = "Compare User and System PATH variables")]
        [switch]$ComparePath,

        [Parameter(HelpMessage = "Export PATH analysis to a file")]
        [string]$ExportPathAnalysisTo
    )

    Begin {
        Write-Verbose "[BEGIN]: Get-EnvironmentVariables"
        # initialize collection
        $resultCollection = [System.Collections.Generic.List[PSObject]]::new()

        Write-OperationStatus -Message "Starting environment variable retrieval with scope: $Scope" -Type Info

        # check for admin privileges if accessing system variables
        if (($Scope -eq "All" -or $Scope -eq "System") -and -not $SkipAdminCheck) {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

            if (-not $isAdmin) {
                Write-Warning "Not running as administrator. Some system environment variables may be inaccessible."
                Write-Verbose "To see all system variables, rerun PowerShell as administrator."
            }
        }

        # If PATH analysis is requested, automatically set OutputFormat to PathAnalysis unless specified otherwise
        if ($AnalyzePath -and $OutputFormat -eq "Table" -and -not $PSBoundParameters.ContainsKey('OutputFormat')) {
            $OutputFormat = "PathAnalysis"
            Write-Verbose "Setting OutputFormat to PathAnalysis for PATH analysis"
        }
    }

    Process {
        Write-Verbose "[PROCESS]: Get-EnvironmentVariables"
        # Get variables based on scope
        if ($Scope -eq "All" -or $Scope -eq "User") {
            $userVariables = Get-EnvVarsFromScope -EnvScope "User" -DisplayScope "User"
            foreach ($key in $userVariables.Keys) {
                $resultCollection.Add([PSCustomObject]@{
                        Scope   = "User"
                        Name    = $key
                        Value   = $userVariables[$key]
                        FullKey = "User.$key"
                        Length  = if ($userVariables[$key]) { $userVariables[$key].Length } else { 0 }
                        Type    = if ($userVariables[$key] -match ';') { "List" } else { "Single" }
                    })
            }
        }

        if ($Scope -eq "All" -or $Scope -eq "System") {
            $systemVariables = Get-EnvVarsFromScope -EnvScope "Machine" -DisplayScope "System"
            foreach ($key in $systemVariables.Keys) {
                $resultCollection.Add([PSCustomObject]@{
                        Scope   = "System"
                        Name    = $key
                        Value   = $systemVariables[$key]
                        FullKey = "System.$key"
                        Length  = if ($systemVariables[$key]) { $systemVariables[$key].Length } else { 0 }
                        Type    = if ($systemVariables[$key] -match ';') { "List" } else { "Single" }
                    })
            }
        }

        # Include process variables if requested or if scope is Process
        if ($IncludeProcessVars -or $Scope -eq "All" -or $Scope -eq "Process") {
            $processVariables = Get-EnvVarsFromScope -EnvScope "Process" -DisplayScope "Process"

            # Track which variables we've already included from other scopes
            $existingKeys = $resultCollection | ForEach-Object { $_.Name } | Select-Object -Unique

            foreach ($key in $processVariables.Keys) {
                # Only add process variables that aren't already included if scope is All
                if ($Scope -eq "Process" -or ($IncludeProcessVars -and -not ($existingKeys -contains $key))) {
                    $resultCollection.Add([PSCustomObject]@{
                            Scope   = "Process"
                            Name    = $key
                            Value   = $processVariables[$key]
                            FullKey = "Process.$key"
                            Length  = if ($processVariables[$key]) { $processVariables[$key].Length } else { 0 }
                            Type    = if ($processVariables[$key] -match ';') { "List" } else { "Single" }
                        })
                }
            }
        }

        # Apply filter if provided
        if ($Filter) {
            Write-OperationStatus -Message "Applying filter: $Filter" -Type Info
            $resultCollection = $resultCollection | Where-Object {
                $_.Name -like "*$Filter*" -or $_.Value -like "*$Filter*"
            }

            if ($resultCollection.Count -eq 0) {
                Write-OperationStatus -Message "No variables matched the filter: $Filter" -Type Warning
            }
        }

        # Add path breakdown for PATH variables
        $pathVariables = $resultCollection | Where-Object { $_.Name -eq "PATH" -or $_.Name -eq "Path" }

        # Perform detailed PATH analysis if requested
        if ($AnalyzePath -or $ComparePath -or $OutputFormat -eq "PathAnalysis") {
            Write-Verbose "Performing detailed PATH analysis"
            foreach ($pathVar in $pathVariables) {
                Expand-PathVariable -PathVariable $pathVar
            }
        } else {
            # Basic PATH entry breakdown for all PATH variables
            foreach ($pathVar in $pathVariables) {
                if ($pathVar.Value -and $pathVar.Value.Contains(';')) {
                    $pathVar | Add-Member -MemberType NoteProperty -Name "PathEntries" -Value ($pathVar.Value -split ';' | Where-Object { $_ }) -Force
                } else {
                    $pathVar | Add-Member -MemberType NoteProperty -Name "PathEntries" -Value @($pathVar.Value) -Force
                }
            }
        }
    }

    End {
        # Sort results
        $sortedResults = $resultCollection | Sort-Object Scope, Name

        # Return as raw object if requested
        if ($AsObject) {
            return $sortedResults
        }

        # Prepare output based on format
        if ($sortedResults.Count -eq 0) {
            Write-OperationStatus -Message "No environment variables found matching the criteria." -Type Warning
            return
        }

        Write-OperationStatus -Message "Found $($sortedResults.Count) environment variables." -Type Info

        # Format and return results
        switch ($OutputFormat) {
            "Table" {
                # Default column set for table view
                $sortedResults | Format-Table -Property Scope, Name, Value -AutoSize
            }
            "List" {
                # More detailed view for list format
                $sortedResults | Format-List -Property Scope, Name, Value, Length, Type
            }
            "Grid" {
                # Interactive view
                $sortedResults | Out-GridView -Title "Environment Variables"
            }
            "CSV" {
                # CSV format for export
                $sortedResults | ConvertTo-Csv -NoTypeInformation
            }
            "JSON" {
                # JSON format for modern integrations
                # Check if ConvertTo-Json is available (PowerShell 3.0+)
                if (Get-Command ConvertTo-Json -ErrorAction SilentlyContinue) {
                    $sortedResults | ConvertTo-Json
                } else {
                    Write-OperationStatus -Message "JSON output requires PowerShell 3.0 or higher. Defaulting to CSV." -Type Warning
                    $sortedResults | ConvertTo-Csv -NoTypeInformation
                }
            }
            "PathAnalysis" {
                # Path-specific output - only show PATH variables with detailed breakdown
                $pathVariables = $sortedResults | Where-Object { $_.Name -eq "PATH" -or $_.Name -eq "Path" }

                if ($pathVariables.Count -eq 0) {
                    Write-Warning "No PATH variables found in the selected scope(s)."
                    return
                }

                # Ensure PATH variables are analyzed
                if (-not $AnalyzePath) {
                    $pathVariables = $pathVariables | ForEach-Object { Expand-PathVariable -PathVariable $_ }
                }

                # First, show a summary table
                $pathVariables | Format-Table -Property Scope, Name, EntryCount, InvalidPathCount -AutoSize

                # Then, for each PATH variable, show a detailed list of entries
                foreach ($pathVar in $pathVariables) {
                    Write-Host "`n[$($pathVar.Scope)] PATH Variable Analysis:" -ForegroundColor Cyan

                    if ($pathVar.DuplicatePaths.Count -gt 0) {
                        Write-Host "  Duplicate entries found:" -ForegroundColor Yellow
                        $pathVar.DuplicatePaths | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
                    }

                    if ($pathVar.NonExistingPaths.Count -gt 0) {
                        Write-Host "  Non-existent paths ($($pathVar.NonExistingPaths.Count)):" -ForegroundColor Red
                        $pathVar.NonExistingPaths | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
                    }

                    Write-Host "  Valid paths ($($pathVar.ExistingPaths.Count)):" -ForegroundColor Green
                    $pathVar.ExistingPaths | ForEach-Object { Write-Host "    $_" -ForegroundColor Green }
                }
            }
            default {
                $sortedResults | Format-Table -AutoSize
            }
        }

        # If PATH comparison is requested
        if ($ComparePath) {
            $pathVariables = $sortedResults | Where-Object { $_.Name -eq "PATH" -or $_.Name -eq "Path" }

            if ($pathVariables.Count -lt 2) {
                Write-Warning "Both User and System PATH variables are needed for comparison."
            } else {
                Write-Host "`nPATH Variable Comparison:" -ForegroundColor Cyan
                $comparison = Compare-PathVariables -PathVariables $pathVariables

                Write-Host "Common entries ($($comparison.CommonEntryCount)):" -ForegroundColor Green
                $comparison.CommonEntries | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }

                Write-Host "`nUser-only entries ($($comparison.UserOnlyCount)):" -ForegroundColor Yellow
                $comparison.UserOnlyEntries | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }

                Write-Host "`nSystem-only entries ($($comparison.SystemOnlyCount)):" -ForegroundColor Magenta
                $comparison.SystemOnlyEntries | ForEach-Object { Write-Host "  $_" -ForegroundColor Magenta }
            }
        }

        # Export PATH analysis if requested
        if ($ExportPathAnalysisTo -and ($AnalyzePath -or $ComparePath -or $OutputFormat -eq "PathAnalysis")) {
            $pathVariables = $sortedResults | Where-Object { $_.Name -eq "PATH" -or $_.Name -eq "Path" }

            # Ensure PATH variables are analyzed
            if (-not $AnalyzePath) {
                $pathVariables = $pathVariables | ForEach-Object { Expand-PathVariable -PathVariable $_ }
            }

            $exportData = [PSCustomObject]@{
                Timestamp     = Get-Date
                ComputerName  = $env:COMPUTERNAME
                Username      = $env:USERNAME
                PathVariables = $pathVariables
            }

            if ($ComparePath -and $pathVariables.Count -ge 2) {
                $comparison = Compare-PathVariables -PathVariables $pathVariables
                $exportData | Add-Member -MemberType NoteProperty -Name "Comparison" -Value $comparison
            }

            if (Get-Command ConvertTo-Json -ErrorAction SilentlyContinue) {
                $exportData | ConvertTo-Json -Depth 10 | Set-Content -Path $ExportPathAnalysisTo
                Write-Host "PATH analysis exported to $ExportPathAnalysisTo" -ForegroundColor Green
            } else {
                Write-Warning "JSON export requires PowerShell 3.0 or higher. Export failed."
            }
        }

        # Additional information for PATH variables when in verbose mode
        if ($VerbosePreference -ne 'SilentlyContinue') {
            $pathVariables = $sortedResults | Where-Object { $_.Name -eq "PATH" }
            foreach ($pathVar in $pathVariables) {
                if ($pathVar.PathEntries) {
                    Write-Verbose "PATH entries from $($pathVar.Scope) scope:"
                    $pathVar.PathEntries | ForEach-Object { Write-Verbose "  $_" }
                }
            }
        }

        Write-OperationStatus -Message "Environment variable retrieval complete." -Type Info
    }
}

Function Get-EnvVarsFromScope {
    <#
    .SYNOPSIS
        Retrieves environment variables from a specific scope.
    .DESCRIPTION
        Helper function that safely retrieves environment variables from User, Machine, or Process scopes.
        Handles errors and returns an empty hashtable if retrieval fails.
    .PARAMETER EnvScope
        The scope to retrieve variables from. Valid values: "User", "Machine", "Process".
    .PARAMETER DisplayScope
        The display name for the scope, used in status messages.
    .EXAMPLE
        Get-EnvVarsFromScope -EnvScope "User" -DisplayScope "User"
        Retrieves all user environment variables.
    #>
    param (
        [Parameter(Mandatory)]
        [ValidateSet("User", "Machine", "Process")]
        [string]$EnvScope,

        [Parameter(Mandatory)]
        [string]$DisplayScope
    )

    try {
        $variables = [System.Environment]::GetEnvironmentVariables($EnvScope)
        Write-OperationStatus -Message "Successfully retrieved $($variables.Count) variables from $DisplayScope scope." -Type Success
        return $variables
    } catch {
        Write-OperationStatus -Message "Failed to retrieve variables from $DisplayScope scope: $_" -Type Error
        return @{}
    }
}

Function Expand-PathVariable {
    <#
    .SYNOPSIS
        Performs detailed analysis on PATH environment variables.
    .DESCRIPTION
        Analyzes PATH variables by breaking down path entries, checking for existence,
        identifying duplicates, and adding detailed metadata to the variable object.
    .PARAMETER PathVariable
        The PATH variable object to analyze.
    .EXAMPLE
        $pathVar | Expand-PathVariable
        Analyzes the PATH variable and adds detailed metadata.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject]$PathVariable
    )

    process {
        if (-not ($PathVariable.Name -eq "PATH" -or $PathVariable.Name -eq "Path")) {
            return $PathVariable
        }

        $pathEntries = $PathVariable.Value -split ';' | Where-Object { $_ } | ForEach-Object { $_.Trim() }

        # Add path entries as a separate property
        $PathVariable | Add-Member -MemberType NoteProperty -Name "PathEntries" -Value $pathEntries -Force

        # Add count of path entries
        $PathVariable | Add-Member -MemberType NoteProperty -Name "EntryCount" -Value $pathEntries.Count -Force

        # Check for existence of each path
        $existingPaths = @()
        $nonExistingPaths = @()

        foreach ($path in $pathEntries) {
            if (Test-Path -Path $path -ErrorAction SilentlyContinue) {
                $existingPaths += $path
            } else {
                $nonExistingPaths += $path
            }
        }

        $PathVariable | Add-Member -MemberType NoteProperty -Name "ExistingPaths" -Value $existingPaths -Force
        $PathVariable | Add-Member -MemberType NoteProperty -Name "NonExistingPaths" -Value $nonExistingPaths -Force
        $PathVariable | Add-Member -MemberType NoteProperty -Name "InvalidPathCount" -Value $nonExistingPaths.Count -Force

        # Check for duplicates
        $duplicates = $pathEntries | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name
        $PathVariable | Add-Member -MemberType NoteProperty -Name "DuplicatePaths" -Value $duplicates -Force

        return $PathVariable
    }
}

Function Compare-PathVariables {
    <#
    .SYNOPSIS
        Compares multiple PATH variables to identify common and unique entries.
    .DESCRIPTION
        Analyzes and compares PATH variables from different scopes to identify
        common entries, entries unique to each scope, and provides summary statistics.
    .PARAMETER PathVariables
        An array of PATH variable objects to compare.
    .EXAMPLE
        Compare-PathVariables -PathVariables $pathVars
        Compares PATH variables and returns a detailed comparison object.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSObject[]]$PathVariables
    )

    if ($PathVariables.Count -lt 2) {
        Write-Warning "Need at least two PATH variables to compare."
        return
    }

    # Ensure all variables are analyzed
    $analyzedVars = $PathVariables | ForEach-Object {
        if (-not $_.PathEntries) {
            Expand-PathVariable -PathVariable $_
        } else {
            $_
        }
    }

    # Find entries that exist in both User and System PATH
    $userVar = $analyzedVars | Where-Object { $_.Scope -eq "User" } | Select-Object -First 1
    $systemVar = $analyzedVars | Where-Object { $_.Scope -eq "System" } | Select-Object -First 1

    if ($userVar -and $systemVar) {
        $commonEntries = $userVar.PathEntries | Where-Object { $entry = $_; $systemVar.PathEntries -contains $entry }

        $userOnly = $userVar.PathEntries | Where-Object { $entry = $_; $systemVar.PathEntries -notcontains $entry }
        $systemOnly = $systemVar.PathEntries | Where-Object { $entry = $_; $userVar.PathEntries -notcontains $entry }

        # Return comparison result
        [PSCustomObject]@{
            UserPathCount     = $userVar.PathEntries.Count
            SystemPathCount   = $systemVar.PathEntries.Count
            CommonEntries     = $commonEntries
            CommonEntryCount  = $commonEntries.Count
            UserOnlyEntries   = $userOnly
            UserOnlyCount     = $userOnly.Count
            SystemOnlyEntries = $systemOnly
            SystemOnlyCount   = $systemOnly.Count
        }
    } else {
        Write-Warning "Both User and System PATH variables are required for comparison."
    }
}

Function Write-OperationStatus {
    <#
    .SYNOPSIS
        Helper function for consistent message formatting
    .DESCRIPTION
        Provides consistent formatting for operation status messages with
        different severity levels (Info, Success, Warning, Error).
    .PARAMETER Message
        The message to display.
    .PARAMETER Type
        The message type/severity. Valid values: "Info", "Success", "Warning", "Error".
    .EXAMPLE
        Write-OperationStatus -Message "Operation completed" -Type Success
        Writes a success operation status message.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )

    switch ($Type) {
        "Info" { Write-Verbose $Message }
        "Success" { Write-Verbose $Message }
        "Warning" { Write-Warning $Message }
        "Error" { Write-Error $Message }
    }
}

# Export the functions if in a module context
if ($MyInvocation.MyCommand.Path) {
    Export-ModuleMember -Function Get-EnvironmentVariables, Get-EnvVarsFromScope, Write-OperationStatus, Expand-PathVariable, Compare-PathVariables -Alias Get-EnvVars, envvars
}
