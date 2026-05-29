#Requires -Module Pester

<#
    .SYNOPSIS
        Tests the state of Windows optional features.

    .DESCRIPTION
        Verifies that the Windows optional features required for the development
        environment (Hyper-V, WSL, the hypervisor platform, and search indexing)
        are in their expected enabled/disabled state.

        Reading optional feature state requires elevation, so these tests are
        skipped when the session is not running as administrator.
#>

BeforeDiscovery {
    $script:OptionalFeaturesStatus = @(
        @{ FeatureName = 'Microsoft-Hyper-V-All'; Enabled = $true; MissingOK = $false }
        @{ FeatureName = 'Microsoft-Windows-Subsystem-Linux'; Enabled = $true; MissingOK = $false }
        @{ FeatureName = 'Microsoft-Windows-Subsystem-Linux-All'; Enabled = $true; MissingOK = $false }
        @{ FeatureName = 'Microsoft-Windows-Subsystem-Linux-WslOptionalFeature'; Enabled = $true; MissingOK = $false }
        @{ FeatureName = 'SearchEngine-Client-Package'; Enabled = $true; MissingOK = $false }
        @{ FeatureName = 'HypervisorPlatform'; Enabled = $true; MissingOK = $false }
    )

    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
    $script:SkipFeatureChecks = -not ($IsWindows -and $IsAdmin)
}

Describe 'Verify Windows Optional Features Status' -Tag 'System', 'OptionalFeatures', 'RequiresAdmin' {
    BeforeAll {
        $script:OptionalFeatures = Get-WindowsOptionalFeature -Online
    }

    It "Verifies Windows Feature '<FeatureName>' is '<Enabled>'" -TestCases $OptionalFeaturesStatus -Skip:$SkipFeatureChecks {
        Param(
            [string]$FeatureName,
            [bool]$MissingOK,
            [bool]$Enabled
        )

        $Feature = $script:OptionalFeatures | Where-Object { $_.FeatureName -eq $FeatureName }

        if ($null -eq $Feature) {
            if (-not $MissingOK) {
                throw "Optional Feature '$FeatureName' is missing but should be present"
            }
            Set-ItResult -Skipped -Because "Optional Feature '$FeatureName' is missing (as expected)"
            return
        }

        ($Feature.State -eq 'Enabled') | Should -Be $Enabled -Because "Feature '$FeatureName' state should match expected state"
    }
}
