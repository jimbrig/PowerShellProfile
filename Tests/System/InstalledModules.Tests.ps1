#Requires -Module Pester

<#
.SYNOPSIS
    Tests for verifying the installation of commonly used PowerShell modules.

.DESCRIPTION
    This script contains tests to verify the installation and configuration of various commonly used PowerShell modules on the system.
#>

Describe 'Installed PowerShell Modules' {

    It "Checks that the <ModuleName> module is installed" -ForEach @(
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
        Get-InstalledPSResource -Name $_ | Should -Not -BeNullOrEmpty
    }
}
