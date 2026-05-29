# ------------------------------------------------------------------------------
# Import-Completion
# ------------------------------------------------------------------------------

Function Import-Completion {
    <#
    .SYNOPSIS
        Load the completion script for the specified command.
    .DESCRIPTION
        This function loads the completion script for the specified command by dot-sourcing the script file.

        The function checks if the completion script for the specified command exists in the `$CompletionScripts` hash
        table and if it has not already been loaded. If both conditions are met, the function dot-sources the completion
        script defined in the hash table and sets the `$Script:CompletionLoaded` hash table entry for the specified
        command to `$true` (for the current session).

        This function is used to implement a lazy-loading mechanism for importing completion scripts.

    .PARAMETER CommandName
        The name of the command for which to load the completion script. This parameter is mandatory and accepts input
        from the pipeline. The value of this parameter is validated against the keys in the `$CompletionScripts` hash
        table defined in the `Completions.psd1` file.

    .EXAMPLE
        # Load the completion script for the `aws` command.
        Load-Completion -CommandName 'aws'
    #>
    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = 'None'
    )]
    Param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateScript({ $CompletionScripts.ContainsKey($_) })]
        [String]$CommandName
    )

    If ($CompletionScripts.ContainsKey($CommandName) -and -not $Script:CompletionLoaded[$CommandName]) {
        . $CompletionScripts[$CommandName]
        $Script:CompletionLoaded[$CommandName] = $true
    }

}
