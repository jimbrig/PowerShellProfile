function Analyze-PowerShellModuleState {
    [CmdletBinding()]
    param(
        [switch]$IncludePerformanceAnalysis,
        [switch]$CheckOneDriveImpact,
        [switch]$ExportReport
    )

    Write-Host '🔍 Analyzing PowerShell Module Configuration...' -ForegroundColor Cyan

    $analysis = @{
        SystemInfo       = @{}
        ModulePaths      = @{}
        InstalledModules = @{}
        Performance      = @{}
        OneDriveImpact   = @{}
        Recommendations  = @()
    }

    # System Information
    $analysis.SystemInfo = @{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Edition           = $PSVersionTable.PSEdition
        Platform          = $PSVersionTable.Platform
        OS                = $PSVersionTable.OS
        HasDevDrive       = (Get-Volume | Where-Object DriveType -eq 'Fixed' | Where-Object FileSystemType -eq 'ReFS').Count -gt 0
    }

    # Analyze Module Paths
    $modulePaths = $env:PSModulePath -split ';'
    $analysis.ModulePaths = @{
        AllPaths          = $modulePaths
        OneDrivePaths     = $modulePaths | Where-Object { $_ -like '*OneDrive*' }
        LocalPaths        = $modulePaths | Where-Object { $_ -notlike '*OneDrive*' }
        DevDrivePaths     = $modulePaths | Where-Object {
            $drive = Split-Path $_ -Qualifier
            $volume = Get-Volume -DriveLetter $drive.TrimEnd(':') -ErrorAction SilentlyContinue
            $volume.FileSystemType -eq 'ReFS'
        }
        LocalAppDataPaths = $modulePaths | Where-Object { $_ -like '*LocalAppData*' }
    }

    # Analyze Installed Modules
    Write-Host '📦 Analyzing installed modules...' -ForegroundColor Yellow

    $installedModules = Get-InstalledPSResource -ErrorAction SilentlyContinue
    if (-not $installedModules) {
        $installedModules = Get-InstalledModule -ErrorAction SilentlyContinue
    }

    $modulesByLocation = @{}
    $duplicateModules = @{}
    $largeModules = @()

    foreach ($path in $modulePaths) {
        if (Test-Path $path) {
            $modules = Get-ChildItem $path -Directory -ErrorAction SilentlyContinue
            $modulesByLocation[$path] = @{
                Count     = $modules.Count
                Modules   = $modules.Name
                TotalSize = if ($modules) {
                    ($modules | Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
                    Measure-Object Length -Sum).Sum / 1MB
                } else { 0 }
            }

            # Check for large modules (>100MB)
            $modules | ForEach-Object {
                $moduleSize = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                    Measure-Object Length -Sum).Sum / 1MB
                if ($moduleSize -gt 100) {
                    $largeModules += @{
                        Name   = $_.Name
                        Path   = $_.FullName
                        SizeMB = [math]::Round($moduleSize, 2)
                    }
                }
            }
        }
    }

    # Find duplicate modules across paths
    $allModuleNames = $modulesByLocation.Values | ForEach-Object { $_.Modules } | Group-Object
    $duplicateModules = $allModuleNames | Where-Object Count -gt 1 | ForEach-Object {
        @{
            ModuleName = $_.Name
            Locations  = $modulesByLocation.Keys | Where-Object {
                $modulesByLocation[$_].Modules -contains $_.Name
            }
        }
    }

    $analysis.InstalledModules = @{
        ByLocation     = $modulesByLocation
        Duplicates     = $duplicateModules
        LargeModules   = $largeModules
        TotalInstalled = $installedModules.Count
    }

    # Performance Analysis
    if ($IncludePerformanceAnalysis) {
        Write-Host '⚡ Running performance analysis...' -ForegroundColor Yellow

        $startupTime = Measure-Command {
            pwsh -NoProfile -Command 'Get-Module -ListAvailable | Out-Null'
        }

        $profileStartupTime = if (Test-Path $PROFILE) {
            Measure-Command {
                pwsh -Command '1'
            }
        } else {
            [TimeSpan]::Zero
        }

        $analysis.Performance = @{
            ModuleDiscoveryTime = $startupTime.TotalMilliseconds
            ProfileStartupTime  = $profileStartupTime.TotalMilliseconds
            SlowPaths           = $modulesByLocation.Keys | Where-Object {
                $_ -like '*OneDrive*' -or $modulesByLocation[$_].Count -gt 50
            }
        }
    }

    # OneDrive Impact Analysis
    if ($CheckOneDriveImpact) {
        Write-Host '☁️ Analyzing OneDrive impact...' -ForegroundColor Yellow

        $documentsPath = [Environment]::GetFolderPath('MyDocuments')
        $isOneDriveRedirected = $documentsPath -like '*OneDrive*'

        $oneDriveModules = if ($isOneDriveRedirected) {
            $oneDriveModulePath = Join-Path $documentsPath 'PowerShell\Modules'
            if (Test-Path $oneDriveModulePath) {
                (Get-ChildItem $oneDriveModulePath -Directory -ErrorAction SilentlyContinue).Count
            } else { 0 }
        } else { 0 }

        $analysis.OneDriveImpact = @{
            DocumentsRedirected = $isOneDriveRedirected
            DocumentsPath       = $documentsPath
            ModulesInOneDrive   = $oneDriveModules
            ProfileInOneDrive   = (Test-Path $PROFILE) -and ($PROFILE -like '*OneDrive*')
        }
    }

    # Generate Recommendations
    Write-Host '💡 Generating recommendations...' -ForegroundColor Green

    # OneDrive recommendations
    if ($analysis.OneDriveImpact.DocumentsRedirected) {
        $analysis.Recommendations += '🚨 HIGH PRIORITY: Documents folder is redirected to OneDrive. Consider disabling OneDrive backup for Documents or moving PowerShell configurations to local paths.'
    }

    if ($analysis.OneDriveImpact.ModulesInOneDrive -gt 0) {
        $analysis.Recommendations += "⚠️ MEDIUM PRIORITY: $($analysis.OneDriveImpact.ModulesInOneDrive) modules found in OneDrive. This can cause startup delays and sync conflicts."
    }

    # Dev Drive recommendations
    if ($analysis.SystemInfo.HasDevDrive -and $analysis.ModulePaths.DevDrivePaths.Count -eq 0) {
        $analysis.Recommendations += '🎯 OPTIMIZATION: Dev Drive detected but not used for PowerShell modules. Consider creating a module path on Dev Drive for better performance.'
    }

    # Performance recommendations
    if ($analysis.Performance.ModuleDiscoveryTime -gt 2000) {
        $analysis.Recommendations += "🐌 PERFORMANCE: Module discovery time is $([math]::Round($analysis.Performance.ModuleDiscoveryTime))ms. Consider reducing module paths or moving modules to faster storage."
    }

    # Duplicate module recommendations
    if ($duplicateModules.Count -gt 0) {
        $analysis.Recommendations += "🔄 CLEANUP: $($duplicateModules.Count) modules found in multiple locations. Consider consolidating to reduce confusion and improve performance."
    }

    # Large module recommendations
    if ($largeModules.Count -gt 0) {
        $totalLargeSize = ($largeModules | Measure-Object SizeMB -Sum).Sum
        $analysis.Recommendations += "💾 STORAGE: $($largeModules.Count) large modules detected (total: $([math]::Round($totalLargeSize))MB). Consider moving to Dev Drive or local storage."
    }

    # LocalAppData recommendation
    if ($analysis.ModulePaths.LocalAppDataPaths.Count -eq 0) {
        $analysis.Recommendations += '📁 SUGGESTION: Consider adding LocalAppData PowerShell module path as a OneDrive-free alternative.'
    }

    # Display Results
    Write-Host "`n📊 ANALYSIS RESULTS" -ForegroundColor Magenta
    Write-Host '===================' -ForegroundColor Magenta

    Write-Host "`n🖥️ System Information:" -ForegroundColor Cyan
    Write-Host "PowerShell: $($analysis.SystemInfo.PowerShellVersion) ($($analysis.SystemInfo.Edition))"
    Write-Host "Dev Drive Available: $($analysis.SystemInfo.HasDevDrive)"

    Write-Host "`n📂 Module Paths:" -ForegroundColor Cyan
    Write-Host "Total Paths: $($analysis.ModulePaths.AllPaths.Count)"
    Write-Host "OneDrive Paths: $($analysis.ModulePaths.OneDrivePaths.Count)"
    Write-Host "Dev Drive Paths: $($analysis.ModulePaths.DevDrivePaths.Count)"
    Write-Host "LocalAppData Paths: $($analysis.ModulePaths.LocalAppDataPaths.Count)"

    Write-Host "`n📦 Module Analysis:" -ForegroundColor Cyan
    Write-Host "Total Installed: $($analysis.InstalledModules.TotalInstalled)"
    Write-Host "Duplicate Modules: $($duplicateModules.Count)"
    Write-Host "Large Modules (>100MB): $($largeModules.Count)"

    if ($IncludePerformanceAnalysis) {
        Write-Host "`n⚡ Performance:" -ForegroundColor Cyan
        Write-Host "Module Discovery: $([math]::Round($analysis.Performance.ModuleDiscoveryTime))ms"
        Write-Host "Profile Startup: $([math]::Round($analysis.Performance.ProfileStartupTime))ms"
    }

    if ($CheckOneDriveImpact) {
        Write-Host "`n☁️ OneDrive Impact:" -ForegroundColor Cyan
        Write-Host "Documents Redirected: $($analysis.OneDriveImpact.DocumentsRedirected)"
        Write-Host "Modules in OneDrive: $($analysis.OneDriveImpact.ModulesInOneDrive)"
        Write-Host "Profile in OneDrive: $($analysis.OneDriveImpact.ProfileInOneDrive)"
    }

    Write-Host "`n💡 RECOMMENDATIONS" -ForegroundColor Green
    Write-Host '==================' -ForegroundColor Green
    $analysis.Recommendations | ForEach-Object { Write-Host $_ }

    # Provide specific commands
    Write-Host "`n🛠️ SUGGESTED COMMANDS" -ForegroundColor Yellow
    Write-Host '=====================' -ForegroundColor Yellow

    if ($analysis.SystemInfo.HasDevDrive) {
        Write-Host '# Create Dev Drive module path:'
        Write-Host '$devDriveModules = "D:\PowerShell\Modules"  # Adjust drive letter'
        Write-Host 'New-Item -Path $devDriveModules -ItemType Directory -Force'
        Write-Host '$env:PSModulePath = "$devDriveModules;$env:PSModulePath"'
    }

    if ($analysis.OneDriveImpact.DocumentsRedirected) {
        Write-Host "`n# Restore local Documents folder:"
        Write-Host '# 1. Open OneDrive Settings > Backup > Manage Backup'
        Write-Host '# 2. Turn off backup for Documents folder'
        Write-Host '# 3. Or modify registry: HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
    }

    Write-Host "`n# Add LocalAppData module path:"
    Write-Host '$localModules = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "PowerShell\Modules"'
    Write-Host 'New-Item -Path $localModules -ItemType Directory -Force'
    Write-Host '$env:PSModulePath = "$localModules;$env:PSModulePath"'

    if ($ExportReport) {
        $reportPath = Join-Path $PWD "PowerShell-Module-Analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $analysis | ConvertTo-Json -Depth 10 | Out-File $reportPath
        Write-Host "`n📄 Report exported to: $reportPath" -ForegroundColor Green
    }

    return $analysis
}

# Example usage with all analysis options
Analyze-PowerShellModuleState -IncludePerformanceAnalysis -CheckOneDriveImpact -ExportReport
