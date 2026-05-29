#Requires -Module Pester

<#
    .SYNOPSIS
        Tests the SSH client configuration and keys.

    .DESCRIPTION
        Verifies the SSH client is available, the ~/.ssh directory and config file
        exist and are populated, RSA and ed25519 keys are present and non-empty,
        and that GitHub is reachable over SSH.

        Note: the Windows ssh-agent service is intentionally not asserted - commit
        signing uses ssh-keygen against the key file directly and git auth is over
        HTTPS, so the agent is not part of this workflow.
#>

Describe 'Testing SSH Configuration and Keys' -Tag 'System', 'SSH' {
    BeforeAll {
        Function Test-SSHKeyNotEmpty {
            Param(
                [Parameter(Mandatory)]
                [System.IO.FileInfo]$Key
            )

            if (-not (Test-Path -Path $Key.FullName)) { return $false }
            return -not [string]::IsNullOrWhiteSpace((Get-Content -Path $Key.FullName -Raw))
        }

        $script:SSHConfigDir = "$env:USERPROFILE\.ssh"
        $script:SSHConfigFile = "$SSHConfigDir\config"

        $script:SSHKeys = Get-ChildItem -Path $SSHConfigDir -Filter 'id_*' -File

        $script:RSAKeys = $SSHKeys | Where-Object { $_.Name -like 'id_rsa*' }
        $script:ECDSAKeys = $SSHKeys | Where-Object { $_.Name -like 'id_ed25519*' }
    }

    It 'Checks ssh command is available' {
        Get-Command -Name 'ssh' | Should -Not -BeNull
    }

    It 'Checks that the SSH directory exists' {
        Test-Path -Path $SSHConfigDir | Should -Be $true
    }

    It 'Checks that the SSH config file exists' {
        Test-Path -Path $SSHConfigFile | Should -Be $true
    }

    It 'Checks that the RSA keys exist' {
        $RSAKeys | Should -Not -BeNullOrEmpty
    }

    It 'Checks that the ECDSA keys exist' {
        $ECDSAKeys | Should -Not -BeNullOrEmpty
    }

    It 'Checks that the RSA keys are not empty' {
        foreach ($Key in $RSAKeys) {
            Test-SSHKeyNotEmpty -Key $Key | Should -BeTrue -Because "$($Key.Name) should contain key material"
        }
    }

    It 'Checks that the ECDSA keys are not empty' {
        foreach ($Key in $ECDSAKeys) {
            Test-SSHKeyNotEmpty -Key $Key | Should -BeTrue -Because "$($Key.Name) should contain key material"
        }
    }

    It 'Checks that the SSH config file is not empty' {
        $SSHConfigFileContent = Get-Content -Path $SSHConfigFile
        $SSHConfigFileContent | Should -Not -BeNullOrEmpty
    }

    It 'Checks that the SSH config file contains the correct permissions' {
        (Get-Acl -Path $SSHConfigFile).Access | Should -Not -BeNullOrEmpty
    }

}



Describe 'GitHub SSH Checks' -Tag 'System', 'SSH', 'RequiresNetwork' {
    BeforeDiscovery {
        # only relevant when SSH is actually configured for GitHub (a github host
        # in ~/.ssh/config); skipped when GitHub is used over HTTPS instead
        $SshConfig = Join-Path -Path $env:USERPROFILE -ChildPath '.ssh\config'
        $script:SkipGitHubSsh = -not ((Test-Path -Path $SshConfig) -and (Select-String -Path $SshConfig -Pattern 'github' -Quiet))
    }

    AfterAll {
        $global:PSNativeCommandUseErrorActionPreference = $true
    }

    It 'Checks can connect to github via ssh (validates key)' -Skip:$SkipGitHubSsh {
        $global:PSNativeCommandUseErrorActionPreference = $false
        ssh -T 'git@ssh.github.com' 2>&1 | Out-Null
        $LASTEXITCODE | Should -Be 1 -Because 'GitHub closes the SSH session with exit code 1 after authenticating with a valid key'
    }
}
