Function Invoke-ProfileReload {
    & $PROFILE
}

Function Get-PublicIP {
    (Invoke-WebRequest 'http://ifconfig.me/ip' ).Content
}

Function Get-Timestamp {
    Get-Date -Format u
}

Function Get-RandomPassword {
    $length = 16
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+'
    -join ((0..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

Function Update-WinGet {
    Params(
        [Switch]$Admin,
        [Switch]$Interactive
    )

    if (Get-PSResource -Name WingetTools -ErrorAction SilentlyContinue) {
        Import-Module WingetTools
    } else {
        Install-Module WingetTools -Force -SkipPublisherCheck
    }

    if ($Admin) {
    } else {
        winget upgrade --all
    }
}
Function Update-Chocolatey {}
Function Update-Scoop {}
Function Update-R {}
Function Update-Python {}

Function Update-Node {}

Function Update-Pip {}
Function Update-Windows {}

Function Mount-DevDrive {
    if (-not(Test-Path -Path 'X:\')) {

        if (Get-PSDrive -Name 'Dev' -ErrorAction SilentlyContinue) {
            Write-Host 'Mapped PSDrive for  DevDrive already exists. Aborting Mounting...' -ForegroundColor Yellow
            Return
        } else {

            $cmd = "sudo powershell.exe -Command 'Mount-VHD -Path I:\DevDrive\DevDrive.vhdx'"

            try {
                Write-Verbose 'Mounting DevDrive...'
                Invoke-Expression -Command $cmd
            } catch {
                Write-Warning 'Failed to mount DevDrive...'
            }

            Write-Verbose 'Creating DevDrive PSDrive...'
            New-PSDrive -Name 'Dev' -PSProvider FileSystem -Root 'X:\' -Scope Global
        }
    }
}

Function Set-LocationDesktop {
    Set-Location -Path "$env:USERPROFILE\Desktop"
}

Function Set-LocationDownloads {
    Set-Location -Path "$env:USERPROFILE\Downloads"
}

Function Set-LocationDocuments {
    Set-Location -Path "$env:USERPROFILE\Documents"
}

Function Set-LocationPictures {
    Set-Location -Path "$env:USERPROFILE\Pictures"
}

Function Set-LocationMusic {
    Set-Location -Path "$env:USERPROFILE\Music"
}

Function Set-LocationVideos {
    Set-Location -Path "$env:USERPROFILE\Videos"
}

Function Set-LocationDevDrive {
    Set-Location -Path 'Dev:'
}

Function cd... {
    Set-Location -Path '..\..'
}

Function cd.... {
    Set-Location -Path '..\..\..'
}

Function Get-MD5Hash { Get-FileHash -Algorithm MD5 $args }

Function Get-SHA1Hash { Get-FileHash -Algorithm SHA1 $args }

Function Get-SHA256Hash { Get-FileHash -Algorithm SHA256 $args }

Function Invoke-Notepad { notepad.exe $args }


# Drive shortcuts
function HKLM: { Set-Location HKLM: }
function HKCU: { Set-Location HKCU: }
function Env: { Set-Location Env: }

Function Invoke-Admin {
    if ($args.Count -gt 0) {
        $argList = "& '" + $args + "'"
        Start-Process "$PSHOME\pwsh.exe" -Verb runAs -ArgumentList $argList
    } else {
        Start-Process "$PSHOME\pwsh.exe" -Verb RunAs
    }
}

Function Edit-PSProfile {
    $cmd = "$Env:Editor $PROFILE.CurrentUserAllHosts"
    Invoke-Expression -Command $cmd
}

Function Edit-PSProfileProject {
    if (-not($ProfileRootPath)) {
        Write-Warning 'ProfileRootPath not found.'
        $Global:ProfileRootPath = Split-Path -Path $PROFILE -Parent
    }

    $cmd = "$Env:Editor $ProfileRootPath"
    Invoke-Expression -Command $cmd
}

Function Invoke-WingetUpdate {
    Import-Module WingetTools

}

Function Invoke-TakeOwnership {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [String]$Path
    )

    $cmd = "sudo takeown /f '$Path' /r /d y"

    if ($WhatIfPreference) {
        Write-Host "WhatIf: $cmd" -ForegroundColor Yellow
    } else {
        Invoke-Expression -Command $cmd
    }

}

Function Invoke-TakeOwnershipWindowsApps {
    sudo takeown /f "$Env:PROGRAMFILES\WindowsApps" /r /d y
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

}

Function Invoke-SFC {
    [CmdletBinding()]
    Param()

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
}

Function Get-SFCLogs {
    $SFCLogPath = "$Env:WinDir\Logs\CBS\CBS.log"
    if (Test-Path -Path $SFCLogPath) {
        Get-Content -Path $SFCLogPath
    } else {
        Write-Warning 'SFC Log file not found.'
    }
}

Function Invoke-CheckDisk {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ })]
        [String]$Path = 'C:'
    )

    $cmd = "sudo chkdsk $Path /f /r"

    if ($WhatIfPreference) {
        Write-Host "WhatIf: $cmd" -ForegroundColor Yellow
    } else {
        Invoke-Expression -Command $cmd
    }
}

Function Get-WinSAT {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Switch]$Formal
    )

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

}


