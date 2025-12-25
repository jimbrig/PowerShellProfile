function Block-WUDriverUpdates {
    # Disable driver updates via Windows Update
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Force
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' `
        -Name 'ExcludeWUDriversInQualityUpdate' -Type DWord -Value 1
    Write-Host 'Blocked Windows Update from installing driver updates.'
}

function Backup-CurrentDrivers {
    param([string]$BackupPath = 'C:\DriverBackup')
    Export-WindowsDriver -Online -Destination $BackupPath
    Write-Host "All current system drivers exported to $BackupPath."
}

function Install-OEMDriver {
    param([string]$InfPath)
    pnputil /add-driver $InfPath /install
    Write-Host "Installed driver: $InfPath"
}

function Remove-GhostDrivers {
    # Removes all non-present (ghost) devices except critical system ones
    $ghosts = Get-PnpDevice | Where-Object { $_.Status -eq 'Unknown' -and $_.Present -eq $false }
    foreach ($dev in $ghosts) {
        try {
            Write-Host "Removing ghost device: $($dev.FriendlyName)"
            Remove-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false
        } catch {
            Write-Warning "Could not remove $($dev.FriendlyName): $_"
        }
    }
}

function Update-DriversFromLocalRepo {
    param([string]$RepoPath)
    $infs = Get-ChildItem -Path $RepoPath -Filter *.inf -Recurse
    foreach ($inf in $infs) {
        pnputil /add-driver $inf.FullName /install
    }
    Write-Host "Installed all drivers from $RepoPath."
}

Export-ModuleMember -Function *  # Expose all functions
