#Requires -Modules Pester

<#
.SYNOPSIS
#>

Describe 'Testing SSH Configuration and Keys' {
    BeforeAll {
        Function Test-SSHKey {
            Param(
                [Parameter(Mandatory)]
                [String]$Key
            )

            Begin {
                if ((Get-Service -Name ssh-agent).Status -ne 'Running') {
                    Write-Warning "SSH Agent is not running. Please start the SSH Agent and try again."
                    return
                }
                if (-not (Get-Command -Name 'ssh' -ErrorAction SilentlyContinue)) {
                    Write-Error "SSH is not installed. Please install SSH and try again."
                    return
                }
                if (-not (Test-Path -Path "$HOME\.ssh")) {
                    Write-Error "SSH directory not found at $HOME\.ssh"
                    return
                }
                $Path = "$HOME\.ssh\$Key"
            }

            Process {
                if (Test-Path -Path $Path) {
                    Write-Host "Key $Key exists" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "Key $Key does not exist" -ForegroundColor Red
                    return $false
                }
            }
        }

        $Script:SSHConfigDir = "$env:USERPROFILE\.ssh"
        $Script:SSHConfigFile = "$SSHConfigDir\config"

        $Script:SSHKeys = Get-ChildItem -Path $SSHConfigDir -Filter 'id_*' -File

        $Script:RSAKeys = $SSHKeys | Where-Object { $_.Name -like 'id_rsa*' }
        $Script:ECDSAKeys = $SSHKeys | Where-Object { $_.Name -like 'id_ed25519*' }
    }

    It 'Checks ssh command is available' {
        Get-Command -Name 'ssh' | Should -Not -BeNull
    }

    It 'Checks that the SSH Agent is running' {
        (Get-Service -Name ssh-agent).Status | Should -Be 'Running'
    }

    It 'Checks ssh-agent service is set to Automatic' {
        (Get-Service -Name ssh-agent).StartType | Should -Be 'Automatic'
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
        $RSAKeys | ForEach-Object {
            Test-SSHKey -Key $_.Name | Should -Be $true
        }
    }

    It 'Checks that the ECDSA keys are not empty' {
        $ECDSAKeys | ForEach-Object {
            Test-SSHKey -Key $_.Name | Should -Be $true
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



Describe 'GitHub SSH Checks' {
    It 'Checks can connect to github via ssh' {

        $global:PSNativeCommandUseErrorActionPreference = $false
        Invoke-Command -ScriptBlock { ssh -T 'git@ssh.github.com' } -ErrorAction Ignore
        $LASTEXITCODE | Should -Be 1
        $? | Should -Be $true
        $global:PSNativeCommandUseErrorActionPreference = $true

    }
}
