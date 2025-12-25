Function Install-ProfileModules {
    <#
    .SYNOPSIS
        Installs all required PowerShell modules for this profile.
    .DESCRIPTION
        Reads module requirements from Source/Configuration/Modules.psd1 and
        installs them using Install-PSResource (PSResourceGet).
    .PARAMETER Force
        Forces reinstallation of modules even if they already exist.
    .PARAMETER ModuleName
        Install only a specific module by name.
    .EXAMPLE
        Install-ProfileModules
        Installs all modules defined in configuration.
    .EXAMPLE
        Install-ProfileModules -Force
        Reinstalls all modules.
    .EXAMPLE
        Install-ProfileModules -ModuleName Pester
        Installs only the Pester module.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Install-RequiredModules')]
    param(
        [switch]$Force,
        [string]$ModuleName
    )

    $ErrorActionPreference = 'Stop'

    # Load module requirements
    $profileRoot = Split-Path -Path $PROFILE -Parent
    $configPath = Join-Path $profileRoot 'Source\Configuration\Modules.psd1'

    if (-not (Test-Path $configPath)) {
        throw "Configuration file not found: $configPath"
    }

    $config = Import-PowerShellDataFile -Path $configPath
    $modules = $config.Modules

    # Filter if specific module requested
    if ($ModuleName) {
        $modules = $modules | Where-Object { $_.Name -eq $ModuleName }
        if (-not $modules) {
            throw "Module '$ModuleName' not found in configuration"
        }
    }

    Write-Host "Installing $($modules.Count) required module(s)..." -ForegroundColor Cyan
    Write-Host ""

    $successCount = 0
    $failCount = 0

    foreach ($module in $modules) {
        $name = $module.Name

        try {
            # Check if already installed
            $installed = Get-InstalledPSResource -Name $name -ErrorAction SilentlyContinue |
                Sort-Object Version -Descending |
                Select-Object -First 1

            if ($installed -and -not $Force) {
                # Check version match
                if ($module.Version -and $installed.Version -ne $module.Version) {
                    Write-Host "⚠ $name " -ForegroundColor Yellow -NoNewline
                    Write-Host "installed ($($installed.Version)) differs from config ($($module.Version))" -ForegroundColor Gray
                } else {
                    Write-Host "✓ $name " -ForegroundColor Green -NoNewline
                    Write-Host "already installed ($($installed.Version))" -ForegroundColor Gray
                    $successCount++
                    continue
                }
            }

            # Build install parameters
            $installParams = @{
                Name            = $name
                Repository      = $module.Repository ?? 'PSGallery'
                Scope           = 'CurrentUser'
                TrustRepository = $true
            }

            if ($module.Version) {
                $installParams.Version = $module.Version
            }

            if ($Force) {
                $installParams.Reinstall = $true
            }

            # Install module
            Write-Host "⏳ Installing $name" -ForegroundColor Yellow -NoNewline
            if ($module.Version) {
                Write-Host " (v$($module.Version))..." -ForegroundColor Gray
            } else {
                Write-Host " (latest)..." -ForegroundColor Gray
            }

            if ($PSCmdlet.ShouldProcess($name, "Install module")) {
                Install-PSResource @installParams -ErrorAction Stop
                Write-Host "✓ Successfully installed $name" -ForegroundColor Green
                $successCount++
            }

        } catch {
            Write-Warning "✗ Failed to install ${name}: $_"
            $failCount++
        }
    }

    Write-Host ""
    Write-Host "Installation complete: " -ForegroundColor Cyan -NoNewline
    Write-Host "$successCount succeeded" -ForegroundColor Green -NoNewline
    if ($failCount -gt 0) {
        Write-Host ", $failCount failed" -ForegroundColor Red
    } else {
        Write-Host ""
    }
}
