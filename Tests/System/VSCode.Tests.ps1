#Requires -Module Pester

<#
.SYNOPSIS
    Tests for Visual Studio Code configuration and setup.

.DESCRIPTION
    This script contains tests to verify the installation and configuration of Visual Studio Code on the system.
#>

Describe 'Visual Studio Code Installation and Configuration' {
    BeforeAll {
        $Script:vscodePath = "$Env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
    }

    It 'Checks that Visual Studio Code is installed' {
        Test-Path -Path $vscodePath | Should -Be $true
    }

    It 'Checks that the settings.json file exists' {
        $settingsPath = "$Env:APPDATA\Code\User\settings.json"
        Test-Path -Path $settingsPath | Should -Be $true
    }

    It 'Checks that the extensions directory exists' {
        $extensionsPath = "$Env:USERPROFILE\.vscode\extensions"
        Test-Path -Path $extensionsPath | Should -Be $true
    }

    It 'Checks that the PowerShell extension is installed' {
        $extensions = (code --list-extensions)
        $extensions.Contains('ms-vscode.powershell') | Should -Be $true
    }
}
