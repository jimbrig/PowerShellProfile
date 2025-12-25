Function Export-ProfileModules {
    <#
    .SYNOPSIS
        Exports currently installed modules to Modules.psd1 configuration.
    .DESCRIPTION
        Scans installed modules from the user scope and generates/updates
        Source/Configuration/Modules.psd1 with current versions.

        By default, excludes only PowerShell Core system modules. All user-installed
        modules are included since these are manually installed and should be tracked.
    .PARAMETER ExcludePattern
        Regex pattern for module names to exclude. Default excludes only system modules
        that ship with PowerShell Core.
    .PARAMETER IncludeAllVersions
        Include all installed versions, not just the latest.
    .PARAMETER PassThru
        Return the list of exported modules.
    .EXAMPLE
        Export-ProfileModules
        Exports all user-installed modules to configuration.
    .EXAMPLE
        Export-ProfileModules -ExcludePattern 'Az\.|AWS\.'
        Exports modules but excludes Azure and AWS modules.
    .EXAMPLE
        Export-ProfileModules -IncludeAllVersions
        Exports all versions of each module.
    #>
    [CmdletBinding()]
    [Alias('Export-InstalledModules')]
    param(
        [string]$ExcludePattern = '^(Microsoft\.PowerShell\.(Archive|Host|Management|Security|Utility)|Microsoft\.WSMan\.Management|PackageManagement|Pester|PowerShellGet|PSReadLine|ThreadJob)$',
        [switch]$IncludeAllVersions,
        [switch]$PassThru
    )

    $profileRoot = Split-Path -Path $PROFILE -Parent
    $outputPath = Join-Path $profileRoot 'Source\Configuration\Modules.psd1'

    Write-Host "Scanning installed modules in user scope..." -ForegroundColor Cyan

    # Get all installed modules from CurrentUser scope
    # This targets ~\Documents\PowerShell\Modules specifically
    $userModulesPath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'

    $installedModules = Get-InstalledPSResource -Scope CurrentUser |
        Where-Object {
            # Exclude only PowerShell Core system modules
            $_.Name -notmatch $ExcludePattern
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

    # Build configuration with categorization
    $categories = @{
        'Editor/UI'        = @('PSReadLine', 'Terminal-Icons', 'Microsoft.PowerShell.ConsoleGuiTools', 'F7History', 'MagicTooltips')
        'Version Control'  = @('posh-git')
        'AI/Assistant'     = @('AIShell', 'tiPS')
        'Testing/Quality'  = @('Pester', 'PSScriptAnalyzer')
        'Development'      = @('Plaster', 'platyPS', 'PSDepend', 'PowerShellBuild', 'psake', 'Plaster', 'Configuration', 'Microsoft.PowerShell.Crescendo')
        'Security'         = @('Microsoft.PowerShell.SecretManagement', 'Microsoft.PowerShell.SecretStore')
        'Windows'          = @('PSWindowsUpdate', 'VirtualDesktop')
        'Package Mgmt'     = @('Microsoft.WinGet.Client', 'Microsoft.WinGet.Configuration', 'Microsoft.WinGet.DSC', 'WingetTools')
        'Utilities'        = @('psyml', 'powershell-yaml')
    }

    $modulesByCategory = @{}
    foreach ($category in $categories.Keys) {
        $modulesByCategory[$category] = $installedModules | Where-Object { $categories[$category] -contains $_.Name }
    }
    $uncategorized = $installedModules | Where-Object {
        $moduleName = $_.Name
        -not ($categories.Values | ForEach-Object { $_ -contains $moduleName } | Where-Object { $_ })
    }
    if ($uncategorized) {
        $modulesByCategory['Other'] = $uncategorized
    }

    # Build content with categories
    $contentParts = @()
    $contentParts += @"
@{
    # Third-party PowerShell module dependencies
    # Auto-generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    # Source: $userModulesPath
    # Install with: Install-ProfileModules
    # Total modules: $($installedModules.Count)
    Modules = @(
"@

    foreach ($category in $modulesByCategory.Keys | Sort-Object) {
        $modules = $modulesByCategory[$category]
        if ($modules) {
            $contentParts += "        # $category"
            foreach ($module in $modules | Sort-Object Name) {
                $version = if ($module.Version) { "'$($module.Version)'" } else { '$null' }
                $repo = if ($module.Repository) { "'$($module.Repository)'" } else { "'PSGallery'" }
                $contentParts += "        @{ Name = '$($module.Name)'; Version = $version; Repository = $repo }"
            }
            $contentParts += ""
        }
    }

    $contentParts += "    )`n}"
    $content = $contentParts -join "`n"

    # Write to file
    $content | Set-Content -Path $outputPath -Encoding UTF8
    Write-Host "✓ Exported to: $outputPath" -ForegroundColor Green

    # Show preview
    Write-Host ""
    Write-Host "Preview of exported modules:" -ForegroundColor Cyan
    $installedModules | Format-Table Name, Version, Repository -AutoSize

    if ($PassThru) {
        return $installedModules
    }
}
