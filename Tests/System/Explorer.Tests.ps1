#Requires -Module Pester

<#
    .SYNOPSIS
        Tests Windows File Explorer configuration.

    .DESCRIPTION
        Verifies the user's preferred File Explorer settings are applied:

        - Explorer opens to "Home" by default (LaunchTo = 2)
        - Hidden files are shown (Hidden = 1)
        - Known file extensions are shown (HideFileExt = 0)

        A missing or different value fails the test, which surfaces settings that a
        Windows update or profile reset may have reverted.
#>

Describe 'Windows File Explorer Configuration and Setup' -Tag 'System', 'Explorer' {
    BeforeAll {
        $script:ExplorerRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
        $script:AdvancedRegistryPath = "$ExplorerRegistryPath\Advanced"
    }

    It 'Checks that File Explorer registry path exists' {
        Test-Path -Path $ExplorerRegistryPath | Should -BeTrue
    }

    It 'Checks that File Explorer is set to open to "Home" by default' {
        $Val = Get-ItemProperty -Path $AdvancedRegistryPath -Name 'LaunchTo' -ErrorAction SilentlyContinue
        $Val.LaunchTo | Should -Be 2 -Because 'LaunchTo = 2 opens Explorer to Home'
    }

    It 'Checks that hidden files are shown' {
        $Val = Get-ItemProperty -Path $AdvancedRegistryPath -Name 'Hidden' -ErrorAction SilentlyContinue
        $Val.Hidden | Should -Be 1 -Because 'Hidden = 1 shows hidden files'
    }

    It 'Checks that file extensions are shown' {
        $Val = Get-ItemProperty -Path $AdvancedRegistryPath -Name 'HideFileExt' -ErrorAction SilentlyContinue
        $Val.HideFileExt | Should -Be 0 -Because 'HideFileExt = 0 shows known file extensions'
    }
}
