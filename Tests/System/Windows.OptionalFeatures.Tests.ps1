BeforeDiscovery {
    $script:OptionalFeaturesStatus = @(
        @{FeatureName = 'Microsoft-Hyper-V-All'; Enabled = $true; MissingOK = $false },
        @{FeatureName = 'Microsoft-Windows-Subsystem-Linux'; Enabled = $true; MissingOK = $false },
        @{FeatureName = 'Microsoft-Windows-Subsystem-Linux-All'; Enabled = $true; MissingOK = $false },
        @{FeatureName = 'Microsoft-Windows-Subsystem-Linux-WslOptionalFeature'; Enabled = $true; MissingOK = $false },
        @{FeatureName = 'SearchEngine-Client-Package'; Enabled = $true; MissingOK = $false },
        @{FeatureName = 'HypervisorPlatform'; Enabled = $true; MissingOK = $false }
    )
}

BeforeAll {
    if (-not $IsWindows) {
        Write-Warning "These tests are only applicable to Windows systems."
        return
    }

    function Start-ElevatedSession {
        if ($IsWindows) {
            Start-Process powershell -Verb RunAs -ArgumentList "-Command $PSCommandPath" -Wait
        } elseif ($IsLinux -or $IsMacOS) {
            sudo pwsh -Command $PSCommandPath
        }
    }

    $script:IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
    $script:SkipTests = -not $IsAdmin

    if (-not $IsAdmin) {
        Write-Warning "Tests require elevation. Run as administrator to execute tests."
    } else {
        $script:OptionalFeatures = Get-WindowsOptionalFeature -Online
    }

    $script:OptionalFeaturesToEnable = @(
        'HypervisorPlatform',
        'VirtualMachinePlatform',
        'Microsoft-Hyper-V-All',
        'Microsoft-Windows-Subsystem-Linux',
        'Containers',
        'SmbDirect'
        # Add other features as needed
    )
}

Describe "Verify Windows Optional Features Status" -Skip:(-not $IsWindows) {
    It "Verifies Windows Feature '<FeatureName>' Should be '<Enabled>'" -TestCases $OptionalFeaturesStatus -Skip:$SkipTests {
        Param(
            [string]$FeatureName,
            [bool]$MissingOK,
            [bool]$Enabled
        )

        # Check for administrative privileges
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "The requested operation requires elevation. Please run this script as an administrator."
        }

        $OptionalFeatures = Get-WindowsOptionalFeature -Online
        $Feature = $OptionalFeatures | Where-Object { $_.FeatureName -eq $FeatureName }

        if ($null -eq $Feature) {
            if (-not $MissingOK) {
                throw "Optional Feature '$FeatureName' is missing but should be present"
            }
            Set-ItResult -Skipped -Because "Optional Feature '$FeatureName' is missing (as expected)"
            return
        }

        $isEnabled = $Feature.State -eq 'Enabled'
        $isEnabled | Should -Be $Enabled -Because "Feature '$FeatureName' state should match expected state"
    }
}
