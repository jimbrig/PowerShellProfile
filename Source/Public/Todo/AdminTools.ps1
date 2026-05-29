# System administration and maintenance tools
Function Invoke-Admin {
    try {
        if ($args.Count -gt 0) {
            $argList = "& '" + $args + "'"
            Start-Process "$PSHOME\pwsh.exe" -Verb runAs -ArgumentList $argList
        } else {
            Start-Process "$PSHOME\pwsh.exe" -Verb RunAs
        }
    } catch {
        Write-Error "Failed to invoke admin: $_"
    }
}

Function Invoke-DISM {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Switch]$RestoreHealth,
        [Parameter()]
        [Switch]$CheckHealth,
        [Parameter()]
        [Switch]$ScanHealth,
        [Parameter()]
        [Switch]$CleanupImage,
        [Parameter()]
        [Switch]$AnalyzeComponentStore
    )

    try {
        $cmd = 'sudo dism'
        $cmd += ' /Online'

        if ($RestoreHealth) {
            $cmd += ' /RestoreHealth'
        }

        if ($CheckHealth) {
            $cmd += ' /CheckHealth'
        }

        if ($ScanHealth) {
            $cmd += ' /ScanHealth'
        }

        if ($CleanupImage) {
            $cmd += ' /Cleanup-Image'
        }

        if ($AnalyzeComponentStore) {
            $cmd += ' /AnalyzeComponentStore'
        }

        Write-Host "DISM Command: $cmd" -ForegroundColor Cyan

        if ($WhatIfPreference) {
            Write-Host "WhatIf: $cmd" -ForegroundColor Yellow
        } else {
            Invoke-Expression -Command $cmd
        }
    } catch {
        Write-Error "Failed to invoke DISM: $_"
    }
}

Function Invoke-SFC {
    [CmdletBinding()]
    Param()

    try {
        $cmd = 'sudo sfc /scannow'

        Write-Host "SFC Command: $cmd" -ForegroundColor Cyan

        if ($WhatIfPreference) {
            Write-Host "WhatIf: $cmd" -ForegroundColor Yellow
        } else {
            Invoke-Expression -Command $cmd
        }

        Write-Host 'SFC Scan Complete.' -ForegroundColor Green

        $SFCLogPath = "$Env:WinDir\Logs\CBS\CBS.log"
        if (Test-Path -Path $SFCLogPath) {
            Write-Host "Review log file at: $SFCLogPath" -ForegroundColor Cyan
        }
    } catch {
        Write-Error "Failed to invoke SFC: $_"
    }
}

Function Get-SFCLogs {
    try {
        $SFCLogPath = "$Env:WinDir\Logs\CBS\CBS.log"
        if (Test-Path -Path $SFCLogPath) {
            Get-Content -Path $SFCLogPath
        } else {
            Write-Warning 'SFC Log file not found.'
        }
    } catch {
        Write-Error "Failed to get SFC logs: $_"
    }
}

Function Invoke-CheckDisk {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ })]
        [String]$Path = 'C:'
    )

    try {
        $cmd = "sudo chkdsk $Path /f /r"

        if ($WhatIfPreference) {
            Write-Host "WhatIf: $cmd" -ForegroundColor Yellow
        } else {
            Invoke-Expression -Command $cmd
        }
    } catch {
        Write-Error "Failed to invoke CheckDisk: $_"
    }
}

Function Get-WinSAT {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Switch]$Formal
    )

    try {
        if ($Formal) {
            $cmd = "sudo winsat formal"
        } else {
            $cmd = "sudo Get-CimInstance Win32_WinSat"
        }

        Write-Host "WinSAT Command: $cmd" -ForegroundColor Cyan

        if ($WhatIfPreference) {
            Write-Host "WhatIf: $cmd" -ForegroundColor Yellow
        } else {
            Invoke-Expression -Command $cmd
        }
    } catch {
        Write-Error "Failed to get WinSAT: $_"
    }
}

Function Invoke-TakeOwnership {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [String]$Path
    )

    try {
        $cmd = "sudo takeown /f '$Path' /r /d y"

        if ($WhatIfPreference) {
            Write-Host "WhatIf: $cmd" -ForegroundColor Yellow
        } else {
            Invoke-Expression -Command $cmd
        }
    } catch {
        Write-Error "Failed to take ownership: $_"
    }
}

Function Invoke-TakeOwnershipWindowsApps {
    try {
        sudo takeown /f "$Env:PROGRAMFILES\WindowsApps" /r /d y
    } catch {
        Write-Error "Failed to take ownership of WindowsApps: $_"
    }
}
