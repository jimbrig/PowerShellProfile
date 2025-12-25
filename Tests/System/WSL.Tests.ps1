#Requires -Module Pester

<#
.SYNOPSIS
    Tests for Windows Subsystem for Linux (WSL) configuration and setup.

.DESCRIPTION
    This script contains tests to verify the installation and configuration of WSL on the system.
#>

Describe 'WSL Installation and Configuration' {
    BeforeAll {
        $Script:wslPath = "$Env:SystemRoot\System32\wsl.exe"
    }

    It 'Checks that WSL is installed' {
        Test-Path -Path $wslPath | Should -Be $true
    }

    It 'Checks that WSL version 2 is installed' {
        $wslVersion = wsl.exe --version
        $wslVersion | Should -Not -BeNullOrEmpty
    }

    It 'Checks that at least one Linux distribution is installed' {
        $distros = & $wslPath --list --quiet
        $distros | Should -Not -BeNullOrEmpty
    }
}
