<#
    .SYNOPSIS
        Registers winget shell completion for PowerShell
    .LINK
        https://github.com/microsoft/winget-cli/blob/master/doc/Completion.md#powershell
#>

if (Get-Command winget -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
    Write-Verbose 'winget shell completion registered successfully.'
} else {
    Write-Debug 'winget command not found; skipping winget completion registration.'
}
