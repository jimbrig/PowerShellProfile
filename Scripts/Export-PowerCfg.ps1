
<#PSScriptInfo

.VERSION 1.0

.GUID 87e26661-7ca7-469b-badd-ab9d8e1e6205

.AUTHOR Jimmy Briggs <jimmy.briggs@jimbrig.com>

.COMPANYNAME

.COPYRIGHT Jimmy Briggs | 2023

.TAGS PowerShell,PowerCfg,PowerProfiles,Windows,System,Administration

.LICENSEURI https://gist.github.com/jimbrig/d3d9a1af7abaa5eff9d7cf689e7f8ef4

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

  # 1.1 [2020-03-01]

  - Added support for exporting all PowerCfg Profiles

  # 1.0 [2020-03-01]

  - Initial Release


.PRIVATEDATA

#>

<#

.DESCRIPTION
 Export PowerCfg Profiles

.PARAMETER ConfigName
    Name of the PowerCfg Profile to Export. Default is "All" which will export all profiles.

.PARAMETER OutputPath
    Path to export PowerCfg Profiles to. Default is "$PWD\PowerProfiles".

.EXAMPLE
    Export-PowerCfg -ConfigName "Balanced" -OutputPath "$HOME\Desktop\PowerProfiles"

    # Export the "Balanced" PowerCfg Profile to the Desktop.

.EXAMPLE
    Export-PowerCfg -ConfigName "All" -OutputPath "$HOME\Desktop\PowerProfiles"

    # Export all PowerCfg Profiles to the Desktop.

.INPUTS
    None

.OUTPUTS
    Exported PowerCfg Profiles

.NOTES
    List of available profiles:
        - Balanced
        - High Performance
        - Power Saver
        - Ultimate Performance

.LINK
    - https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options
    - https://learn.microsoft.com/en-us/windows-hardware/customize/power-settings/configure-power-settings
    - https://learn.microsoft.com/en-us/windows-hardware/customize/power-settings/update-power-settings
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("All", "Balanced", "High Performance", "Power Saver", "Ultimate Performance")]
    [string]$ConfigName = "All",
    [Parameter(Mandatory = $false, Position = 1)]
    [string]$OutputPath = "$PWD\PowerProfiles"
)


# Get PowerCfg GUIDs
$PowerCfg = powercfg.exe /list
$PowerCfgGUIDs = $PowerCfg | Select-String -Pattern "Power Scheme GUID:" | `
    ForEach-Object { $_.ToString().Split(":")[1].Trim() } | `
    ForEach-Object { $_.ToString().Split("(")[0].Trim() }

# Get PowerCfg Names
$PowerCfgNames = $PowerCfg | Select-String -Pattern "Power Scheme GUID:" | `
    ForEach-Object { $_.ToString().Split(":")[1].Trim() } | `
    ForEach-Object { $_.ToString().Split("(")[1].Trim() } | `
    ForEach-Object { $_.ToString().Split(")")[0].Trim() }

# Check OutputPath
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory
}

# Export PowerCfg
if ($ConfigName -eq "All") {
    $PowerCfgGUIDs | ForEach-Object {
        $PowerCfgName = $PowerCfgNames[$PowerCfgGUIDs.IndexOf($_)]
        $PowerCfgPath = "$OutputPath\$PowerCfgName.xml"
        powercfg.exe /export $PowerCfgPath $_
    }
}
else {
    $PowerCfgGUIDs | ForEach-Object {
        $PowerCfgName = $PowerCfgNames[$PowerCfgGUIDs.IndexOf($_)]
        if ($PowerCfgName -eq $ConfigName) {
            $PowerCfgPath = "$OutputPath\$PowerCfgName.xml"
            powercfg.exe /export $PowerCfgPath $_
        }
    }
}

