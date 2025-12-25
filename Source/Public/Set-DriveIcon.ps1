Function Set-DriveIcon {
    <#
    .SYNOPSIS
        Sets a custom icon for a specified drive in Windows Explorer.
    .DESCRIPTION
        Configures a custom icon for a drive by modifying the Windows registry
        under HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons.
        Requires administrator privileges to modify the registry.
    .PARAMETER DriveLetter
        The drive letter to set the icon for (e.g., 'D:' or 'D').
    .PARAMETER IconPath
        The full path to the icon file (.ico) to use for the drive.
    .NOTES
        Requires administrator privileges. Changes take effect after restarting
        Windows Explorer or logging out and back in.
    .INPUTS
        None. This command does not accept pipeline input.
    .OUTPUTS
        None.
    .EXAMPLE
        Set-DriveIcon -DriveLetter 'D:' -IconPath 'C:\Icons\drive.ico'
        Sets the icon for the D: drive to the specified icon file.
    .EXAMPLE
        Set-DriveIcon -DriveLetter 'E' -IconPath "$env:USERPROFILE\Icons\usb.ico"
        Sets the icon for the E: drive using an icon from the user's profile.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$DriveLetter,

        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$IconPath
    )

    begin {
        Write-Verbose '[BEGIN]: Set-DriveIcon'
        $driveLetter = $DriveLetter.TrimEnd(':\').ToUpper()
        $iconPath = (Resolve-Path -Path $IconPath).Path

        $regRoot = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons'
        $regPath = "$regRoot\$driveLetter"
        $regIconPath = "$regPath\DefaultIcon"
    }

    process {
        Write-Verbose '[PROCESS]: Set-DriveIcon'

        if ($PSCmdlet.ShouldProcess("Drive $driveLetter", "Set icon to '$iconPath'")) {
            try {
                if (-not (Test-Path -Path $regPath)) {
                    New-Item -Path $regPath -Force | Out-Null
                }

                if (-not (Test-Path -Path $regIconPath)) {
                    New-Item -Path $regIconPath -Force | Out-Null
                }

                Set-ItemProperty -Path $regIconPath -Name '(default)' -Value $iconPath -Force
                Write-Information "Successfully set the icon for drive $driveLetter to $iconPath."
            } catch {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new("Failed to set the icon for drive $driveLetter. $($_.Exception.Message)"),
                        'SetDriveIconFailed',
                        [System.Management.Automation.ErrorCategory]::WriteError,
                        $driveLetter
                    )
                )
            }
        }
    }

    end {
        Write-Verbose '[END]: Set-DriveIcon'
    }
}
