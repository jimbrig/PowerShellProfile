
<#PSScriptInfo

.VERSION 0.0.1

.GUID b01f0036-aaa8-4ee3-b85b-0eb94f0f10d8

.AUTHOR Jimmy Briggs

.COMPANYNAME Jimmy Briggs

.COPYRIGHT

.TAGS System Windows Restore Maintain Utility Admin

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
    PowerShell script / function for creating a new system restore point. 

.SYNOPSIS 
    Creates a new system restore point.

.PARAMETER Description
    The description of the restore point.

.PARAMETER Type
    The type of restore point. 
    Valid values are: 
        - APPLICATION_INSTALL, 
        - APPLICATION_UNINSTALL, 
        - DEVICE_DRIVER_INSTALL,
        - MODIFY_SETTINGS,
        - CANCELLED_OPERATION

.EXAMPLE 
    New-RestorePoint -Description "My new restore point" -Type APPLICATION_INSTALL
    # Creates a new restore point with the description "My new restore point" and the type APPLICATION_INSTALL.

.NOTES
    This script is based on the function `Checkpoint-Computer` from the Microsoft.PowerShell.Management module.

.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/checkpoint-computer?view=powershell-5.1

#> 

[CmdletBinding()]
Param(
    [Parameter()]
    [string]$Description = "New restore point",
    [Parameter()]
    [ValidateSet("APPLICATION_INSTALL", "APPLICATION_UNINSTALL", "DEVICE_DRIVER_INSTALL", "MODIFY_SETTINGS", "CANCELLED_OPERATION")]
    [string]$Type
)

$ErrorActionPreference = "Stop"

Function New-RestorePoint {
    <# 

.DESCRIPTION 
    PowerShell script / function for creating a new system restore point. 

.SYNOPSIS 
    Creates a new system restore point.

.PARAMETER Description
    The description of the restore point.

.PARAMETER Type
    The type of restore point. 
    Valid values are: 
        - APPLICATION_INSTALL, 
        - APPLICATION_UNINSTALL, 
        - DEVICE_DRIVER_INSTALL,
        - MODIFY_SETTINGS,
        - CANCELLED_OPERATION

.EXAMPLE 
    New-RestorePoint -Description "My new restore point" -Type APPLICATION_INSTALL
    # Creates a new restore point with the description "My new restore point" and the type APPLICATION_INSTALL.

.NOTES
    This script is based on the function `Checkpoint-Computer` from the Microsoft.PowerShell.Management module.

.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/checkpoint-computer?view=powershell-5.1

#> 
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]$Description = "New restore point",
        [Parameter()]
        [ValidateSet("APPLICATION_INSTALL", "APPLICATION_UNINSTALL", "DEVICE_DRIVER_INSTALL", "MODIFY_SETTINGS", "CANCELLED_OPERATION")]
        [string]$Type
    )

    $restorePoint = @{
        Description = $Description
        Type = $Type
    }

    $restorePoint = New-Object -TypeName System.Management.Automation.PSCustomObject -Property $restorePoint

    $restorePoint | Checkpoint-Computer -Description $Description -Type $Type

}

New-RestorePoint -Description $Description -Type $Type

# Path: Scripts\New-RestorePoint.ps1
