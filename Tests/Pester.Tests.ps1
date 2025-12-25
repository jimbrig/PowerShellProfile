<#
    .SYNOPSIS
        Main Pester test runner for PowerShell profile tests
    .DESCRIPTION
        Runs all Pester tests from configured paths (System, Profile) and optionally
        generates HTML reports using reportgenerator if available.
    .EXAMPLE
        .\Pester.Tests.ps1
        Runs all tests with default configuration.
    .EXAMPLE
        .\Pester.Tests.ps1 -Verbose
        Runs all tests with verbose output.
#>
[CmdletBinding()]
param()

# ensure test results directory exists
$TestResultsPath = Join-Path -Path $PSScriptRoot -ChildPath 'TestResults'
if (-not (Test-Path -Path $TestResultsPath)) {
    New-Item -Path $TestResultsPath -ItemType Directory -Force | Out-Null
}

# load and run pester configuration
$PesterConfigData = Import-PowerShellDataFile -Path "$PSScriptRoot\PesterConfig.psd1"
$PesterConfig = New-PesterConfiguration -HashTable $PesterConfigData

Write-Verbose 'Running Pester tests...'
$Result = Invoke-Pester -Configuration $PesterConfig

# generate html report if reportgenerator is available
if (Get-Command reportgenerator -ErrorAction SilentlyContinue) {
    $ReportPath = Join-Path -Path $PSScriptRoot -ChildPath 'Reports'
    $Results = Get-ChildItem -Path $TestResultsPath -Filter '*.xml' -File

    if ($Results.Count -gt 0) {
        Write-Host 'Generating HTML report...'
        $ReportCmd = "reportgenerator -reports:$($TestResultsPath)\*.xml -targetdir:$ReportPath -reporttypes:Html"
        Invoke-Expression $ReportCmd
        Write-Host "Report generated at: $ReportPath"
    } else {
        Write-Host 'No test results found to generate report.'
    }
} else {
    Write-Debug 'reportgenerator command not found; skipping report generation.'
}

# return result for pipeline usage
$Result
