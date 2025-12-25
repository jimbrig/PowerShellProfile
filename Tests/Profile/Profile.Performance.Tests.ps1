<#
    .SYNOPSIS
        Pester tests for PowerShell profile performance
    .DESCRIPTION
        Tests profile loading performance and individual component load times
        to ensure the profile doesn't significantly slow down shell startup.
#>

Describe 'Profile Performance' {

    BeforeAll {
        $script:ProfileRoot = Split-Path -Path $PROFILE -Parent
        $script:SourcePath = Join-Path -Path $script:ProfileRoot -ChildPath 'Source'
        $script:ProfileModulePath = Join-Path -Path $script:SourcePath -ChildPath 'Profile.psm1'

        # performance thresholds (milliseconds)
        $script:MaxProfileLoadTime = 5000   # 5 seconds max for full profile
        $script:MaxScriptParseTime = 1000   # 1 second max to parse any script
        $script:MaxConfigLoadTime = 100     # 100ms max to load config files
    }

    Context 'Script Parsing Performance' {

        It 'Profile.psm1 should parse in under 1 second' {
            $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = [System.Management.Automation.Language.Parser]::ParseFile(
                $script:ProfileModulePath,
                [ref]$null,
                [ref]$null
            )
            $Stopwatch.Stop()

            $Stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxScriptParseTime
        }

    }

    Context 'Configuration Loading Performance' {

        BeforeAll {
            $script:ConfigPath = Join-Path -Path $script:SourcePath -ChildPath 'Configuration'
            $script:ProfileConfigPath = Join-Path -Path $script:SourcePath -ChildPath 'Profile.Configuration.psd1'
        }

        It 'Profile.Configuration.psd1 should load in under 100ms' {
            if (Test-Path $script:ProfileConfigPath) {
                $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $null = Import-PowerShellDataFile -Path $script:ProfileConfigPath
                $Stopwatch.Stop()

                $Stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxConfigLoadTime
            }
        }

        It 'Each configuration file should load quickly' {
            if (Test-Path $script:ConfigPath) {
                $ConfigFiles = Get-ChildItem -Path $script:ConfigPath -Filter '*.psd1' -File

                foreach ($ConfigFile in $ConfigFiles) {
                    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    $null = Import-PowerShellDataFile -Path $ConfigFile.FullName -ErrorAction SilentlyContinue
                    $Stopwatch.Stop()

                    $Stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxConfigLoadTime -Because "$($ConfigFile.Name) should load quickly"
                }
            }
        }

    }

    Context 'Completion Script Performance' {

        BeforeAll {
            $script:CompletionsPath = Join-Path -Path $script:SourcePath -ChildPath 'Completions'
            $script:MaxCompletionParseTime = 500  # 500ms max per completion script
        }

        It 'Large completion scripts should parse efficiently' {
            if (Test-Path $script:CompletionsPath) {
                # test the largest completion scripts
                $LargeScripts = Get-ChildItem -Path $script:CompletionsPath -Filter '*.completion.ps1' -File |
                    Where-Object { $_.Length -gt 10KB }

                foreach ($Script in $LargeScripts) {
                    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    $null = [System.Management.Automation.Language.Parser]::ParseFile(
                        $Script.FullName,
                        [ref]$null,
                        [ref]$null
                    )
                    $Stopwatch.Stop()

                    $Stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxCompletionParseTime -Because "$($Script.Name) should parse quickly"
                }
            }
        }

    }

    Context 'Public Functions Performance' {

        BeforeAll {
            $script:PublicPath = Join-Path -Path $script:SourcePath -ChildPath 'Public'
            $script:MaxFunctionParseTime = 200  # 200ms max per function script
        }

        It 'Public function scripts should parse quickly' {
            if (Test-Path $script:PublicPath) {
                $FunctionScripts = Get-ChildItem -Path $script:PublicPath -Filter '*.ps1' -File

                foreach ($Script in $FunctionScripts) {
                    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    $null = [System.Management.Automation.Language.Parser]::ParseFile(
                        $Script.FullName,
                        [ref]$null,
                        [ref]$null
                    )
                    $Stopwatch.Stop()

                    $Stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionParseTime -Because "$($Script.Name) should parse quickly"
                }
            }
        }

    }

}

