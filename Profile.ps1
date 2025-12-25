# --------------------------------------------------------------
# PowerShell Core $PROFILE (Current User, All Hosts)
# --------------------------------------------------------------

# variables
$Global:Interactive = ($Host.Name -eq 'ConsoleHost')
$Global:ProfileRootPath = Split-Path -Path $PROFILE -Parent
$Global:ProfileSourcePath = Join-Path -Path $ProfileRootPath -ChildPath 'Source'
$Global:ProfileConfigPath = Join-Path -Path $ProfileSourcePath -ChildPath 'Profile.Configuration.psd1'

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

# obsidian-cli completion & alias
if (Get-Command obsidian-cli -ErrorAction SilentlyContinue) {
    try {
        . (Join-Path $ProfileSourcePath 'Completions\obsidian-cli.completion.ps1')
        Write-Verbose 'Obsidian CLI shell completion registered successfully.'
    } catch {
        Write-Warning "Failed to register Obsidian CLI shell completion: $_"
    }
    # obs_cd() {
    #     local result=$(obsidian-cli print-default --path-only)
    #     [ -n "$result" ] && cd -- "$result"
    # }
    Function obscd {
        $result = (obsidian-cli print-default --path-only)
        if ($result) {
            Set-Location $result
        } else {
            Write-Warning 'Failed to get Obsidian default path'
        }
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

# Prompt
# TODO: integrate with oh-my-posh
# . $PSScriptRoot\Source\Profile.Prompt.ps1

# PSReadLine
Set-PSReadLineKeyHandler -Key Ctrl+Home -Function BeginningOfLine
Set-PSReadLineKeyHandler -Key Ctrl+End -Function EndOfLine
Set-PSReadLineKeyHandler -Key Ctrl+Shift+Home -Function SelectBackwardsLine
Set-PSReadLineKeyHandler -Key Ctrl+Shift+End -Function SelectLine

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

Function Import-LocalModule {
    <#
    .SYNOPSIS
        Imports a local module from the Source/Modules directory.
    .DESCRIPTION
        This function imports a local module from the Source/Modules directory.
    .PARAMETER ModuleName
        The name of the module to import.
    .EXAMPLE
        Import-LocalModule -ModuleName 'PSClearHost'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    $modulePath = Join-Path -Path $ProfileSourcePath -ChildPath "Modules\$ModuleName"
    if (Test-Path $modulePath -PathType Container) {
        Import-Module $modulePath -ErrorAction SilentlyContinue
    } else {
        Write-Warning "Module directory not found: $modulePath"
    }
}

Import-LocalModule -ModuleName 'PSClearHost'
Function Clear-HostRaindropAliasFunction {
    <#
    .SYNOPSIS
        This function is set to the `cls` primary alias.
    .DESCRIPTION
        This is a simple wrapper that calls `Clear-HostRaindrop` with a speed of 10 and a random
        mode.
    #>
    Clear-HostRaindrop -Speed 10
}

Set-Alias -Name cls -Value Clear-HostRaindropAliasFunction -Option AllScope -Force
