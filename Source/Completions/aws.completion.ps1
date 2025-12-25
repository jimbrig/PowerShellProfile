<#
    .SYNOPSIS
        Registers AWS CLI shell completion for PowerShell
    .LINK
        https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-completion.html
#>

if (Get-Command aws -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName aws -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        $env:COMP_LINE = $wordToComplete
        $env:COMP_POINT = $cursorPosition
        aws_completer.exe | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
        Remove-Item Env:\COMP_LINE
        Remove-Item Env:\COMP_POINT
    }
    Write-Verbose 'AWS CLI shell completion registered successfully.'
} else {
    Write-Debug 'aws command not found; skipping AWS CLI completion registration.'
}
