Function New-QuickAccessPin {
    <#
        .SYNOPSIS
            Adds a pinned folder to Quick Access in Windows Explorer.
        .DESCRIPTION
            This function allows you to add a specified folder to the Quick Access section of Windows Explorer.
        .PARAMETER Path
            The path of the folder you want to add to Quick Access.
        .EXAMPLE
            New-QuickAccessPin -Path "C:\Users\YourUsername\Documents"
        .INPUTS
            System.String
        .OUTPUTS
            None
    #>
    [Alias("Pin-QuickAccess", "New-QAPin")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path,

        [Parameter()]
        [Switch]$RestartExplorer
    )

    Begin {
        Write-Verbose "[BEGIN]: New-QuickAccessPath"
        $PathToPin = (Resolve-Path -Path $Path).Path
        $QAT = New-Object -ComObject shell.application
    }

    Process {
        Write-Verbose "[PROCESS]: New-QuickAccessPath"
        try {
            $QAT.Namespace($PathToPin).Self.InvokeVerb("pintohome")
            Write-Host "Successfully pinned '$PathToPin' to Quick Access." -ForegroundColor Green
        } catch {
            Write-Host "Failed to pin $PathToPin to Quick Access. Ensure the path is valid and accessible." -ForegroundColor Red
            Write-Error "Error: $_"
        }

        Write-Verbose "[PROCESS]: RestartExplorer: $RestartExplorer"
        if ($RestartExplorer) {
            Restart-Explorer
        }
    }

    End {
        Write-Verbose "[END]: New-QuickAccessPath"
        $QAT = $null
        $PathToPin = $null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }

}
