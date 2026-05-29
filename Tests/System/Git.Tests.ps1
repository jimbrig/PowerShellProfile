#Requires -Module Pester

<#
    .SYNOPSIS
        Tests the global git configuration values.

    .DESCRIPTION
        Verifies the global git configuration is set to the expected values:

        - user.email is set and well-formed
        - init.defaultBranch is "main"
        - gpg.program is set and resolvable on PATH
        - user.signingkey is set
        - commit.gpgSign is true
        - tag.forceSignAnnotated is true
#>

Describe 'Testing Git Configuration Values' -Tag 'System', 'Git' {
    BeforeAll {
        Function Get-GitConfigPath {
            $path = "$HOME\.gitconfig"
            if ($ENV:XDG_CONFIG_HOME) {
                if (Test-Path -Path $ENV:XDG_CONFIG_HOME\git\config) {
                    $path = "$ENV:XDG_CONFIG_HOME\git\config"
                }
            }
            return $path
        }

        Function Get-GitConfigValue($Key) {
            # read the effective config (not --global): user keys live in the XDG
            # file ~/.config/git/config, which `git config --global` does not read
            # when ~/.gitconfig also exists
            git config --get $Key
        }

        Function Test-Email($Email) {
            if ($Email -match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') {
                return $true
            } else {
                return $false
            }
        }
    }

    It 'Checks a global git configuration file exists' {
        $GitConfigPath = Get-GitConfigPath
        Test-Path -Path $GitConfigPath | Should -Be $true
        $GitConfigContent = Get-Content -Path $GitConfigPath
        $GitConfigContent | Should -Not -BeNullOrEmpty
    }

    It 'Checks that user.email is set and valid' {
        $Test_Email = Get-GitConfigValue -Key 'user.email'
        $Test_Email | Should -Not -BeNullOrEmpty
        Test-Email -Email $Test_Email | Should -Be $true
    }

    It 'Checks that init.defaultBranch is set and is "main"' {
        $Test_DefaultMain = Get-GitConfigValue -Key 'init.defaultBranch'
        $Test_DefaultMain | Should -Be 'main'
    }

    It 'Checks that gpg.program is set and is a valid executable' {
        $Test_GPGProgram = Get-GitConfigValue -Key 'gpg.program'
        $Test_GPGProgram | Should -Not -BeNullOrEmpty
        Get-Command $Test_GPGProgram -ErrorAction SilentlyContinue | Should -Not -BeNull
    }

    It 'Checks that user.signingkey is set' {
        $Test_SigningKey = Get-GitConfigValue -Key 'user.signingkey'
        $Test_SigningKey | Should -Not -BeNullOrEmpty
    }

    It 'Checks that commit.gpgSign is set' {
        $Test_CommitSigning = Get-GitConfigValue -Key 'commit.gpgSign'
        $Test_CommitSigning | Should -Be 'true'
    }

    It 'Checks that tag.forceSignAnnotated is set' {
        $Test_TagSigning = Get-GitConfigValue -Key 'tag.forceSignAnnotated'
        $Test_TagSigning | Should -Be 'true'
    }

}
