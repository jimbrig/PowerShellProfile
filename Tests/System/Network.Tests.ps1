#Requires -Module Pester

<#
    .SYNOPSIS
        Tests network connectivity, TLS/crypto configuration, and TCP tuning.

    .DESCRIPTION
        Verifies that the system's networking stack is configured as expected:

        - Basic internet connectivity
        - TLS 1.2/1.3 are available and weak protocols (TLS 1.0/1.1, SSL 3.0) are not
        - ServicePointManager EncryptionPolicy and DefaultConnectionLimit
        - .NET Framework v4+ Strong Cryptography registry keys (64-bit and 32-bit)
        - TCP autotuning and scaling heuristics
        - Intel Killer networking services are stopped and set to Manual startup,
          and IPv6 connectivity to a Killer-affected CloudFront service succeeds
#>

Describe 'PowerShell Networking Tests' -Tag 'System', 'Network' {

    BeforeAll {
        $script:NetSecurityProtocols = [enum]::GetNames([Net.SecurityProtocolType])
        $script:AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
    }

    AfterAll {
        $global:PSNativeCommandUseErrorActionPreference = $true
    }

    It 'Checks internet connection from a powershell shell' -Tag 'RequiresNetwork' {
        Test-Connection -ComputerName 'www.google.com' -Count 1 -Quiet | Should -BeTrue
    }

    It 'Checks that TLS 1.2 is on system' {
        $NetSecurityProtocols | Should -Contain 'Tls12'
    }

    It 'Checks that TLS 1.2 is available' {
        $AvailableTls | Should -Contain 'Tls12'
    }

    It 'Checks that TLS 1.3 is available' {
        $AvailableTls | Should -Contain 'Tls13'
    }

    It 'Checks that TLS 1.1 is not available' {
        $AvailableTls | Should -Not -Contain 'Tls11'
    }

    It 'Checks that TLS 1.0 is not available' {
        $AvailableTls | Should -Not -Contain 'Tls'
    }

    It 'Checks that SSL 3.0 is not available' {
        $AvailableTls | Should -Not -Contain 'Ssl3'
    }

    It 'Checks that a secure default TLS protocol is configured' {
        $Protocol = [Net.ServicePointManager]::SecurityProtocol
        $IsSecure = ($Protocol -eq 'SystemDefault') -or
                    (($Protocol -band [Net.SecurityProtocolType]::Tls12) -and ($Protocol -band [Net.SecurityProtocolType]::Tls13))
        $IsSecure | Should -BeTrue -Because 'TLS should be SystemDefault or explicitly TLS 1.2 + 1.3 (as the profile configures)'
    }

    It 'Checks EncryptionPolicy' {
        [Net.ServicePointManager]::EncryptionPolicy | Should -Be 'RequireEncryption'
    }

    It 'Checks DefaultConnectionLimit' {
        [Net.ServicePointManager]::DefaultConnectionLimit | Should -BeGreaterOrEqual 2
    }

    It 'Checks .NET Framework v4+ Strong Cryptography registry key (64-bit)' {
        $Val = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -ErrorAction SilentlyContinue
        $Val.SchUseStrongCrypto | Should -Be 1 -Because 'SchUseStrongCrypto enables strong crypto for .NET 4+ (64-bit)'
    }

    It 'Checks .NET Framework v4+ Strong Cryptography registry key (32-bit)' {
        $Val = Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -ErrorAction SilentlyContinue
        $Val.SchUseStrongCrypto | Should -Be 1 -Because 'SchUseStrongCrypto enables strong crypto for .NET 4+ (32-bit)'
    }

    # to fix: netsh int tcp set global autotuninglevel=normal
    It 'Checks the Window AutoTuning Levels are set to Normal' {
        $Settings = Get-NetTCPSetting | Where-Object { $_.SettingName -ne 'Automatic' }
        foreach ($Setting in $Settings) {
            $Setting.AutoTuningLevelEffective | Should -Be 'Local' -Because "the '$($Setting.SettingName)' profile autotuning should be Local"
            $Setting.AutoTuningLevelLocal | Should -Be 'Normal' -Because "the '$($Setting.SettingName)' profile autotuning should be Normal"
        }
    }

    # to fix: netsh interface tcp set heuristics disabled
    It 'Checks that Scaling Heuristics are Disabled' {
        $Settings = Get-NetTCPSetting | Where-Object { $_.SettingName -ne 'Automatic' }
        foreach ($Setting in $Settings) {
            $Setting.ScalingHeuristics | Should -Be 'Disabled' -Because "the '$($Setting.SettingName)' profile should not use scaling heuristics"
        }
    }

    <#
    Intel Killer Networking Tests:
    Killer services break IPv6 connectivity to some CloudFront-backed services
    (e.g. https://cdn.posit.co/posit-ai/manifest.json), so they must be stopped
    and set to a Manual startup type. A Windows update can silently re-enable
    them, which is why this is verified here.

    Diagnose:
    # an IPv6 connection reset (exit code 35) indicates Killer is interfering
    curl.exe -6 -I "https://cdn.posit.co/posit-ai/manifest.json"
    curl: (35) Recv failure: Connection was reset

    Remediate (requires an elevated shell):
    $KillerServices = 'KAPSService', 'Killer Analytics Service', 'Killer Network Service', 'Killer Provider Data Helper Service', 'KNDBWM'
    Get-Service -Name $KillerServices -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
    Get-Service -Name $KillerServices -ErrorAction SilentlyContinue | Set-Service -StartupType Manual
    #>
    Context 'Intel Killer Networking Services' {

        $KillerServiceNames = @(
            'KAPSService'
            'Killer Analytics Service'
            'Killer Network Service'
            'Killer Provider Data Helper Service'
            'KNDBWM'
        )

        It "Stops the '<_>' service and sets it to a Manual startup type" -ForEach $KillerServiceNames {
            $Service = Get-Service -Name $_ -ErrorAction SilentlyContinue

            $Service | Should -Not -BeNullOrEmpty -Because "the '$_' Killer service is expected on this Intel Killer system"
            $Service.Status | Should -Be 'Stopped' -Because 'running Killer services break IPv6 connectivity to some CloudFront services'
            $Service.StartType | Should -Be 'Manual' -Because 'Killer services must not start automatically on boot'
        }

        It 'Connects to a Killer-affected CloudFront service over IPv6' -Tag 'RequiresNetwork' {
            $PSNativeCommandUseErrorActionPreference = $false
            $null = curl.exe -6 -sS --max-time 15 -I 'https://cdn.posit.co/posit-ai/manifest.json' 2>&1
            $LASTEXITCODE | Should -Be 0 -Because 'a non-zero exit (e.g. 35 - connection reset) indicates Killer is interfering with IPv6'
        }
    }
}
