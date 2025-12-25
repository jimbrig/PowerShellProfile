#Requires -Module Pester

<#
    .SYNOPSIS
        This script is used to test network connectivity and security protocols.

    .DESCRIPTION
        This script tests various network connectivity and security protocols to ensure that they are
        configured correctly. The following tests are performed:

        - Internet Connection Test
        - TLS 1.2 is on the system, available, and the default protocol used by the system
        - EncryptionPolicy is set to RequireEncryption
        - DefaultConnectionLimit is set to a value greater than 2
        - Registry keys for .NET Framework Version 4+ for Strong Cryptography are set

    .NOTES


#>

Describe 'PowerShell Networking Tests' {

    BeforeAll {
        $script:NetSecurityProtocols = [enum]::GetNames([Net.SecurityProtocolType])
        $script:AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }

        $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
        if ($IsAdmin) { $script:SkipDefenderChecks = $null } else { $script:SkipDefenderChecks = $true }
    }

    AfterAll {
        $global:PSNativeCommandUseErrorActionPreference = $true
    }

    It 'Checks internet connection from a powershell shell' {
        $TestConnection = Test-Connection -ComputerName 'www.google.com' -Count 1 -Quiet
        $TestConnection | Should -Be $true
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

    It 'Checks that TLS 1.2 is default' {
        [Net.ServicePointManager]::SecurityProtocol | Should -Be 'SystemDefault'
    }

    It 'Checks EncryptionPolicy' {
        [Net.ServicePointManager]::EncryptionPolicy | Should -Be 'RequireEncryption'
    }

    It 'Checks DefaultConnectionLimit' {
        [Net.ServicePointManager]::DefaultConnectionLimit | Should -BeGreaterOrEqual 2
    }

    It 'Checks for Registry Keys for .NET Framework Version 4+ for Strong Cryptography (64bit)' {
        $splat = @{
            Path        = 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319'
            Name        = 'SchUseStrongCrypto'
            ErrorAction = 'SilentlyContinue'
        }

        $Val = Get-ItemProperty @splat
        If ($Val) {
            $Val.SchUseStrongCrypto | Should -BeExactly 1
        } Else {
            Write-Info -Message 'Registry key not found...'
        }
    }

    It 'Checks for Registry Keys for .NET Framework Version 4+ for Strong Cryptography (32bit)' {
        $splat = @{
            Path        = 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319'
            Name        = 'SchUseStrongCrypto'
            ErrorAction = 'SilentlyContinue'
        }

        $Val = Get-ItemProperty @splat
        If ($Val) {
            $Val.SchUseStrongCrypto | Should -BeExactly 1
        } Else {
            Write-Info -Message 'Registry key not found...'
        }
    }

    It 'Checks the Window AutoTuning Levels are set to Normal' {

        $Settings = Get-NetTCPSetting

        # loop through each settings group object and ensure that:
        # - 'AutoTuningLevelEffective' is set to 'Local'
        # - 'AutoTuningLevelLocal' is set to 'Normal'

        $Settings | ForEach-Object {
            if ($_.SettingName -eq 'Automatic') { return }
            $_.AutoTuningLevelEffective | Should -Be 'Local'
            $_.AutoTuningLevelLocal | Should -Be 'Normal'
        }

        # to fix: netsh int tcp set global autotuninglevel=normal
    }

    # Microsoft is not limiting internet connection
    # netsh interface tcp show heuristics
    # netsh interface tcp set heuristics disabled
    It 'Checks that ScalingHeristics are Disabled' {
        $Settings = Get-NetTCPSetting
        $Settings | ForEach-Object {
            if ($_.SettingName -eq 'Automatic') { return }
            $_.ScalingHeuristics | Should -Be 'Disabled'
        }
    }

    It 'Checks that ECN Capability is Disabled' {
        $Settings = Get-NetTCPSetting
        $Settings | ForEach-Object {
            if ($_.SettingName -eq 'Automatic') { return }
            $_.ECNCapability | Should -Be 'Disabled'
        }
    }

    # netsh advfirewall firewall add rule name="StopThrottling" dir=in action=block remoteip=173.194.55.0/24,206.111.0.0/16 enable=yes
    # requires admin
    # It 'Checks that Firewall Rule is in effect for ISP Throttling' {
    #     $FirewallRule = Get-NetFirewallRule -DisplayName 'ISP Throttling'
    #     $FirewallRule | Should -Not -BeNullOrEmpty
    # }

}


# [System.Net.ServicePointManager]::SecurityProtocol += [System.Net.SecurityProtocolType]::Tls12

# if ('SslProtocol' -notin (Get-Command Invoke-RestMethod).Parameters.Keys) {
#     $currentMaxTls = [Math]::Max([Net.ServicePointManager]::SecurityProtocol.value__, [Net.SecurityProtocolType]::Tls.value__)
#     $newTlsTypes = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -gt $currentMaxTls }
#     $newTlsTypes | ForEach-Object {
#         [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $_
#     }
# }

# ping -t 1 $DefaultGatewayIPAddress

# Test-Connection -ComputerName $DefaultGatewayIPAddress -Count 1 -Quiet

# Test-Connection -ComputerName 'www.google.com' -Count 1 -Quiet

# [Net.ServicePointManager]::SecurityProtocol

# [Net.ServicePointManager]::EncryptionPolicy

# [Net.ServicePointManager]::DefaultConnectionLimit

# Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto'

# ipconfig /release ipconfig /renew

# ipconfig /flushdns

# netsh interface ip show config

# netsh commands cmd

# Get-NetIPConfiguration

# $DefaultGateway = Get-NetIPConfiguration |
#     Where-Object { $_.IPv4DefaultGateway -ne $null }

# $DefaultGatewayIPAddress = $DefaultGateway | ForEach-Object { $_.IPv4DefaultGateway.NextHop } | Select-Object -First 1
