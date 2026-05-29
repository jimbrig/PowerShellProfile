Function Get-DynamicAboutHelp {
    <#
        .SYNOPSIS
            Displays a dynamic list of about topics and allows the user to select one to view.
        .DESCRIPTION
            This utility function displays a dynamic list of about topics and allows the user to select one to view.
        .EXAMPLE
            Get-DynamicAboutHelp
        .EXAMPLE
            Get-DynamicAboutHelp -Glob 'about*'
        .NOTES
            Author: Jimmy Briggs <jimmy.briggs@jimbrig.com>
    #>
    #Requires -Module Microsoft.PowerShell.ConsoleGuiTools
    [CmdletBinding()]
    Param(
        [Parameter()]
        [String]$Glob = 'about*'
    )

    Begin {
        $About = Get-Help -Name $Glob | Select-Object -Property Name, Synopsis
    }

    Process {
        $About | Out-ConsoleGridView -Title 'Select a Help Topic' -OutputMode Single | Get-Help
    }

    End {

    }
}
