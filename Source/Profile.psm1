# --------------------------------------------------------------
# PowerShell Core Source/Profile.psm1 Custom Script Module
# --------------------------------------------------------------

using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Diagnostics.CodeAnalysis

<#
    .SYNOPSIS
        PowerShell Profile Script Module
    .DESCRIPTION
        This script module is executed by `Profile.ps1` when a new PowerShell session is created
        for the current user, on any host.
    .PARAMETER Vanilla
        Runs a "vanilla" session, without any configurations, variables, customizations, modules or scripts pre-loaded.
    .PARAMETER NoImports
        Skips importing modules and scripts.
    .PARAMETER DebugLogging
        Enables debug logging for profile loading.
    .PARAMETER Measure
        Enables performance measurement of each profile component.
    .NOTES
        Author: Jimmy Briggs <jimmy.briggs@jimbrig.com>
#>
#Requires -Version 7
[SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable', '', Justification = 'PS7 Polyfill')]
[SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Profile Script')]
[CmdletBinding()]
Param(
    [Parameter()]
    [switch]$Vanilla,
    [Parameter()]
    [switch]$NoImports,
    [Parameter()]
    [switch]$Measure,
    [Parameter()]
    [switch]$DebugLogging
)

# Skip everything if Vanilla mode is enabled
if ($Vanilla) {
    Write-Host 'Running in vanilla mode. Skipping profile customizations.' -ForegroundColor Yellow
    return
}

# variables
$Global:Interactive = ($Host.Name -eq 'ConsoleHost')
$Global:ProfileRootPath = Split-Path -Path $PROFILE -Parent
$Global:ProfileSourcePath = Join-Path -Path $ProfileRootPath -ChildPath 'Source'
$Global:ProfileConfigPath = Join-Path -Path $ProfileSourcePath -ChildPath 'Configuration'
$Global:ProfileConfigFilePath = Join-Path -Path $ProfileConfigPath -ChildPath 'Profile.Configuration.psd1'
$Global:ProfilePrivatePath = Join-Path -Path $ProfileSourcePath -ChildPath 'Private'
$Global:ProfilePublicPath = Join-Path -Path $ProfileSourcePath -ChildPath 'Public'
$Global:ProfileScriptsPath = Join-Path -Path $ProfileSourcePath -ChildPath 'Scripts'

# Import Profile Components



<#


# remove "R" alias which by default is set to Invoke-History (for R.exe to work)
Remove-Alias -Name R -ErrorAction SilentlyContinue

# set ai alias
Set-Alias -Name ai -Value aichat.exe -ErrorAction SilentlyContinue

# import chocolatey profile
try {
    Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1 -ErrorAction Stop
} catch {
    Write-Warning "Chocolatey profile not loaded: $_"
}

# azure-cli completion
if (Get-Command az -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        try {
            $completion_file = New-TemporaryFile
            $env:ARGCOMPLETE_USE_TEMPFILES = 1
            $env:_ARGCOMPLETE_STDOUT_FILENAME = $completion_file
            $env:COMP_LINE = $wordToComplete
            $env:COMP_POINT = $cursorPosition
            $env:_ARGCOMPLETE = 1
            $env:_ARGCOMPLETE_SUPPRESS_SPACE = 0
            $env:_ARGCOMPLETE_IFS = "`n"
            $env:_ARGCOMPLETE_SHELL = 'powershell'
            az 2>&1 | Out-Null
            Get-Content $completion_file | Sort-Object | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
            Remove-Item $completion_file -ErrorAction SilentlyContinue
            Remove-Item Env:\_ARGCOMPLETE_STDOUT_FILENAME, Env:\ARGCOMPLETE_USE_TEMPFILES, Env:\COMP_LINE, Env:\COMP_POINT, Env:\_ARGCOMPLETE, Env:\_ARGCOMPLETE_SUPPRESS_SPACE, Env:\_ARGCOMPLETE_IFS, Env:\_ARGCOMPLETE_SHELL -ErrorAction SilentlyContinue
        } catch {
            Write-Warning "Error in az completion: $_"
        }
    }
}

# gh-cli completion
if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression -Command $(gh completion --shell powershell | Out-String)
        Write-Verbose 'GitHub CLI shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register GitHub CLI shell completion: $_"
    }
}

# aichat completion & shell integration
if (Get-Command aichat -ErrorAction SilentlyContinue) {
    try {
        . (Join-Path $ProfileSourcePath 'Completions\aichat.completion.ps1')
        Write-Verbose 'aichat shell completion registered successfully.'

        Set-PSReadLineKeyHandler -Chord 'alt+e' -ScriptBlock {
            $_old = $null
            [Microsoft.PowerShell.PSConsoleReadline]::GetBufferState([ref]$_old, [ref]$null)
            if ($_old) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert('⌛')
                $_new = (aichat -e $_old)
                [Microsoft.PowerShell.PSConsoleReadLine]::DeleteLine()
                [Microsoft.PowerShell.PSConsoleReadline]::Insert($_new)
            }
        }
        Write-Verbose 'aichat shell integration registered successfully.'
    } catch {
        Write-Warning "Failed to register aichat shell completion: $_"
    }
}

# zoxide initialization
try {
    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Invoke-Expression (& { (zoxide init powershell --cmd z | Out-String) })
    }
} catch {
    Write-Warning "Zoxide not initialzied: $_"
}

# oh-my-posh initialization
try {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        $themeFile = Join-Path "$Env:POSH_THEMES_PATH" 'wopian.omp.json' -ErrorAction SilentlyContinue
        if (Test-Path $themeFile -ErrorAction SilentlyContinue) {
            $Expression = (& oh-my-posh init pwsh --config=$themeFile --print) -join "`n"
            Invoke-Expression $Expression
        } else {
            Write-Warning "Theme file not found: $themeFile"
        }
    }
} catch {
    Write-Warning "Oh-My-Posh not initialized: $_"
}

# PSReadLine
if ($Interactive) {
    Import-Module -Name PSReadLine -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key 'Ctrl+Home' -Function 'BeginningOfLine'
    Set-PSReadLineKeyHandler -Key 'Ctrl+End' -Function 'EndOfLine'
    Set-PSReadLineKeyHandler -Key 'Ctrl+Shift+Home' -Function 'SelectBackwardsLine'
    Set-PSReadLineKeyHandler -Key 'Ctrl+Shift+End' -Function 'SelectLine'

}

# Functions
. $PSScriptRoot\Source\Public\Update-WinGetPackages.ps1

# Import modules
@(
    'Microsoft.PowerShell.ConsoleGuiTools',
    'Terminal-Icons',
    'posh-git',
    'F7History',
    'tiPS'
) | ForEach-Object {
    Import-Module $_ -ErrorAction SilentlyContinue
}
#>
