<#
.SYNOPSIS
    Exports currently installed modules to Modules.psd1 configuration.
.DESCRIPTION
    Scans installed modules and generates/updates Source/Configuration/Modules.psd1
    with current versions. Excludes built-in Windows modules.
.PARAMETER ExcludePattern
    Regex pattern for module names to exclude (default: built-in Windows modules).
.PARAMETER IncludeAllVersions
    Include all installed versions, not just the latest.
.EXAMPLE
    .\Source\Scripts\Export-InstalledModules.ps1
.EXAMPLE
    .\Source\Scripts\Export-InstalledModules.ps1 -ExcludePattern 'Microsoft\.PowerShell\.|Az\.'
#>
[CmdletBinding()]
param(
    [string]$ExcludePattern = '^(Microsoft\.(PowerShell|WSMan)|PackageManagement|PowerShellGet|PSReadLine)$',
    [switch]$IncludeAllVersions
)

$outputPath = Join-Path $PSScriptRoot '..\Configuration\Modules.psd1'

Write-Host "Scanning installed modules..." -ForegroundColor Cyan

# Get all installed modules from CurrentUser scope
$installedModules = Get-InstalledPSResource -Scope CurrentUser |
    Where-Object {
        $_.Name -notmatch $ExcludePattern -and
        $_.Repository -eq 'PSGallery'  # Only PSGallery modules
    } |
    Sort-Object Name

if (-not $IncludeAllVersions) {
    # Group by name and take latest version only
    $installedModules = $installedModules |
        Group-Object Name |
        ForEach-Object {
            $_.Group | Sort-Object Version -Descending | Select-Object -First 1
        }
}

Write-Host "Found $($installedModules.Count) modules to export" -ForegroundColor Green
Write-Host ""

# Build configuration
$moduleEntries = $installedModules | ForEach-Object {
    $version = if ($_.Version) { "'$($_.Version)'" } else { '$null' }
    $repo = if ($_.Repository) { "'$($_.Repository)'" } else { "'PSGallery'" }

    "        @{ Name = '$($_.Name)'; Version = $version; Repository = $repo }"
}

$content = @"
@{
    # Third-party PowerShell module dependencies
    # Auto-generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    # Install with: Source/Scripts/Install-RequiredModules.ps1
    Modules = @(
$($moduleEntries -join "`n")
    )
}
"@

# Write to file
$content | Set-Content -Path $outputPath -Encoding UTF8
Write-Host "✓ Exported to: $outputPath" -ForegroundColor Green

# Show preview
Write-Host ""
Write-Host "Preview of exported modules:" -ForegroundColor Cyan
$installedModules | Format-Table Name, Version, Repository -AutoSize
