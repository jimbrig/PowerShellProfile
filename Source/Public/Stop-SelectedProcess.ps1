#!/usr/bin/env pwsh

Function Stop-SelectedProcess {
    <#
        .SYNOPSIS
            Stops a selected process from a dynamic list of running processes.
        .DESCRIPTION
            This utility function stops a selected process from a dynamic list of running processes.
        .PARAMETER Name
            The name of the process to stop (optional). Can be used to filter the list of processes by passing it
            a regular expression pattern also. If not provided, all processes will be displayed to the user to select
            from.
        .EXAMPLE
            Stop-SelectedProcess
        .EXAMPLE
            Stop-SelectedProcess -Name 'notepad'
        .NOTES
            Author: Jimmy Briggs <jimmy.briggs@noclocks.dev>
    #>
    #Requires -Module Microsoft.PowerShell.ConsoleGuiTools
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Name
    )

    Begin {

        # Get Initial Processes
        $Processes = Get-Process | Where-Object { $_.Name -ne 'Idle' -and $_.Name -ne 'System' }
        if ($Name) {
            $Processes = $Processes | Where-Object { $_.Name -like $Name }
        }

        # Setup Console GUI Tools
        Import-Module Microsoft.PowerShell.ConsoleGuiTools

    }

    Process {

        # Display Processes in GridView
        $Selection = $Processes | Out-ConsoleGridView -Title 'Select a Process to Stop' -OutputMode Multiple
        Write-Verbose "Selected Processes: $($Selection.Name)"

        # Stop Selected Processes
        Write-Verbose "Stopping Selected Processes..."
        $Selection | ForEach-Object {
            if ($WhatIfPreference) {
                Write-Host "Stopping Process: $($_.Name) - ID: $($_.Id)" -ForegroundColor Yellow
            } else {
                Stop-Process -Id $_.Id -Force
            }
        }
    }

    End {

        Write-Verbose "Stopped Selected Processes."

        # Return Selected Processes
        return $Selection
    }
}
