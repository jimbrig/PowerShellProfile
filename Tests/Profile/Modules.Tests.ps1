<#
    .SYNOPSIS
        Pester tests for PowerShell profile custom modules
    .DESCRIPTION
        Tests the custom modules in Source/Modules for proper structure,
        manifest validity, and syntax correctness.
#>

BeforeDiscovery {
    $script:ModulesPath = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath 'Source\Modules'
    if (Test-Path $script:ModulesPath) {
        $script:CustomModules = Get-ChildItem -Path $script:ModulesPath -Directory
    } else {
        $script:CustomModules = @()
    }

    # collect all .ps1 files from custom modules
    $script:ModuleScripts = @()
    if (Test-Path $script:ModulesPath) {
        $script:ModuleScripts = Get-ChildItem -Path $script:ModulesPath -Filter '*.ps1' -Recurse -File
    }
}

Describe 'Custom Modules' {

    BeforeAll {
        $script:ModulesPath = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath 'Source\Modules'
        $script:CustomModulesRuntime = if (Test-Path $script:ModulesPath) {
            Get-ChildItem -Path $script:ModulesPath -Directory
        } else {
            @()
        }
    }

    Context 'Modules Discovery' {

        It 'Modules directory should exist' {
            Test-Path -Path $script:ModulesPath -PathType Container | Should -BeTrue
        }

        It 'Should have custom module directories' {
            $script:CustomModulesRuntime.Count | Should -BeGreaterThan 0
        }

    }

    Context 'Module Structure' {

        It 'Module <_.Name> should have a root module file (.psm1)' -ForEach $script:CustomModules {
            $ModuleName = $_.Name
            $RootModulePath = Join-Path -Path $_.FullName -ChildPath "$ModuleName.psm1"
            Test-Path -Path $RootModulePath -PathType Leaf | Should -BeTrue -Because "Module should have $ModuleName.psm1"
        }

    }

    Context 'Root Module Syntax' {

        It 'Module <_.Name> root module should have valid PowerShell syntax' -ForEach $script:CustomModules {
            $ModuleName = $_.Name
            $RootModulePath = Join-Path -Path $_.FullName -ChildPath "$ModuleName.psm1"

            if (Test-Path -Path $RootModulePath -PathType Leaf) {
                $Errors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseFile($RootModulePath, [ref]$null, [ref]$Errors)
                $Errors.Count | Should -Be 0 -Because 'Root module should parse without syntax errors'
            }
        }

    }

}

Describe 'Module Manifests' {

    BeforeAll {
        $script:ModulesPath = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath 'Source\Modules'
        $script:ModulesWithManifest = @()

        if (Test-Path $script:ModulesPath) {
            $AllModules = Get-ChildItem -Path $script:ModulesPath -Directory
            foreach ($Module in $AllModules) {
                $ManifestPath = Join-Path -Path $Module.FullName -ChildPath "$($Module.Name).psd1"
                if (Test-Path -Path $ManifestPath -PathType Leaf) {
                    $script:ModulesWithManifest += $Module
                }
            }
        }
    }

    Context 'Manifest Validation' {

        It 'Modules with manifests should have valid syntax' {
            foreach ($Module in $script:ModulesWithManifest) {
                $ManifestPath = Join-Path -Path $Module.FullName -ChildPath "$($Module.Name).psd1"
                $Errors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseFile($ManifestPath, [ref]$null, [ref]$Errors)
                $Errors.Count | Should -Be 0 -Because "$($Module.Name) manifest should parse without errors"
            }
        }

        It 'Modules with manifests should be importable as data' {
            foreach ($Module in $script:ModulesWithManifest) {
                $ManifestPath = Join-Path -Path $Module.FullName -ChildPath "$($Module.Name).psd1"
                { Import-PowerShellDataFile -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
            }
        }

    }

}

Describe 'Module Script Files' {

    Context 'Script Syntax Validation' {

        It 'Module script <_.Name> should have valid PowerShell syntax' -ForEach $script:ModuleScripts {
            $Errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$Errors)
            $Errors.Count | Should -Be 0 -Because 'Module scripts should parse without syntax errors'
        }

    }

}

Describe 'Specific Module Tests' {

    BeforeAll {
        $script:ModulesPath = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath 'Source\Modules'
    }

    Context 'PSCleanupManager' {

        BeforeAll {
            $script:ModulePath = Join-Path -Path $script:ModulesPath -ChildPath 'PSCleanupManager'
            $script:ModuleExists = Test-Path -Path $script:ModulePath -PathType Container
        }

        It 'PSCleanupManager module directory should exist' {
            $script:ModuleExists | Should -BeTrue
        }

        It 'Should have PSCleanupManager.psm1' {
            if ($script:ModuleExists) {
                $RootModulePath = Join-Path -Path $script:ModulePath -ChildPath 'PSCleanupManager.psm1'
                Test-Path -Path $RootModulePath -PathType Leaf | Should -BeTrue
            }
        }

        It 'Should have Public directory' {
            if ($script:ModuleExists) {
                $PublicPath = Join-Path -Path $script:ModulePath -ChildPath 'Public'
                Test-Path -Path $PublicPath -PathType Container | Should -BeTrue
            }
        }

        It 'Should have Private directory' {
            if ($script:ModuleExists) {
                $PrivatePath = Join-Path -Path $script:ModulePath -ChildPath 'Private'
                Test-Path -Path $PrivatePath -PathType Container | Should -BeTrue
            }
        }

    }

    Context 'PSDriverManager' {

        BeforeAll {
            $script:ModulePath = Join-Path -Path $script:ModulesPath -ChildPath 'PSDriverManager'
            $script:ModuleExists = Test-Path -Path $script:ModulePath -PathType Container
        }

        It 'PSDriverManager module directory should exist' {
            $script:ModuleExists | Should -BeTrue
        }

        It 'Should have PSDriverManager.psm1' {
            if ($script:ModuleExists) {
                $RootModulePath = Join-Path -Path $script:ModulePath -ChildPath 'PSDriverManager.psm1'
                Test-Path -Path $RootModulePath -PathType Leaf | Should -BeTrue
            }
        }

    }

}
