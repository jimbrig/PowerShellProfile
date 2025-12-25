Function Restart-Explorer {
    <#
        .SYNOPSIS
            Restarts the Windows Explorer process.
        .DESCRIPTION
            This function stops and restarts the Windows Explorer process, which can be useful for applying changes or resolving issues with the Explorer interface.
        .EXAMPLE
            Restart-Explorer
        .INPUTS
            None
        .OUTPUTS
            None
    #>
    [CmdletBinding()]
    Param ()

    Begin {
        Write-Verbose "[BEGIN]: Restart-Explorer"
        $user = Get-CurrentUser
        try {
            $explorer = Get-Process -Name explorer -ErrorAction stop -IncludeUserName
        }
        catch {
            $global:error.RemoveAt(0)
        }
    }

    Process {
        Write-Verbose "[PROCESS]: Restart-Explorer"
        try {
            if ($null -ne $explorer) {
                $explorer | Where-Object { $_.UserName -eq "$($user.Domain)\$($user.Name)" } | `
                    Stop-Process -Force -ErrorAction Stop | Out-Null
            }
            Start-Sleep 1
            if (!(Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
                $global:error.RemoveAt(0)
                Start-Process -FilePath explorer.exe
            }
            Write-Host "Explorer has been restarted successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to restart Explorer. Please try again." -ForegroundColor Red
            Write-Error "Error: $_"
        }
    }

    End {
        Write-Verbose "[END]: Restart-Explorer"

    }

}

