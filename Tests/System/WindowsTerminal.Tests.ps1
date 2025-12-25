#Requires -Module Pester

<#
.SYNOPSIS
    Tests for Windows Terminal configuration and setup.

.DESCRIPTION
    This script contains tests to verify the installation and configuration of Windows Terminal on the system.
#>

Describe 'Windows Terminal Installation and Configuration' {
    BeforeAll {
        $Script:TerminalPath = "$Env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
        $Script:SettingsPath = "$Env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    }

    It 'Checks that Windows Terminal is installed' {
        Test-Path -Path $TerminalPath | Should -Be $true
    }

    It 'Checks that the settings.json file exists' {
        Test-Path -Path $SettingsPath | Should -Be $true
    }

    It 'Checks that the settings.json file is not empty' {
        $SettingsContent = Get-Content -Path $SettingsPath -ErrorAction SilentlyContinue
        $SettingsContent | Should -Not -BeNullOrEmpty
    }

    It 'Checks that the default profile is set to PowerShell' {
        $SettingsContent = Get-Content -Path $SettingsPath -Raw | ConvertFrom-Json
        $DefaultProfile = $SettingsContent.defaultProfile
        $PowerShellProfile = $SettingsContent.profiles.list | Where-Object { $_.Name -eq "PowerShell" }
        $DefaultProfile | Should -BeExactly $PowerShellProfile.guid
    }
}
