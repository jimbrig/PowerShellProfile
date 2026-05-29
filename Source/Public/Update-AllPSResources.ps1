function Update-AllPSResources {
    <#
    .SYNOPSIS
    Comprehensive management of PowerShell modules and scripts using both PowerShellGet and PSResourceGet

    .DESCRIPTION
    Updates all installed modules and scripts to their latest versions and cleans up older versions.
    Handles resources from both PowerShellGet (v1/v2) and Microsoft.PowerShell.PSResourceGet.
    Provides detailed progress reporting and handles error conditions gracefully.

    .PARAMETER SkipAdminCheck
    Skip the check for multiple PowerShell sessions when running as admin.

    .PARAMETER IncludePrerelease
    Include prerelease versions when updating modules/scripts.

    .PARAMETER KeepLatestMinorVersion
    Keep the latest version of each minor release instead of just the most recent version.

    .PARAMETER ExcludeModules
    Array of module names to exclude from updating.

    .PARAMETER UpdatePSGetOnly
    Only update PowerShellGet modules before proceeding.

    .PARAMETER Credential
    PSCredential object to use for authenticating to repositories.

    .PARAMETER SkipDependencyCheck
    Skip dependency checking when uninstalling modules (use with caution).

    .PARAMETER KeepDependencies
    Preserve modules that are dependencies for other modules.

    .PARAMETER RepositoryName
    Name of the repository to use. Defaults to PSGallery if not specified.

    .PARAMETER RepositoryPriority
    Order of repository search priority. Defaults to @('PSGallery', 'LocalRepository').

    .INPUTS
    None

    .OUTPUTS
    [PSCustomObject] Summary of update operations

    .EXAMPLE
    # Update all modules and scripts, removing old versions
    Update-AllPSResources

    .EXAMPLE
    # Update all modules but exclude AzureRM modules
    Update-AllPSResources -ExcludeModules @('AzureRM*')

    .EXAMPLE
    # Include prerelease versions and keep latest of each minor version
    Update-AllPSResources -IncludePrerelease -KeepLatestMinorVersion

    .EXAMPLE
    # Use specific repository credentials
    $cred = Get-Credential
    Update-AllPSResources -Credential $cred -RepositoryName 'InternalRepo'

    .NOTES
    Author: Updated by consultant at No Clocks, LLC
    Last Updated: March 17, 2025
    Requires: Windows PowerShell 5.1 or PowerShell 7.x
    #>

    [CmdletBinding()]
    param (
        [switch]$SkipAdminCheck,
        [switch]$IncludePrerelease,
        [switch]$KeepLatestMinorVersion,
        [string[]]$ExcludeModules = @(),
        [switch]$UpdatePSGetOnly,
        [System.Management.Automation.PSCredential]$Credential,
        [switch]$SkipDependencyCheck,
        [switch]$KeepDependencies,
        [string]$RepositoryName,
        [string[]]$RepositoryPriority = @('PSGallery')
    )

    #region Helper Functions

    function Test-IsAdmin {
        return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
    }

    function Test-ModuleExcluded {
        param([string]$ModuleName)

        foreach ($pattern in $ExcludeModules) {
            if ($ModuleName -like $pattern) {
                return $true
            }
        }
        return $false
    }

    function Get-MinorVersionKey {
        param(
            [Parameter(Mandatory = $true, Position = 0)]
            [object]$Version
        )

        # Handle different version types (Version vs SemanticVersion)
        if ($Version -is [System.Management.Automation.SemanticVersion]) {
            return "$($Version.Major).$($Version.Minor)"
        } elseif ($Version -is [version]) {
            return "$($Version.Major).$($Version.Minor)"
        } else {
            try {
                $v = [version]$Version
                return "$($v.Major).$($v.Minor)"
            } catch {
                Write-Warning "Unable to parse version: $Version"
                return $Version
            }
        }
    }

    function Write-ModuleError {
        param(
            [string]$ModuleName,
            [string]$Message,
            [System.Management.Automation.ErrorRecord]$ErrorRecord,
            [string]$Category = "General"
        )

        $warningParams = @{
            Message = "[$ModuleName] $Message"
        }

        if ($ErrorRecord) {
            $warningParams.Message += " Error: $($ErrorRecord.Exception.Message)"
        }

        Write-Warning @warningParams

        # Track error categories for better reporting
        $script:errorCategories[$Category] = ($script:errorCategories[$Category] + 1)
    }

    function Find-LatestModule {
        param(
            [string]$Name,
            [switch]$IncludePrerelease,
            [System.Management.Automation.PSCredential]$Credential
        )

        $result = $null
        $tried = @()

        foreach ($repo in $RepositoryPriority) {
            try {
                $findParams = @{
                    Name        = $Name
                    ErrorAction = 'Stop'
                    Repository  = $repo
                }

                if ($Credential) {
                    $findParams['Credential'] = $Credential
                }

                if ($IncludePrerelease) {
                    $findParams['AllowPrerelease'] = $true
                }

                $result = Find-Module @findParams
                if ($result) {
                    return $result
                }
            } catch {
                $tried += $repo
                Write-Verbose "Module $Name not found in repository $repo"
            }
        }

        # Fall back to default behavior if no specific repository succeeds
        if (-not $result) {
            try {
                $findParams = @{
                    Name        = $Name
                    ErrorAction = 'Stop'
                }

                if ($Credential) {
                    $findParams['Credential'] = $Credential
                }

                if ($IncludePrerelease) {
                    $findParams['AllowPrerelease'] = $true
                }

                $result = Find-Module @findParams
            } catch {
                Write-Verbose "Module $Name not found in any repository"
                throw $_
            }
        }

        return $result
    }

    function Find-LatestPSResource {
        param(
            [string]$Name,
            [switch]$IncludePrerelease,
            [System.Management.Automation.PSCredential]$Credential
        )

        $result = $null
        $tried = @()

        foreach ($repo in $RepositoryPriority) {
            try {
                $findParams = @{
                    Name        = $Name
                    ErrorAction = 'Stop'
                    Repository  = $repo
                }

                if ($Credential) {
                    $findParams['Credential'] = $Credential
                }

                if ($IncludePrerelease) {
                    $findParams['Prerelease'] = $true
                }

                $result = Find-PSResource @findParams
                if ($result) {
                    return $result
                }
            } catch {
                $tried += $repo
                Write-Verbose "Resource $Name not found in repository $repo"
            }
        }

        # Fall back to default behavior if no specific repository succeeds
        if (-not $result) {
            try {
                $findParams = @{
                    Name        = $Name
                    ErrorAction = 'Stop'
                }

                if ($Credential) {
                    $findParams['Credential'] = $Credential
                }

                if ($IncludePrerelease) {
                    $findParams['Prerelease'] = $true
                }

                $result = Find-PSResource @findParams
            } catch {
                Write-Verbose "Resource $Name not found in any repository"
                throw $_
            }
        }

        return $result
    }

    function Test-IsDependency {
        param(
            [string]$ModuleName,
            [string]$Version
        )

        if (-not $KeepDependencies) {
            return $false
        }

        # Check if module is a dependency for any other module
        $allModules = Get-InstalledModule -ErrorAction SilentlyContinue

        foreach ($module in $allModules) {
            if ($module.Name -eq $ModuleName) {
                continue # Skip self
            }

            try {
                $moduleInfo = Get-Module $module.Name -ListAvailable -ErrorAction SilentlyContinue | Select-Object -First 1
                if (-not $moduleInfo) {
                    continue
                }

                $requiredModules = $moduleInfo.RequiredModules
                foreach ($reqModule in $requiredModules) {
                    if ($reqModule.Name -eq $ModuleName) {
                        Write-Verbose "$ModuleName is a dependency for $($module.Name)"
                        return $true
                    }
                }
            } catch {
                Write-Verbose "Error checking dependencies for $($module.Name): $_"
            }
        }

        return $false
    }

    #endregion Helper Functions

    #region Initialize

    $startTime = Get-Date
    $isAdmin = Test-IsAdmin
    Write-Verbose -Message "PowerShell session running as administrator: $isAdmin"

    # Script-level variables for tracking
    $script:processedModules = @{}
    $script:errorCategories = @{
        "Authentication" = 0
        "Repository"     = 0
        "Dependency"     = 0
        "Permission"     = 0
        "Uninstallation" = 0
        "General"        = 0
    }

    # Track metrics
    $summary = [PSCustomObject]@{
        SystemModulesUpdated = 0
        UserModulesUpdated   = 0
        ScriptsUpdated       = 0
        ErrorCount           = 0
        SkippedCount         = 0
        OldVersionsRemoved   = 0
        RuntimeMinutes       = 0
        DetailedResults      = @()
        ErrorCategories      = $script:errorCategories
    }

    # Set repository priority if specific repository is provided
    if ($RepositoryName) {
        $RepositoryPriority = @($RepositoryName, 'PSGallery')
    }

    # Check for multiple PowerShell sessions (if not skipped)
    if (-not $SkipAdminCheck) {
        $psSessions = @(Get-Process -Name powershell, pwsh -ErrorAction SilentlyContinue)
        if ($psSessions.Count -gt 1) {
            Write-Warning "Multiple PowerShell sessions detected ($($psSessions.Count)). This may prevent module uninstallation."
            Write-Warning "Current process ID: $PID"

            $otherSessions = $psSessions | Where-Object { $_.Id -ne $PID }
            Write-Verbose "Other PowerShell sessions: $($otherSessions.Id -join ', ')"

            $confirmation = Read-Host "Continue anyway? (y/n)"
            if ($confirmation -notmatch '^y') {
                Write-Warning "Update aborted. Please close other PowerShell sessions before continuing."
                return
            }
        }
    }

    # Verify repository access and credentials
    if ($RepositoryName) {
        try {
            $repoParams = @{
                Name        = $RepositoryName
                ErrorAction = 'Stop'
            }

            $repository = Get-PSRepository @repoParams
            Write-Verbose "Successfully connected to repository: $RepositoryName"
        } catch {
            Write-Warning "Unable to connect to specified repository: $RepositoryName. Error: $_"
            Write-Warning "Falling back to PSGallery"
            $RepositoryPriority = @('PSGallery')
        }
    }

    # Check for PSResourceGet availability
    $psgModuleVersions = @{}
    $psrAvailable = $false

    try {
        $psgModuleVersions['PowerShellGet'] = (Get-Module PowerShellGet -ListAvailable | Sort-Object Version -Descending)[0].Version

        if (Get-Module -Name Microsoft.PowerShell.PSResourceGet -ListAvailable) {
            $psrAvailable = $true
            $psgModuleVersions['PSResourceGet'] = (Get-Module Microsoft.PowerShell.PSResourceGet -ListAvailable | Sort-Object Version -Descending)[0].Version
            Write-Verbose "PSResourceGet $($psgModuleVersions['PSResourceGet']) detected"
        }
    } catch {
        Write-Warning "Error detecting installed module management systems: $_"
        $script:errorCategories["General"]++
    }

    # Update Package Providers if needed and running as admin
    if ($isAdmin) {
        try {
            # Ensure NuGet PackageProvider is installed/updated for PowerShellGet
            $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
            if (-not $nugetProvider -or $nugetProvider.Version -lt [version]'2.8.5.201') {
                Write-Verbose "Installing/Updating NuGet package provider..."
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers | Out-Null
            }

            # Set repositories as trusted based on priority list
            foreach ($repoName in $RepositoryPriority) {
                $repository = Get-PSRepository -Name $repoName -ErrorAction SilentlyContinue
                if ($repository -and $repository.InstallationPolicy -ne 'Trusted') {
                    Write-Verbose "Setting $repoName as a trusted repository"
                    Set-PSRepository -Name $repoName -InstallationPolicy Trusted
                }
            }
        } catch {
            Write-Warning "Error updating package providers: $_"
            $script:errorCategories["General"]++
        }
    }

    # Register repositories if credentials are provided
    if ($Credential -and $RepositoryName -and $RepositoryName -ne 'PSGallery') {
        try {
            $existingRepo = Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue

            if (-not $existingRepo) {
                # Prompt for repository URL if not registered
                $repoUrl = Read-Host "Repository $RepositoryName not found. Enter the repository URL"

                if ($repoUrl) {
                    Write-Verbose "Registering repository $RepositoryName with URL $repoUrl"
                    Register-PSRepository -Name $RepositoryName -SourceLocation $repoUrl -Credential $Credential -InstallationPolicy Trusted
                } else {
                    Write-Warning "No repository URL provided. Falling back to PSGallery."
                    $RepositoryPriority = @('PSGallery')
                }
            }
        } catch {
            Write-Warning "Error registering repository: $_"
            $script:errorCategories["Repository"]++
        }
    }

    # Optionally update PowerShellGet modules first
    if ($UpdatePSGetOnly) {
        try {
            Write-Verbose "Updating PowerShellGet and related modules first..."

            # For PowerShellGet
            if (-not $psrAvailable) {
                if ($isAdmin) {
                    Install-Module PowerShellGet -Force -AllowClobber -Scope AllUsers
                } else {
                    Install-Module PowerShellGet -Force -AllowClobber -Scope CurrentUser
                }
            }

            # For PSResourceGet (if not already available)
            if (-not $psrAvailable -and $isAdmin) {
                Install-Module Microsoft.PowerShell.PSResourceGet -Force -Scope AllUsers
                $psrAvailable = $true
            } elseif (-not $psrAvailable) {
                Install-Module Microsoft.PowerShell.PSResourceGet -Force -Scope CurrentUser
                $psrAvailable = $true
            }

            # Reload PowerShell to use the new modules
            Write-Warning "PowerShellGet modules have been updated. Please restart PowerShell and run this function again."
            return
        } catch {
            Write-Warning "Error updating PowerShellGet modules: $_"
        }
    }

    #endregion Initialize

    #region PowerShellGet Modules

    Write-Verbose "Processing PowerShellGet modules..."

    try {
        # Get all installed modules using PowerShellGet
        $allInstalledModules = Get-InstalledModule -ErrorAction SilentlyContinue
        $totalPSGModules = ($allInstalledModules | Measure-Object).Count

        Write-Verbose "Found $totalPSGModules modules installed via PowerShellGet"

        # Initialize progress bar
        $progressParams = @{
            Activity        = "Updating PowerShell modules (PowerShellGet)"
            Status          = "Processing modules"
            PercentComplete = 0
        }

        # Process each module
        for ($i = 0; $i -lt $totalPSGModules; $i++) {
            $module = $allInstalledModules[$i]
            $progressParams.PercentComplete = ($i / $totalPSGModules * 100)
            $progressParams.CurrentOperation = "Processing $($module.Name) [$($i + 1)/$totalPSGModules]"
            Write-Progress @progressParams

            # Skip if already processed by another system
            if ($script:processedModules.ContainsKey($module.Name)) {
                Write-Verbose "Skipping $($module.Name) - already processed through another package management system"
                continue
            }

            # Mark as processed
            $script:processedModules[$module.Name] = "PowerShellGet"

            # Skip excluded modules
            if (Test-ModuleExcluded -ModuleName $module.Name) {
                Write-Verbose "Skipping excluded module: $($module.Name)"
                $summary.SkippedCount++
                $summary.DetailedResults += [PSCustomObject]@{
                    Name       = $module.Name
                    Type       = "Module (PowerShellGet)"
                    Action     = "Skipped - Excluded"
                    OldVersion = $module.Version
                    NewVersion = $null
                    Path       = $module.InstalledLocation
                }
                continue
            }

            try {
                # Check for available updates using prioritized repos with credentials
                $findParams = @{
                    Name              = $module.Name
                    IncludePrerelease = $IncludePrerelease
                }

                if ($Credential) {
                    $findParams['Credential'] = $Credential
                }

                $latestModule = Find-LatestModule @findParams

                if ($module.Version -ne $latestModule.Version) {
                    Write-Verbose "Module $($module.Name) - Current: $($module.Version), Latest: $($latestModule.Version)"

                    # Check if we can update (based on installation path and admin status)
                    $canUpdate = $true
                    $systemPath = $module.InstalledLocation -notlike "*$env:USERPROFILE*"

                    if ($systemPath -and -not $isAdmin) {
                        Write-ModuleError -ModuleName $module.Name -Message "Cannot update system-wide module without administrator privileges." -Category "Permission"
                        $canUpdate = $false
                        $summary.ErrorCount++
                    }

                    if ($canUpdate) {
                        # Update the module
                        Write-Verbose "Updating module: $($module.Name) to version $($latestModule.Version)"

                        # Prepare update parameters
                        $updateParams = @{
                            Name        = $module.Name
                            Force       = $true
                            ErrorAction = 'Stop'
                        }

                        if ($RepositoryName) {
                            $updateParams['Repository'] = $RepositoryName
                        }

                        if ($Credential) {
                            $updateParams['Credential'] = $Credential
                        }

                        # Execute update
                        if ($systemPath) {
                            Update-Module @updateParams
                            $summary.SystemModulesUpdated++
                        } else {
                            Update-Module @updateParams
                            $summary.UserModulesUpdated++
                        }

                        # Add to results
                        $summary.DetailedResults += [PSCustomObject]@{
                            Name       = $module.Name
                            Type       = "Module (PowerShellGet)"
                            Action     = "Updated"
                            OldVersion = $module.Version
                            NewVersion = $latestModule.Version
                            Path       = $module.InstalledLocation
                        }

                        # Remove old versions
                        # Get all versions of this module
                        $allVersions = Get-InstalledModule -Name $module.Name -AllVersions -ErrorAction Stop

                        # Determine which versions to keep
                        $versionsToRemove = @()

                        if ($KeepLatestMinorVersion) {
                            # Group by minor version and keep only the latest of each
                            $versionGroups = @{}

                            foreach ($ver in $allVersions) {
                                $minorKey = Get-MinorVersionKey -Version $ver.Version
                                if (-not $versionGroups.ContainsKey($minorKey) -or $ver.Version -gt $versionGroups[$minorKey].Version) {
                                    $versionGroups[$minorKey] = $ver
                                }
                            }

                            # All versions that aren't the latest in their minor version group
                            $versionsToRemove = $allVersions | Where-Object {
                                $minorKey = Get-MinorVersionKey -Version $_.Version
                                $_.Version -ne $versionGroups[$minorKey].Version
                            }
                        } else {
                            # Just keep the absolute latest version
                            $versionsToRemove = $allVersions | Where-Object { $_.Version -ne $latestModule.Version }
                        }

                        # Remove old versions
                        foreach ($oldVersion in $versionsToRemove) {
                            # Skip if it's a dependency and we're keeping dependencies
                            if ($KeepDependencies -and (Test-IsDependency -ModuleName $module.Name -Version $oldVersion.Version)) {
                                Write-Verbose "Keeping version $($oldVersion.Version) of $($module.Name) as it's a dependency"
                                continue
                            }

                            try {
                                Write-Verbose "Removing old version of $($module.Name): $($oldVersion.Version)"

                                # Prepare uninstall parameters
                                $uninstallParams = @{
                                    Name            = $module.Name
                                    RequiredVersion = $oldVersion.Version
                                    Force           = $true
                                    ErrorAction     = 'Stop'
                                }

                                if ($SkipDependencyCheck) {
                                    $uninstallParams['SkipDependencyCheck'] = $true
                                }

                                # Execute uninstall
                                Uninstall-Module @uninstallParams
                                $summary.OldVersionsRemoved++
                            } catch {
                                if ($_.Exception.Message -like "*dependency*") {
                                    Write-ModuleError -ModuleName $module.Name -Message "Failed to uninstall version $($oldVersion.Version) due to dependencies" -ErrorRecord $_ -Category "Dependency"
                                } else {
                                    Write-ModuleError -ModuleName $module.Name -Message "Failed to uninstall version $($oldVersion.Version)" -ErrorRecord $_ -Category "Uninstallation"
                                }
                                $summary.ErrorCount++
                            }
                        }
                    }
                } else {
                    Write-Verbose "Module $($module.Name) is already at the latest version: $($module.Version)"
                    $summary.DetailedResults += [PSCustomObject]@{
                        Name       = $module.Name
                        Type       = "Module (PowerShellGet)"
                        Action     = "Skipped - Already Latest"
                        OldVersion = $module.Version
                        NewVersion = $module.Version
                        Path       = $module.InstalledLocation
                    }
                }
            } catch {
                if ($_.Exception.Message -like "*No match was found for the specified search criteria*") {
                    Write-Warning "Module $($module.Name) is no longer available in the repository."
                    $script:errorCategories["Repository"]++
                } elseif ($_.Exception.Message -like "*401*" -or $_.Exception.Message -like "*Unauthorized*") {
                    Write-ModuleError -ModuleName $module.Name -Message "Authentication error when accessing repository" -ErrorRecord $_ -Category "Authentication"
                } else {
                    Write-ModuleError -ModuleName $module.Name -Message "Error updating module" -ErrorRecord $_ -Category "General"
                }
                $summary.ErrorCount++
            }
        }

        Write-Progress -Activity "Updating PowerShell modules (PowerShellGet)" -Completed
    } catch {
        Write-Warning "Error processing PowerShellGet modules: $_"
        $script:errorCategories["General"]++
    }

    #endregion PowerShellGet Modules

    #region PSResourceGet Resources (if available)

    if ($psrAvailable) {
        Write-Verbose "Processing PSResourceGet resources..."

        try {
            # Import the module
            Import-Module Microsoft.PowerShell.PSResourceGet -ErrorAction Stop

            # Get all installed resources
            $allResources = Get-PSResource -ErrorAction SilentlyContinue
            $totalResources = ($allResources | Measure-Object).Count

            Write-Verbose "Found $totalResources resources installed via PSResourceGet"

            # Initialize progress bar
            $progressParams = @{
                Activity        = "Updating PowerShell resources (PSResourceGet)"
                Status          = "Processing resources"
                PercentComplete = 0
            }

            # Process each resource
            for ($i = 0; $i -lt $totalResources; $i++) {
                $resource = $allResources[$i]
                $progressParams.PercentComplete = ($i / $totalResources * 100)
                $progressParams.CurrentOperation = "Processing $($resource.Name) [$($i + 1)/$totalResources]"
                Write-Progress @progressParams

                # Skip if already processed by another system
                if ($script:processedModules.ContainsKey($resource.Name)) {
                    Write-Verbose "Skipping $($resource.Name) - already processed through another package management system"
                    continue
                }

                # Mark as processed
                $script:processedModules[$resource.Name] = "PSResourceGet"

                # Skip excluded resources
                if (Test-ModuleExcluded -ModuleName $resource.Name) {
                    Write-Verbose "Skipping excluded resource: $($resource.Name)"
                    $summary.SkippedCount++
                    $summary.DetailedResults += [PSCustomObject]@{
                        Name       = $resource.Name
                        Type       = $resource.Type
                        Action     = "Skipped - Excluded"
                        OldVersion = $resource.Version
                        NewVersion = $null
                        Path       = $resource.InstalledLocation
                    }
                    continue
                }

                try {
                    # Check for latest version using prioritized repos with credentials
                    $findParams = @{
                        Name              = $resource.Name
                        IncludePrerelease = $IncludePrerelease
                    }

                    if ($Credential) {
                        $findParams['Credential'] = $Credential
                    }

                    $latestResource = Find-LatestPSResource @findParams

                    if ($resource.Version -ne $latestResource.Version) {
                        Write-Verbose "$($resource.Type) $($resource.Name) - Current: $($resource.Version), Latest: $($latestResource.Version)"

                        # Check if we can update (based on installation path and admin status)
                        $canUpdate = $true
                        $systemPath = $resource.InstalledLocation -notlike "*$env:USERPROFILE*" -and $resource.InstalledLocation -notlike "*$env:HOME*"

                        if ($systemPath -and -not $isAdmin) {
                            Write-ModuleError -ModuleName $resource.Name -Message "Cannot update system-wide $($resource.Type) without administrator privileges." -Category "Permission"
                            $canUpdate = $false
                            $summary.ErrorCount++
                        }

                        if ($canUpdate) {
                            # Update the resource
                            Write-Verbose "Updating $($resource.Type): $($resource.Name) to version $($latestResource.Version)"

                            # Prepare update parameters
                            $updateParams = @{
                                Name        = $resource.Name
                                Force       = $true
                                ErrorAction = 'Stop'
                            }

                            if ($IncludePrerelease) {
                                $updateParams['Prerelease'] = $true
                            }

                            if ($RepositoryName) {
                                $updateParams['Repository'] = $RepositoryName
                            }

                            if ($Credential) {
                                $updateParams['Credential'] = $Credential
                            }

                            # Execute update
                            if ($systemPath) {
                                $updateParams['Scope'] = 'AllUsers'
                                Update-PSResource @updateParams
                                $summary.SystemModulesUpdated++
                            } else {
                                $updateParams['Scope'] = 'CurrentUser'
                                Update-PSResource @updateParams

                                if ($resource.Type -eq 'Script') {
                                    $summary.ScriptsUpdated++
                                } else {
                                    $summary.UserModulesUpdated++
                                }
                            }

                            # Add to results
                            $summary.DetailedResults += [PSCustomObject]@{
                                Name       = $resource.Name
                                Type       = "$($resource.Type) (PSResourceGet)"
                                Action     = "Updated"
                                OldVersion = $resource.Version
                                NewVersion = $latestResource.Version
                                Path       = $resource.InstalledLocation
                            }

                            # Remove old versions if resource type is Module or Script
                            if ($resource.Type -eq 'Module' -or $resource.Type -eq 'Script') {
                                # Get all versions of this resource
                                $allVersions = Get-PSResource -Name $resource.Name -ErrorAction Stop

                                # Determine which versions to remove
                                $versionsToRemove = @()

                                if ($KeepLatestMinorVersion) {
                                    # Group by minor version and keep only the latest of each
                                    $versionGroups = @{}

                                    foreach ($ver in $allVersions) {
                                        $minorKey = Get-MinorVersionKey -Version $ver.Version

                                        if (-not $versionGroups.ContainsKey($minorKey) -or $ver.Version -gt $versionGroups[$minorKey].Version) {
                                            $versionGroups[$minorKey] = $ver
                                        }
                                    }

                                    # All versions that aren't the latest in their minor version group
                                    $versionsToRemove = $allVersions | Where-Object {
                                        $minorKey = Get-MinorVersionKey -Version $_.Version
                                        $_.Version -ne $versionGroups[$minorKey].Version
                                    }
                                } else {
                                    # Just keep the absolute latest version
                                    $versionsToRemove = $allVersions | Where-Object { $_.Version -ne $latestResource.Version }
                                }

                                # Remove old versions
                                foreach ($oldVersion in $versionsToRemove) {
                                    # Skip if it's a dependency and we're keeping dependencies
                                    if ($KeepDependencies -and (Test-IsDependency -ModuleName $resource.Name -Version $oldVersion.Version)) {
                                        Write-Verbose "Keeping version $($oldVersion.Version) of $($resource.Name) as it's a dependency"
                                        continue
                                    }

                                    try {
                                        Write-Verbose "Removing old version of $($resource.Name): $($oldVersion.Version)"

                                        # Prepare uninstall parameters
                                        $uninstallParams = @{
                                            Name        = $resource.Name
                                            Version     = "[$($oldVersion.Version)]"
                                            Force       = $true
                                            ErrorAction = 'Stop'
                                        }

                                        if ($SkipDependencyCheck) {
                                            $uninstallParams['SkipDependencyCheck'] = $true
                                        }

                                        # Execute uninstall
                                        Uninstall-PSResource @uninstallParams
                                        $summary.OldVersionsRemoved++
                                    } catch {
                                        if ($_.Exception.Message -like "*dependency*") {
                                            Write-ModuleError -ModuleName $resource.Name -Message "Failed to uninstall version $($oldVersion.Version) due to dependencies" -ErrorRecord $_ -Category "Dependency"
                                        } else {
                                            Write-ModuleError -ModuleName $resource.Name -Message "Failed to uninstall version $($oldVersion.Version)" -ErrorRecord $_ -Category "Uninstallation"
                                        }
                                        $summary.ErrorCount++
                                    }
                                }
                            }
                        }
                    } else {
                        Write-Verbose "$($resource.Type) $($resource.Name) is already at the latest version: $($resource.Version)"
                        $summary.DetailedResults += [PSCustomObject]@{
                            Name       = $resource.Name
                            Type       = "$($resource.Type) (PSResourceGet)"
                            Action     = "Skipped - Already Latest"
                            OldVersion = $resource.Version
                            NewVersion = $resource.Version
                            Path       = $resource.InstalledLocation
                        }
                    }
                } catch {
                    if ($_.Exception.Message -like "*No match was found for the specified search criteria*") {
                        Write-Warning "$($resource.Type) $($resource.Name) is no longer available in the repository."
                        $script:errorCategories["Repository"]++
                    } elseif ($_.Exception.Message -like "*401*" -or $_.Exception.Message -like "*Unauthorized*") {
                        Write-ModuleError -ModuleName $resource.Name -Message "Authentication error when accessing repository" -ErrorRecord $_ -Category "Authentication"
                    } else {
                        Write-ModuleError -ModuleName $resource.Name -Message "Error updating $($resource.Type)" -ErrorRecord $_ -Category "General"
                    }
                    $summary.ErrorCount++
                }
            }

            Write-Progress -Activity "Updating PowerShell resources (PSResourceGet)" -Completed
        } catch {
            Write-Warning "Error processing PSResourceGet resources: $_"
            $script:errorCategories["General"]++
        }
    }

    #endregion PSResourceGet Resources

    #region Finalize and Report

    # Calculate runtime
    $endTime = Get-Date
    $runtime = $endTime - $startTime
    $summary.RuntimeMinutes = [math]::Round($runtime.TotalMinutes, 2)

    # Update error categories in summary
    $summary.ErrorCategories = $script:errorCategories

    # Output summary
    Write-Host "`n===== Update Summary =====" -ForegroundColor Cyan
    Write-Host "System modules updated: $($summary.SystemModulesUpdated)" -ForegroundColor Green
    Write-Host "User modules updated: $($summary.UserModulesUpdated)" -ForegroundColor Green
    Write-Host "Scripts updated: $($summary.ScriptsUpdated)" -ForegroundColor Green
    Write-Host "Old versions removed: $($summary.OldVersionsRemoved)" -ForegroundColor Green
    Write-Host "Errors encountered: $($summary.ErrorCount)" -ForegroundColor ($summary.ErrorCount -gt 0 ? "Red" : "Green")
    Write-Host "Resources skipped: $($summary.SkippedCount)" -ForegroundColor Yellow
    Write-Host "Total runtime: $($summary.RuntimeMinutes) minutes" -ForegroundColor Cyan

    # Display error breakdown if errors occurred
    if ($summary.ErrorCount -gt 0) {
        Write-Host "`n----- Error Breakdown -----" -ForegroundColor Yellow
        foreach ($category in $script:errorCategories.Keys) {
            if ($script:errorCategories[$category] -gt 0) {
                Write-Host "$category errors: $($script:errorCategories[$category])" -ForegroundColor Yellow
            }
        }
    }

    # Display processed modules count
    Write-Host "`nTotal modules processed: $($script:processedModules.Count)" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan

    # Provide advice if authentication errors occurred
    if ($script:errorCategories["Authentication"] -gt 0) {
        Write-Host "`nTIP: Authentication errors occurred. Try running with credentials:" -ForegroundColor Yellow
        Write-Host "    Update-AllPSResources -Credential (Get-Credential) -RepositoryName 'YourRepo'" -ForegroundColor Yellow
    }

    # Provide advice if dependency errors occurred
    if ($script:errorCategories["Dependency"] -gt 0) {
        Write-Host "`nTIP: Dependency errors occurred. Try running with dependency options:" -ForegroundColor Yellow
        Write-Host "    Update-AllPSResources -SkipDependencyCheck" -ForegroundColor Yellow
        Write-Host "    # or" -ForegroundColor Yellow
        Write-Host "    Update-AllPSResources -KeepDependencies" -ForegroundColor Yellow
    }

    return $summary

    #endregion Finalize and Report
}
