<#
    .SYNOPSIS
        Pester tests for PowerShell completion scripts
    .DESCRIPTION
        Tests the structure, syntax, and conventions of completion loader scripts
        in Source/Completions to ensure consistency and proper implementation.
#>

BeforeDiscovery {
    $script:CompletionsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Source\Completions'
    $script:CompletionScripts = Get-ChildItem -Path $script:CompletionsPath -Filter '*.completion.ps1' -File

    # dynamic scripts use Invoke-Expression at the top level (not inside a scriptblock)
    $script:DynamicScripts = $script:CompletionScripts | Where-Object {
        $content = Get-Content -Path $_.FullName -Raw
        # match Invoke-Expression outside of Register-ArgumentCompleter scriptblocks
        ($content -match 'Invoke-Expression -Command') -and ($content -notmatch 'Register-ArgumentCompleter')
    }

    $script:ModuleScripts = $script:CompletionScripts | Where-Object {
        (Get-Content -Path $_.FullName -Raw) -match 'Import-Module'
    }

    $script:CompleterScripts = $script:CompletionScripts | Where-Object {
        (Get-Content -Path $_.FullName -Raw) -match 'Register-ArgumentCompleter'
    }
}

Describe 'Completion Scripts' {

    BeforeAll {
        $script:CompletionsPathRuntime = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Source\Completions'
        $script:CompletionScriptsRuntime = Get-ChildItem -Path $script:CompletionsPathRuntime -Filter '*.completion.ps1' -File

        $ExpectedPatterns = @{
            CommandCheck   = 'Get-Command .+ -ErrorAction SilentlyContinue'
            VerboseSuccess = 'Write-Verbose .+(registered|imported) successfully'
            DebugSkip      = 'Write-Debug .+not found'
        }
    }

    Context 'Script Discovery' {

        It 'Should find completion scripts in Source/Completions' {
            $script:CompletionScriptsRuntime.Count | Should -BeGreaterThan 0
        }

        It 'Should have at least 15 completion scripts' {
            $script:CompletionScriptsRuntime.Count | Should -BeGreaterOrEqual 15
        }

    }

    Context 'Script Syntax Validation' {

        It 'Script <_.Name> should have valid PowerShell syntax' -ForEach $script:CompletionScripts {
            $ScriptPath = $_.FullName
            $Errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$Errors)
            $Errors.Count | Should -Be 0 -Because 'Script should parse without syntax errors'
        }

    }

    Context 'Documentation Standards' {

        It 'Script <_.Name> should have a comment-based help block' -ForEach $script:CompletionScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match '<#' -Because 'Script should have comment-based help'
            $Content | Should -Match '#>' -Because 'Script should have comment-based help closing tag'
        }

        It 'Script <_.Name> should have .SYNOPSIS in help block' -ForEach $script:CompletionScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match '\.SYNOPSIS' -Because 'Script should document its purpose'
        }

        It 'Script <_.Name> should have .LINK in help block' -ForEach $script:CompletionScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match '\.LINK' -Because 'Script should link to documentation'
        }

    }

    Context 'Structure Standards' {

        It 'Script <_.Name> should check if command exists before registering' -ForEach $script:CompletionScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match $ExpectedPatterns.CommandCheck -Because 'Script should verify command availability'
        }

        It 'Script <_.Name> should output verbose message on success' -ForEach $script:CompletionScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match $ExpectedPatterns.VerboseSuccess -Because 'Script should provide verbose feedback'
        }

        It 'Script <_.Name> should output debug message when skipping' -ForEach $script:CompletionScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match $ExpectedPatterns.DebugSkip -Because 'Script should indicate when skipped'
        }

        It 'Script <_.Name> should use lowercase if statement' -ForEach $script:CompletionScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match '\nif \(Get-Command' -Because "Script should use lowercase 'if' for consistency"
        }

    }

    Context 'Naming Conventions' {

        It 'Script <_.Name> should follow naming pattern: <tool>.completion.ps1' -ForEach $script:CompletionScripts {
            $_.Name | Should -Match '^[a-z0-9\-]+\.completion\.ps1$' -Because 'Script name should be lowercase with hyphens'
        }

    }

}

