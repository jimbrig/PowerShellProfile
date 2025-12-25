<#
    .SYNOPSIS
        Pester tests for PowerShell profile public functions
    .DESCRIPTION
        Tests the public functions in Source/Public for syntax validity,
        documentation standards, and basic functionality.
#>

BeforeDiscovery {
    $script:PublicPath = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath 'Source\Public'
    if (Test-Path $script:PublicPath) {
        $script:PublicFunctions = Get-ChildItem -Path $script:PublicPath -Filter '*.ps1' -File
    } else {
        $script:PublicFunctions = @()
    }
}

Describe 'Public Functions' {

    BeforeAll {
        $script:PublicPath = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath 'Source\Public'
        $script:PublicFunctionsRuntime = if (Test-Path $script:PublicPath) {
            Get-ChildItem -Path $script:PublicPath -Filter '*.ps1' -File
        } else {
            @()
        }
    }

    Context 'Function Discovery' {

        It 'Public functions directory should exist' {
            Test-Path -Path $script:PublicPath -PathType Container | Should -BeTrue
        }

        It 'Should have public function scripts' {
            $script:PublicFunctionsRuntime.Count | Should -BeGreaterThan 0
        }

    }

    Context 'Script Syntax Validation' {

        It 'Function script <_.Name> should have valid PowerShell syntax' -ForEach $script:PublicFunctions {
            $Errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$Errors)
            $Errors.Count | Should -Be 0 -Because 'Function scripts should parse without syntax errors'
        }

    }

    Context 'Documentation Standards' {

        It 'Function script <_.Name> should have comment-based help' -ForEach $script:PublicFunctions {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match '<#' -Because 'Script should have comment-based help'
            $Content | Should -Match '\.SYNOPSIS' -Because 'Script should document its purpose'
        }

        It 'Function script <_.Name> should define a function' -ForEach $script:PublicFunctions {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match 'Function\s+\w+' -Because 'Script should define a function'
        }

    }

    Context 'Naming Conventions' {

        It 'Function script <_.Name> should follow Verb-Noun naming pattern' -ForEach $script:PublicFunctions {
            $FunctionName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            $FunctionName | Should -Match '^\w+-\w+$' -Because 'Function should use Verb-Noun naming convention'
        }

        It 'Function script <_.Name> should use approved verb' -ForEach $script:PublicFunctions {
            $FunctionName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            $Verb = ($FunctionName -split '-')[0]
            $ApprovedVerbs = (Get-Verb).Verb
            $ApprovedVerbs | Should -Contain $Verb -Because "Function verb '$Verb' should be an approved PowerShell verb"
        }

    }

    Context 'Function Structure' {

        It 'Function script <_.Name> should have CmdletBinding' -ForEach $script:PublicFunctions {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match '\[CmdletBinding\(' -Because 'Functions should use CmdletBinding for advanced function features'
        }

    }

}

Describe 'Individual Function Tests' {

    BeforeAll {
        $script:PublicPath = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath 'Source\Public'
    }

    Context 'Get-CurrentUser' {

        BeforeAll {
            $FunctionPath = Join-Path -Path $script:PublicPath -ChildPath 'Get-CurrentUser.ps1'
            $script:FunctionExists = Test-Path $FunctionPath
            if ($script:FunctionExists) {
                . $FunctionPath
            }
        }

        It 'Function file should exist' {
            $script:FunctionExists | Should -BeTrue
        }

        It 'Function should be available' {
            if ($script:FunctionExists) {
                Get-Command -Name Get-CurrentUser -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should return a custom object' {
            if ($script:FunctionExists) {
                $Result = Get-CurrentUser
                $Result | Should -BeOfType [PSCustomObject]
            }
        }

        It 'Should return object with Name property' {
            if ($script:FunctionExists) {
                $Result = Get-CurrentUser
                $Result.PSObject.Properties.Name | Should -Contain 'Name'
            }
        }

        It 'Should return object with Domain property' {
            if ($script:FunctionExists) {
                $Result = Get-CurrentUser
                $Result.PSObject.Properties.Name | Should -Contain 'Domain'
            }
        }

        It 'Should return object with SID property' {
            if ($script:FunctionExists) {
                $Result = Get-CurrentUser
                $Result.PSObject.Properties.Name | Should -Contain 'SID'
            }
        }

    }

    Context 'Get-ShellApps' {

        BeforeAll {
            $FunctionPath = Join-Path -Path $script:PublicPath -ChildPath 'Get-ShellApps.ps1'
            $script:FunctionExists = Test-Path $FunctionPath
            if ($script:FunctionExists) {
                . $FunctionPath
            }
        }

        It 'Function file should exist' {
            $script:FunctionExists | Should -BeTrue
        }

        It 'Function should be available' {
            if ($script:FunctionExists) {
                Get-Command -Name Get-ShellApps -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should return shell applications' {
            if ($script:FunctionExists) {
                $Result = Get-ShellApps
                $Result | Should -Not -BeNullOrEmpty
            }
        }

    }

    Context 'Invoke-ProfileReload' {

        BeforeAll {
            $FunctionPath = Join-Path -Path $script:PublicPath -ChildPath 'Invoke-ProfileReload.ps1'
            $script:FunctionExists = Test-Path $FunctionPath
            $script:FunctionContent = if ($script:FunctionExists) {
                Get-Content -Path $FunctionPath -Raw
            } else {
                ''
            }
        }

        It 'Function file should exist' {
            $script:FunctionExists | Should -BeTrue
        }

        It 'Should have Reload-Profile alias' {
            if ($script:FunctionExists) {
                $script:FunctionContent | Should -Match "Alias\('Reload-Profile'\)"
            }
        }

    }

}
