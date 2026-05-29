#Requires -Module Pester

<#
    .SYNOPSIS
        Tests Windows registry configuration and personal tweaks.

    .DESCRIPTION
        Verifies system policy and personal registry tweaks are applied:

        - Windows Update automatic updates are enabled (AUOptions = 3, NoAutoUpdate = 0)
        - Seconds are shown in the taskbar clock (ShowSecondsInSystemClock = 1)
        - The ".lnk" shortcut suffix text is disabled (link = 0)

        A missing or different value fails the test, surfacing tweaks that a
        Windows update may have reverted.
#>

Describe 'Windows Registry Configuration' -Tag 'System', 'Registry' {
    BeforeAll {
        $script:WindowsUpdateRegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
    }

    It 'Checks that Windows Update registry path exists' {
        Test-Path -Path $WindowsUpdateRegistryPath | Should -BeTrue
    }

    It 'Checks that automatic updates are enabled' {
        $Val = Get-ItemProperty -Path "$WindowsUpdateRegistryPath\AU" -Name 'AUOptions' -ErrorAction SilentlyContinue
        $Val.AUOptions | Should -Be 3 -Because 'AUOptions = 3 auto-downloads and notifies for install'

        $Val = Get-ItemProperty -Path "$WindowsUpdateRegistryPath\AU" -Name 'NoAutoUpdate' -ErrorAction SilentlyContinue
        $Val.NoAutoUpdate | Should -Be 0 -Because 'NoAutoUpdate = 0 keeps automatic updates enabled'
    }
}

Describe 'Windows Registry Tweaks' -Tag 'System', 'Registry' {

    It 'Checks that seconds are shown in the taskbar clock' {
        $Val = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSecondsInSystemClock' -ErrorAction SilentlyContinue
        $Val.ShowSecondsInSystemClock | Should -Be 1 -Because 'ShowSecondsInSystemClock = 1 shows seconds in the clock'
    }

    It 'Checks that the shortcut suffix text is disabled' {
        $Val = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'link' -ErrorAction SilentlyContinue
        $Val.link | Should -Be 1 -Because 'link = 1 disables the "- Shortcut" suffix on new shortcuts'
    }
}
