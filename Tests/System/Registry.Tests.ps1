#Requires -Module Pester

<#
.SYNOPSIS
    Tests for verifying the configuration of various Windows registry settings.

.DESCRIPTION
    This script contains tests to verify the configuration of various Windows registry settings that are commonly used
    to configure system behavior and preferences.
#>

Describe 'Windows Registry Configuration' {
    BeforeAll {
        $Script:HKLM_WindowsUpdateRegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
        $Script:HKLM_StartupRegistryPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'
        $Script:HKCU_StartupRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        $Script:HKLM_EnvironmentRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
        $Script:HKCU_EnvironmentRegistryPath = 'HKCU:\Environment'
    }

    It 'Checks that Windows Update registry path exists' {
        Test-Path -Path $HKLM_WindowsUpdateRegistryPath | Should -Be $true
    }

    It 'Checks that automatic updates are enabled' {
        $splat = @{
            Path        = "$HKLM_WindowsUpdateRegistryPath\AU"
            Name        = 'AUOptions'
            ErrorAction = 'SilentlyContinue'
        }
        $Val = Get-ItemProperty @splat
        If ($Val) {
            $Val.AUOptions | Should -BeExactly 3
        } Else {
            Write-Info -Message 'Registry key not found...'
        }

        $splat = @{
            Path        = "$HKLM_WindowsUpdateRegistryPath\AU"
            Name        = 'NoAutoUpdate'
            ErrorAction = 'SilentlyContinue'
        }

        $Val = Get-ItemProperty @splat

        If ($Val) {
            $Val.NoAutoUpdate | Should -Be 0
        } Else {
            Write-Info -Message 'Registry key not found...'
        }
    }
}

Describe "Registry Tweaks" {

    BeforeAll {
        $Script:RegistryEdits = @{
            'ShowSecondsInTaskbar' = @{
                'Path'  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                'Name'  = 'ShowSecondsInSystemClock'
                'Type'  = 'DWORD'
                'Value' = 1
            }
            'DisableShortcutText' = @{
                'Path'  = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
                'Name'  = 'link'
                'Type'  = 'DWORD'
                'Value' = 1
            }
        }
    }

    It "ShowsSecondsInTaskbar" {
        $splat = @{
            Path        = $RegistryEdits.ShowSecondsInTaskbar.Path
            Name        = $RegistryEdits.ShowSecondsInTaskbar.Name
            ErrorAction = 'SilentlyContinue'
        }
        $Val = Get-ItemProperty @splat

        If ($Val) {
            $Val.ShowSecondsInSystemClock | Should -Be 1
        } Else {
            Write-Info -Message 'Registry key not found...'
        }
    }
}
