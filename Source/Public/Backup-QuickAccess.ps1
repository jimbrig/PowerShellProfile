Function Backup-QuickAccess {
    <#
        .SYNOPSIS
            Backs up the Quick Access configuration file.
        .DESCRIPTION
            This function creates a backup of the Quick Access configuration file located in the user's AppData folder.
        .PARAMETER BackupPath
            The path where the backup file will be saved. Defaults to "$env:USERPROFILE\Documents\QuickAccessBackups".
        .EXAMPLE
            Backup-QuickAccess -BackupPath "C:\Backups"
        .INPUTS
            None
        .OUTPUTS
            None
    #>
    [CmdletBinding()]
    Param (
        [Parameter()]
        [string]$BackupPath = "$env:USERPROFILE\Documents\QuickAccessBackups"
    )

    Begin {
        Write-Verbose "[BEGIN]: Backup-QuickAccess"
        $QATFile = "f01b4d95cf55d32a.automaticDestinations-ms"
        $QATFilePath = Join-Path -Path $env:APPDATA -ChildPath "Microsoft\Windows\Recent\AutomaticDestinations\$QATFile"
        if (-Not (Test-Path -Path $QATFilePath)) {
            Write-Error "Quick Access file not found at '$QATFilePath'."
            return
        }
        if (-Not (Test-Path -Path $BackupPath)) {
            Write-Verbose "Creating backup directory at '$BackupPath'."
            New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
            Write-Host "Backup directory created at '$BackupPath'." -ForegroundColor Yellow
        }
        $BackupFile = "QuickAccessBackup_$((Get-Date).ToString('yyyyMMdd_HHmmss')).automaticDestinations-ms"
        $BackupFilePath = Join-Path -Path $BackupPath -ChildPath $BackupFile
    }

    Process {
        Write-Verbose "[PROCESS]: Backup-QuickAccess"
        try {
            Copy-Item -Path $QATFilePath -Destination $BackupFilePath -Force
            Write-Host "Successfully backed up Quick Access to '$BackupFilePath'." -ForegroundColor Green
        } catch {
            Write-Error "Failed to back up Quick Access to '$BackupFilePath'."
        }
    }

    End {
        Write-Verbose "[END]: Backup-QuickAccess"
    }

}
