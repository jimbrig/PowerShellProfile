#Requires -Module Pester

<#
.SYNOPSIS
    Tests for Windows File Explorer configuration and setup.

.DESCRIPTION
    This script contains tests to verify the configuration and setup of Windows File Explorer on the system.
#>

Describe 'Windows File Explorer Configuration and Setup' {
    BeforeAll {
        $Script:ExplorerRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
        $Script:AdvancedRegistryPath = "$ExplorerRegistryPath\Advanced"
    }

    It 'Checks that File Explorer registry path exists' {
        Test-Path -Path $ExplorerRegistryPath | Should -Be $true
    }

    It 'Checks that File Explorer is set to open new "Home" by default' {
        $splat = @{
            Path        = $AdvancedRegistryPath
            Name        = 'LaunchTo'
            ErrorAction = 'SilentlyContinue'
        }
        $Val = Get-ItemProperty @splat
        If ($Val) {
            $Val.LaunchTo | Should -BeExactly 2
        } Else {
            Write-Info -Message 'Registry key not found...'
        }
    }

    It 'Checks that hidden files are shown' {
        $splat = @{
            Path        = "$ExplorerRegistryPath\Advanced"
            Name        = 'Hidden'
            ErrorAction = 'SilentlyContinue'
        }
        $Val = Get-ItemProperty @splat
        If ($Val) {
            $Val.Hidden | Should -BeExactly 1
        } Else {
            Write-Info -Message 'Registry key not found...'
        }
    }

    It 'Checks that file extensions are shown' {
        $splat = @{
            Path        = "$ExplorerRegistryPath\Advanced"
            Name        = 'HideFileExt'
            ErrorAction = 'SilentlyContinue'
        }
        $Val = Get-ItemProperty @splat
        If ($Val) {
            $Val.HideFileExt | Should -BeExactly 0
        } Else {
            Write-Info -Message 'Registry key not found...'
        }
    }
}