Describe 'Profile Component Count Limits' {

    BeforeAll {
        $script:ProfileRoot = Split-Path -Path $PROFILE -Parent
        $script:SourcePath = Join-Path -Path $script:ProfileRoot -ChildPath 'Source'

        # reasonable limits to prevent profile bloat
        $script:MaxCompletionScripts = 50
        $script:MaxPublicFunctions = 50
        $script:MaxConfigFiles = 20
    }

    Context 'Completion Scripts Count' {

        It 'Should not have excessive completion scripts' {
            $CompletionsPath = Join-Path -Path $script:SourcePath -ChildPath 'Completions'
            if (Test-Path $CompletionsPath) {
                $CompletionCount = (Get-ChildItem -Path $CompletionsPath -Filter '*.completion.ps1' -File).Count
                $CompletionCount | Should -BeLessOrEqual $script:MaxCompletionScripts -Because 'Too many completion scripts can slow profile loading'
            }
        }

    }

    Context 'Public Functions Count' {

        It 'Should not have excessive public functions' {
            $PublicPath = Join-Path -Path $script:SourcePath -ChildPath 'Public'
            if (Test-Path $PublicPath) {
                $FunctionCount = (Get-ChildItem -Path $PublicPath -Filter '*.ps1' -File).Count
                $FunctionCount | Should -BeLessOrEqual $script:MaxPublicFunctions -Because 'Too many functions can slow profile loading'
            }
        }

    }

    Context 'Configuration Files Count' {

        It 'Should not have excessive configuration files' {
            $ConfigPath = Join-Path -Path $script:SourcePath -ChildPath 'Configuration'
            if (Test-Path $ConfigPath) {
                $ConfigCount = (Get-ChildItem -Path $ConfigPath -Filter '*.psd1' -File).Count
                $ConfigCount | Should -BeLessOrEqual $script:MaxConfigFiles -Because 'Too many config files add loading overhead'
            }
        }

    }

}

Describe 'Profile File Sizes' {

    BeforeAll {
        $script:ProfileRoot = Split-Path -Path $PROFILE -Parent
        $script:SourcePath = Join-Path -Path $script:ProfileRoot -ChildPath 'Source'

        # size limits in KB
        $script:MaxProfileModuleSize = 100      # 100 KB
        $script:MaxCompletionScriptSize = 600   # 600 KB (some are auto-generated)
        $script:MaxFunctionScriptSize = 50      # 50 KB
    }

    Context 'Profile Module Size' {

        It 'Profile.psm1 should not be excessively large' {
            $ProfileModulePath = Join-Path -Path $script:SourcePath -ChildPath 'Profile.psm1'
            if (Test-Path $ProfileModulePath) {
                $SizeKB = (Get-Item $ProfileModulePath).Length / 1KB
                $SizeKB | Should -BeLessOrEqual $script:MaxProfileModuleSize -Because 'Large profile modules take longer to load'
            }
        }

    }

    Context 'Completion Script Sizes' {

        It 'Completion scripts should not be excessively large' {
            $CompletionsPath = Join-Path -Path $script:SourcePath -ChildPath 'Completions'
            if (Test-Path $CompletionsPath) {
                $LargeScripts = Get-ChildItem -Path $CompletionsPath -Filter '*.completion.ps1' -File |
                    Where-Object { ($_.Length / 1KB) -gt $script:MaxCompletionScriptSize }

                $LargeScripts.Count | Should -Be 0 -Because "Completion scripts over $($script:MaxCompletionScriptSize)KB should be reviewed"
            }
        }

    }

    Context 'Function Script Sizes' {

        It 'Public function scripts should not be excessively large' {
            $PublicPath = Join-Path -Path $script:SourcePath -ChildPath 'Public'
            if (Test-Path $PublicPath) {
                $LargeScripts = Get-ChildItem -Path $PublicPath -Filter '*.ps1' -File |
                    Where-Object { ($_.Length / 1KB) -gt $script:MaxFunctionScriptSize }

                $LargeScripts.Count | Should -Be 0 -Because "Function scripts over $($script:MaxFunctionScriptSize)KB should be split up"
            }
        }

    }

}