Describe 'Completion Script Categories' {

    BeforeAll {
        $script:CompletionsPathRuntime = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Source\Completions'
        $script:AllScripts = Get-ChildItem -Path $script:CompletionsPathRuntime -Filter '*.completion.ps1' -File

        $script:DynamicScriptsRuntime = $script:AllScripts | Where-Object {
            $content = Get-Content -Path $_.FullName -Raw
            ($content -match 'Invoke-Expression -Command') -and ($content -notmatch 'Register-ArgumentCompleter')
        }

        $script:ModuleScriptsRuntime = $script:AllScripts | Where-Object {
            (Get-Content -Path $_.FullName -Raw) -match 'Import-Module'
        }

        $script:CompleterScriptsRuntime = $script:AllScripts | Where-Object {
            (Get-Content -Path $_.FullName -Raw) -match 'Register-ArgumentCompleter'
        }
    }

    Context 'Dynamic Completion Scripts (Invoke-Expression)' {

        It 'Should find dynamic completion scripts' {
            $script:DynamicScriptsRuntime.Count | Should -BeGreaterThan 0
        }

        It 'Dynamic script <_.Name> should have try-catch error handling' -ForEach $script:DynamicScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match 'try\s*\{' -Because 'Dynamic completions should handle errors'
            $Content | Should -Match 'catch\s*\{' -Because 'Dynamic completions should catch errors'
        }

        It 'Dynamic script <_.Name> should warn on failure' -ForEach $script:DynamicScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match 'Write-Warning' -Because 'Dynamic completions should warn on failure'
        }

    }

    Context 'Module-Based Completion Scripts' {

        It 'Should find module-based completion scripts' {
            $script:ModuleScriptsRuntime.Count | Should -BeGreaterThan 0
        }

        It 'Module script <_.Name> should check module availability' -ForEach $script:ModuleScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $HasModuleCheck = ($Content -match 'Get-InstalledPSResource') -or ($Content -match 'Test-Path')
            $HasModuleCheck | Should -BeTrue -Because 'Module scripts should verify module exists'
        }

    }

    Context 'Register-ArgumentCompleter Scripts' {

        It 'Should find Register-ArgumentCompleter scripts' {
            $script:CompleterScriptsRuntime.Count | Should -BeGreaterThan 0
        }

        It 'Completer script <_.Name> should register native completion' -ForEach $script:CompleterScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match 'Register-ArgumentCompleter' -Because 'Script should register argument completer'
        }

    }

}

Describe 'Completion Script Execution Safety' {

    Context 'No Harmful Patterns' {

        It 'Script <_.Name> should not contain Remove-Item without safeguards' -ForEach $script:CompletionScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            # allow Remove-Item only for temp files or env vars (az.completion.ps1 pattern)
            if ($Content -match 'Remove-Item(?!.*\$completion_file)(?!.*Env:)') {
                $Content | Should -Match 'ErrorAction' -Because 'Remove-Item should have error handling'
            }
        }

        It 'Script <_.Name> should not execute arbitrary external commands without checks' -ForEach $script:CompletionScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            # scripts that use & or Invoke-Expression should first check command exists
            if ($Content -match '^\s*&\s*\$') {
                $Content | Should -Match 'Test-Path|Get-Command' -Because 'External execution should verify target exists'
            }
        }

    }

    Context 'Error Handling' {

        It 'Script <_.Name> should use -ErrorAction SilentlyContinue for Get-Command checks' -ForEach $script:CompletionScripts {
            $Content = Get-Content -Path $_.FullName -Raw
            $Content | Should -Match 'Get-Command .+ -ErrorAction SilentlyContinue' -Because 'Command checks should not throw'
        }

    }

}
