
<#PSScriptInfo

.VERSION 1.0.0

.GUID 8d68e1d1-ca5c-4c20-becc-549098d06a52

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS Registry Dates System Configure Formatting Tool

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
    Changes the current user's short date format via the registry to 'yyyy-MM-dd' instead of the default of 'M/d/yyyy'. 
    Useful for things like exporting from Excel to CSV and ensuring dates are formatted correctly. 
#> 
Param(
    [switch]$Backup
)

$regPath = 'HKCU:\Control Panel\International'
$regName = 'sShortDate'

$oldSetting = Get-ItemPropertyValue -Path $regPath -Name $regName
$newSetting = 'yyyy-MM-dd'

Set-ItemProperty -Path -Path $regPath -Name $regName -Value $newSetting

Write-Host "Changed registry entry for $regPath - $regName from $oldSetting to $newSetting" -ForegroundColor Yellow



