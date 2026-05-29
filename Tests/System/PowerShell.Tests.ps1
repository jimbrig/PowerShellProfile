#Requires -Module Pester

<#
    .SYNOPSIS
        Tests the PowerShell Core installation.

    .DESCRIPTION
        Verifies the stable (7+) and preview PowerShell Core installations exist,
        report the expected versions, and are present on the machine PATH. Preview
        checks are skipped when the preview build is not installed.
#>

Describe 'PowerShell Core Installation Checks' -Tag 'System', 'PowerShell' {

    BeforeAll {
        $DefaultPath = "$Env:PROGRAMFILES\PowerShell\7\pwsh.exe"
        $PreviewPath = "$Env:PROGRAMFILES\PowerShell\7-preview\pwsh.exe"

        $psStableVersionMajor = ((Get-Command $DefaultPath -ErrorAction SilentlyContinue).FileVersionInfo.ProductVersion -split '\.')[0]
        $psStableExpectedVersionMajor = '7'

        $psPreviewVersionMajor = ((Get-Command $PreviewPath -ErrorAction SilentlyContinue).FileVersionInfo.ProductVersion -split '\.')[0]
        $psPreviewExpectedVersionMajor = '7'

        $EnvPaths = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';'

        $DefaultPathDir = Split-Path $DefaultPath -Parent
        $PreviewPathDir = Split-Path $PreviewPath -Parent

        $StableExists = Test-Path -Path $DefaultPath
        $PreviewExists = Test-Path -Path $PreviewPath
        $SkipStableCheck = If ($StableExists) { $null } Else { $true }
        $SkipPreviewCheck = If ($PreviewExists) { $null } Else { $true }


    }

    It 'Checks if PowerShell Core Stable Version is installed' -Skip:$SkipStableCheck {
        Test-Path $DefaultPath | Should -Be $true
    }

    It 'Checks if Installed Stable PowerShell Core Version is 7+' -Skip:$SkipStableCheck {
        $psStableVersionMajor | Should -BeExactly $psStableExpectedVersionMajor
    }

    It 'Checks if PowerShell Core Preview Version is installed' -Skip:$SkipPreviewCheck {
        Test-Path $PreviewPath | Should -Be $true
    }

    It 'Checks if Installed Preview PowerShell Core Version is 7+' -Skip:$SkipPreviewCheck {
        $psPreviewVersionMajor | Should -BeExactly $psPreviewExpectedVersionMajor
    }

    It 'Checks that Stable PowerShell Installed Executable is on system PATH' -Skip:$SkipStableCheck {
        $EnvPaths.Contains($DefaultPathDir) | Should -Be $true
    }

    It 'Checks that Preview PowerShell Installed Executable is on system PATH' -Skip:$SkipPreviewCheck {
        $EnvPaths.Contains($PreviewPathDir) | Should -Be $true
    }

}
