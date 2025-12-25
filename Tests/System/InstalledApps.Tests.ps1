#Requires -Module Pester

<#
.SYNOPSIS
    Tests for verifying the installation of commonly used applications.

.DESCRIPTION
    This script contains tests to verify the installation and configuration of various commonly used applications on the system.
#>

Describe 'Installed Applications' {

    BeforeAll {
        # Ensure User Environment PATH Variables are loaded
        if (-not $env:Path.Contains([System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User))) {
            $env:Path += [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User)
        }
    }

    It 'Checks that Git is installed' {
        Get-Command git -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Checks that Node.js is installed' {
        Get-Command node -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Checks that npm is installed' {
        Get-Command npm -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Checks that Python is installed' {
        Get-Command python -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Checks that Docker is installed' {
        Get-Command docker -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Checks that Visual Studio Code is installed' {
        Get-Command code -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}
