<#
    .SYNOPSIS
        Pester tests for PowerShell profile structure and configuration
    .DESCRIPTION
        Tests the main profile structure, configuration files, and directory layout
        to ensure proper organization and valid file syntax.
#>

BeforeDiscovery {
    $script:ProfileRoot = Split-Path -Path $PROFILE -Parent
    $script:SourcePath = Join-Path -Path $script:ProfileRoot -ChildPath 'Source'
    $script:ConfigPath = Join-Path -Path $script:SourcePath -ChildPath 'Configuration'

    # get configuration files for data-driven tests
    if (Test-Path $script:ConfigPath) {
        $script:ConfigFiles = Get-ChildItem -Path $script:ConfigPath -Filter '*.psd1' -File
    } else {
        $script:ConfigFiles = @()
    }
}

Describe 'Profile Structure' {

    BeforeAll {
        $script:ProfileRoot = Split-Path -Path $PROFILE -Parent
        $script:SourcePath = Join-Path -Path $script:ProfileRoot -ChildPath 'Source'
    }

    Context 'Directory Structure' {

        It 'Profile root directory should exist' {
            Test-Path -Path $script:ProfileRoot -PathType Container | Should -BeTrue
        }

        It 'Source directory should exist' {
            Test-Path -Path $script:SourcePath -PathType Container | Should -BeTrue
        }

        It 'Source/<Directory> should exist' -ForEach @(
            @{ Name = 'Configuration' }
            @{ Name = 'Public' }
            @{ Name = 'Private' }
            @{ Name = 'Modules' }
            @{ Name = 'Completions' }
            @{ Name = 'Scripts' }
        ) {
            $DirPath = Join-Path -Path $script:SourcePath -ChildPath $Name
            Test-Path -Path $DirPath -PathType Container | Should -BeTrue -Because "Source/$Name directory should exist"
        }

    }

    Context 'Profile Files' {

        It 'Profile.ps1 should exist in profile root' {
            $ProfilePath = Join-Path -Path $script:ProfileRoot -ChildPath 'Profile.ps1'
            Test-Path -Path $ProfilePath -PathType Leaf | Should -BeTrue
        }

        It 'Profile.psm1 module should exist in Source' {
            $ModulePath = Join-Path -Path $script:SourcePath -ChildPath 'Profile.psm1'
            Test-Path -Path $ModulePath -PathType Leaf | Should -BeTrue
        }

        It 'Profile.Configuration.psd1 should exist in Source' {
            $ConfigPath = Join-Path -Path $script:SourcePath -ChildPath 'Profile.Configuration.psd1'
            Test-Path -Path $ConfigPath -PathType Leaf | Should -BeTrue
        }

    }

    Context 'Profile Module Syntax' {

        It 'Profile.psm1 should have valid PowerShell syntax' {
            $ModulePath = Join-Path -Path $script:SourcePath -ChildPath 'Profile.psm1'
            $Errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($ModulePath, [ref]$null, [ref]$Errors)
            $Errors.Count | Should -Be 0
        }

        It 'Profile.psm1 should have comment-based help' {
            $ModulePath = Join-Path -Path $script:SourcePath -ChildPath 'Profile.psm1'
            $Content = Get-Content -Path $ModulePath -Raw
            $Content | Should -Match '\.SYNOPSIS'
        }

    }

}

Describe 'Configuration Files' {

    BeforeAll {
        $script:ConfigPath = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath 'Source\Configuration'
        $script:ConfigFilesRuntime = if (Test-Path $script:ConfigPath) {
            Get-ChildItem -Path $script:ConfigPath -Filter '*.psd1' -File
        } else {
            @()
        }
    }

    Context 'Configuration Directory' {

        It 'Configuration directory should exist' {
            Test-Path -Path $script:ConfigPath -PathType Container | Should -BeTrue
        }

        It 'Should have configuration files' {
            $script:ConfigFilesRuntime.Count | Should -BeGreaterThan 0
        }

    }

    Context 'Configuration File Syntax' {

        It 'Config file <_.Name> should have valid PowerShell data syntax' -ForEach $script:ConfigFiles {
            $Errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$Errors)
            $Errors.Count | Should -Be 0 -Because 'Configuration files should be valid PowerShell data files'
        }

        It 'Config file <_.Name> should be importable as data' -ForEach $script:ConfigFiles {
            { Import-PowerShellDataFile -Path $_.FullName -ErrorAction Stop } | Should -Not -Throw
        }

    }

    Context 'Required Configuration Files' {

        It 'Modules.psd1 should exist' {
            $FilePath = Join-Path -Path $script:ConfigPath -ChildPath 'Modules.psd1'
            Test-Path -Path $FilePath -PathType Leaf | Should -BeTrue
        }

        It 'Aliases.psd1 should exist' {
            $FilePath = Join-Path -Path $script:ConfigPath -ChildPath 'Aliases.psd1'
            Test-Path -Path $FilePath -PathType Leaf | Should -BeTrue
        }

        It 'Completions.psd1 should exist' {
            $FilePath = Join-Path -Path $script:ConfigPath -ChildPath 'Completions.psd1'
            Test-Path -Path $FilePath -PathType Leaf | Should -BeTrue
        }

    }

}

Describe 'Profile Configuration Data' {

    BeforeAll {
        $script:SourcePath = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath 'Source'
        $script:ProfileConfigPath = Join-Path -Path $script:SourcePath -ChildPath 'Profile.Configuration.psd1'
    }

    Context 'Profile.Configuration.psd1 Structure' {

        It 'Should be importable' {
            { Import-PowerShellDataFile -Path $script:ProfileConfigPath -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have Settings key' {
            $Config = Import-PowerShellDataFile -Path $script:ProfileConfigPath
            $Config.Keys | Should -Contain 'Settings'
        }

        It 'Should have Components key' {
            $Config = Import-PowerShellDataFile -Path $script:ProfileConfigPath
            $Config.Keys | Should -Contain 'Components'
        }

        It 'Settings should define component order' {
            $Config = Import-PowerShellDataFile -Path $script:ProfileConfigPath
            $Config.Settings.Keys | Should -Contain 'Order'
            $Config.Settings.Order | Should -Not -BeNullOrEmpty
        }

    }

}

