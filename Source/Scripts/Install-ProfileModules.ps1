<#
    .SYNOPSIS
        Installs all required PowerShell modules for this profile.
    .DESCRIPTION
        Reads module requirements from Source/Configuration/Modules.psd1 and installs them using
        `Install-PSResource` (PSResourceGet).
    .PARAMETER Force
        Forces reinstallation of modules even if they already exist.
    .EXAMPLE
        .\Source\Scripts\Install-RequiredModules.ps1
    .EXAMPLE
        .\Source\Scripts\Install-RequiredModules.ps1 -Force
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Load module requirements
$configPath = Join-Path $PSScriptRoot '..\Configuration\Modules.psd1'
if (-not (Test-Path $configPath)) {
    throw "Configuration file not found: $configPath"
}

$config = Import-PowerShellDataFile -Path $configPath
$modules = $config.Modules

Write-Host "Installing $($modules.Count) required modules..." -ForegroundColor Cyan
Write-Host ""

foreach ($module in $modules) {
    $moduleName = $module.Name

    try {
        # Check if already installed
        $installed = Get-InstalledPSResource -Name $moduleName -ErrorAction SilentlyContinue

        if ($installed -and -not $Force) {
            Write-Host "✓ $moduleName " -ForegroundColor Green -NoNewline
            Write-Host "already installed ($($installed.Version))" -ForegroundColor Gray
            continue
        }

        # Build install parameters
        $installParams = @{
            Name       = $moduleName
            Repository = $module.Repository ?? 'PSGallery'
            Scope      = 'CurrentUser'
            TrustRepository = $true
        }

        if ($module.Version) {
            $installParams.Version = $module.Version
        }

        if ($Force) {
            $installParams.Reinstall = $true
        }

        # Install module
        Write-Host "⏳ Installing $moduleName" -ForegroundColor Yellow -NoNewline
        if ($module.Version) {
            Write-Host " (v$($module.Version))..." -ForegroundColor Gray
        } else {
            Write-Host " (latest)..." -ForegroundColor Gray
        }

        if ($PSCmdlet.ShouldProcess($moduleName, "Install module")) {
            Install-PSResource @installParams -ErrorAction Stop
            Write-Host "✓ Successfully installed $moduleName" -ForegroundColor Green
        }

    } catch {
        Write-Warning "✗ Failed to install ${moduleName}: $_"
    }
}

Write-Host ""
Write-Host "Module installation complete!" -ForegroundColor Cyan
