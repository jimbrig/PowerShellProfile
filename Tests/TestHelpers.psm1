<#
    .SYNOPSIS
        Shared test helper functions for Pester tests
    .DESCRIPTION
        Provides common utilities and helper functions used across test files.
#>

#region Path Helpers

function Get-ProfileRootPath {
    <#
        .SYNOPSIS
            Gets the PowerShell profile root path
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Split-Path -Path $PROFILE -Parent
}

function Get-ProfileSourcePath {
    <#
        .SYNOPSIS
            Gets the profile Source directory path
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Join-Path -Path (Get-ProfileRootPath) -ChildPath 'Source'
}

function Get-ProfilePublicPath {
    <#
        .SYNOPSIS
            Gets the profile Public functions directory path
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Join-Path -Path (Get-ProfileSourcePath) -ChildPath 'Public'
}

function Get-ProfileModulesPath {
    <#
        .SYNOPSIS
            Gets the profile custom Modules directory path
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Join-Path -Path (Get-ProfileSourcePath) -ChildPath 'Modules'
}

function Get-ProfileConfigurationPath {
    <#
        .SYNOPSIS
            Gets the profile Configuration directory path
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Join-Path -Path (Get-ProfileSourcePath) -ChildPath 'Configuration'
}

#endregion

#region Script Validation Helpers

function Test-ScriptSyntax {
    <#
        .SYNOPSIS
            Tests if a PowerShell script has valid syntax
        .PARAMETER Path
            Path to the script file
        .OUTPUTS
            Boolean indicating if syntax is valid
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $Errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$Errors)
    return ($Errors.Count -eq 0)
}

function Get-ScriptFunctions {
    <#
        .SYNOPSIS
            Extracts function definitions from a script file
        .PARAMETER Path
            Path to the script file
        .OUTPUTS
            Array of function names defined in the script
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $Tokens = $null
    $Errors = $null
    $Ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$Tokens, [ref]$Errors)

    $Ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) |
        ForEach-Object { $_.Name }
}

function Test-ScriptHasHelpBlock {
    <#
        .SYNOPSIS
            Tests if a script has comment-based help
        .PARAMETER Path
            Path to the script file
        .OUTPUTS
            Boolean indicating if help block exists
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $Content = Get-Content -Path $Path -Raw
    return ($Content -match '<#[\s\S]*\.SYNOPSIS[\s\S]*#>')
}

#endregion

#region Module Helpers

function Get-CustomModules {
    <#
        .SYNOPSIS
            Gets list of custom modules in the profile
        .OUTPUTS
            Array of module directory info objects
    #>
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo[]])]
    param()

    $ModulesPath = Get-ProfileModulesPath
    if (Test-Path $ModulesPath) {
        Get-ChildItem -Path $ModulesPath -Directory
    }
}

function Test-ModuleHasManifest {
    <#
        .SYNOPSIS
            Tests if a module directory has a manifest file
        .PARAMETER ModulePath
            Path to the module directory
        .OUTPUTS
            Boolean indicating if manifest exists
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath
    )

    $ModuleName = Split-Path -Path $ModulePath -Leaf
    $ManifestPath = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
    return (Test-Path -Path $ManifestPath -PathType Leaf)
}

function Test-ModuleHasRootModule {
    <#
        .SYNOPSIS
            Tests if a module directory has a root module file
        .PARAMETER ModulePath
            Path to the module directory
        .OUTPUTS
            Boolean indicating if root module exists
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath
    )

    $ModuleName = Split-Path -Path $ModulePath -Leaf
    $RootModulePath = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psm1"
    return (Test-Path -Path $RootModulePath -PathType Leaf)
}

#endregion

#region Performance Helpers

function Measure-ScriptExecution {
    <#
        .SYNOPSIS
            Measures script execution time
        .PARAMETER ScriptBlock
            Script block to measure
        .PARAMETER Iterations
            Number of iterations to run
        .OUTPUTS
            Average execution time in milliseconds
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [int]$Iterations = 1
    )

    $Times = @()
    for ($i = 0; $i -lt $Iterations; $i++) {
        $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        & $ScriptBlock
        $Stopwatch.Stop()
        $Times += $Stopwatch.Elapsed.TotalMilliseconds
    }

    return ($Times | Measure-Object -Average).Average
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Get-ProfileRootPath'
    'Get-ProfileSourcePath'
    'Get-ProfilePublicPath'
    'Get-ProfileModulesPath'
    'Get-ProfileConfigurationPath'
    'Test-ScriptSyntax'
    'Get-ScriptFunctions'
    'Test-ScriptHasHelpBlock'
    'Get-CustomModules'
    'Test-ModuleHasManifest'
    'Test-ModuleHasRootModule'
    'Measure-ScriptExecution'
)

