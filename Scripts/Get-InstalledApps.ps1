
<#PSScriptInfo

.VERSION 1.0.0

.GUID 5f90cf05-0a5e-4201-af9a-18cefffcb4e0

.AUTHOR Jimmy Briggs

.COMPANYNAME Jimmy Briggs

.COPYRIGHT Jimmy Briggs | 2022

.TAGS Apps Inventory System Registry Software

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
 PowerShell Function/Script for retrieving all installed software on a system from the Windows Registry. 

#> 
Param()

if ([IntPtr]::Size -eq 4) {
    $regpath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
}
else {
    $regpath = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
}

Get-ItemProperty $regpath | `
    .{process{if($_.DisplayName -and $_.UninstallString) { $_ } }} | `
    Select-Object DisplayName, Publisher, InstallDate, DisplayVersion, UninstallString | `
    Sort-Object DisplayName
