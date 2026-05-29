#Requires -Module Pester

<#
.SYNOPSIS
    Tests for verifying the installation of commonly used PowerShell modules.

.DESCRIPTION
    Verifies the expected PowerShell modules are installed via PSResourceGet
    (Get-InstalledPSResource). This deliberately does not fall back to
    Get-Module -ListAvailable, so modules installed via the legacy
    PowerShellGet/Install-Module are reported as missing and can be migrated.
#>

Describe 'Installed PowerShell Modules' -Tag 'System', 'Modules' {

    It 'Checks that the <_> module is installed' -ForEach @(
        'CompletionPredictor'
        'Configuration'
        'Microsoft.PowerShell.ConsoleGuiTools'
        'Microsoft.PowerShell.Crescendo'
        'Microsoft.PowerShell.PSResourceGet'
        'Microsoft.PowerShell.SecretManagement'
        'Microsoft.PowerShell.SecretStore'
        'Microsoft.PowerShell.ThreadJob'
        'Microsoft.PowerShell.WhatsNew'
        'Microsoft.WinGet.Client'
        'PackageManagement'
        'Pester'
        'Plaster'
        'platyPS'
        'posh-git'
        'powershell-yaml'
        'PowerShellBuild'
        'PowerShellGet'
        'psake'
        'PSDepend'
        'PSReadLine'
        'PSScriptAnalyzer'
        'PSWindowsUpdate'
        'Terminal-Icons'
    ) {
        # intentionally Get-InstalledPSResource only: modules should be installed
        # via PSResourceGet, not the legacy PowerShellGet/Install-Module
        Get-InstalledPSResource -Name $_ -ErrorAction SilentlyContinue |
        Should -Not -BeNullOrEmpty -Because "the '$_' module should be installed via PSResourceGet"
    }
}
