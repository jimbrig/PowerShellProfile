Function Sync-ProfileModules {
    <#
    .SYNOPSIS
        Synchronizes installed modules with configuration.
    .DESCRIPTION
        Compares installed modules against Source/Configuration/Modules.psd1
        and reports differences. Optionally installs missing modules or removes extras.
    .PARAMETER Install
        Install missing modules that are in configuration but not installed.
    .PARAMETER Remove
        Remove installed modules that are not in configuration.
    .PARAMETER Export
        Update configuration with currently installed modules.
    .EXAMPLE
        Sync-ProfileModules
        Shows differences between installed and configured modules.
    .EXAMPLE
        Sync-ProfileModules -Install
        Installs any missing modules.
    .EXAMPLE
        Sync-ProfileModules -Export
        Updates configuration with current state.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$Install,
        [switch]$Remove,
        [switch]$Export
    )

    $profileRoot = Split-Path -Path $PROFILE -Parent
    $configPath = Join-Path $profileRoot 'Source\Configuration\Modules.psd1'

    # Load configuration
    $config = Import-PowerShellDataFile -Path $configPath
    $configuredModules = $config.Modules | ForEach-Object { $_.Name }

    # Get installed modules
    $installedModules = Get-InstalledPSResource -Scope CurrentUser |
        Where-Object { $_.Name -notmatch '^(Microsoft\.PowerShell\.|PackageManagement|PowerShellGet)$' } |
        Group-Object Name |
        ForEach-Object { $_.Group | Sort-Object Version -Descending | Select-Object -First 1 }

    $installedNames = $installedModules.Name

    # Compare
    $missingModules = $configuredModules | Where-Object { $_ -notin $installedNames }
    $extraModules = $installedNames | Where-Object { $_ -notin $configuredModules }

    Write-Host "Module Synchronization Report" -ForegroundColor Cyan
    Write-Host "=" * 50
    Write-Host ""

    if ($missingModules) {
        Write-Host "Missing modules (in config, not installed): $($missingModules.Count)" -ForegroundColor Yellow
        $missingModules | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        Write-Host ""

        if ($Install) {
            Write-Host "Installing missing modules..." -ForegroundColor Cyan
            foreach ($module in $missingModules) {
                Install-ProfileModules -ModuleName $module
            }
        }
    } else {
        Write-Host "✓ All configured modules are installed" -ForegroundColor Green
        Write-Host ""
    }

    if ($extraModules) {
        Write-Host "Extra modules (installed, not in config): $($extraModules.Count)" -ForegroundColor Magenta
        $extraModules | ForEach-Object { Write-Host "  + $_" -ForegroundColor Magenta }
        Write-Host ""

        if ($Export) {
            Write-Host "Exporting current state to configuration..." -ForegroundColor Cyan
            Export-ProfileModules
        } elseif ($Remove) {
            Write-Host "Removing extra modules..." -ForegroundColor Cyan
            foreach ($module in $extraModules) {
                if ($PSCmdlet.ShouldProcess($module, "Uninstall module")) {
                    Uninstall-PSResource -Name $module -Scope CurrentUser
                    Write-Host "✓ Removed $module" -ForegroundColor Green
                }
            }
        }
    } else {
        Write-Host "✓ No extra modules installed" -ForegroundColor Green
        Write-Host ""
    }

    if (-not $missingModules -and -not $extraModules) {
        Write-Host "🎉 Modules are in perfect sync!" -ForegroundColor Green
    }
}
