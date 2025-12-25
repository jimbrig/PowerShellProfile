<#
    .SYNOPSIS
        Registers .NET CLI shell completion for PowerShell
    .LINK
        https://learn.microsoft.com/en-us/dotnet/core/tools/enable-tab-completion
#>

if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
    Write-Verbose '.NET CLI shell completion registered successfully.'
} else {
    Write-Debug 'dotnet command not found; skipping .NET CLI completion registration.'
}
