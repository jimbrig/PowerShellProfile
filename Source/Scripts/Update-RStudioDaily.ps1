#Requires -Version 5.1
<#
.SYNOPSIS
    Update RStudio to the latest daily build from dailies.rstudio.com.

.DESCRIPTION
    Resolves the latest Windows RStudio daily build URL using multiple fallback
    strategies, compares the build number against the currently installed version,
    and performs a silent NSIS install if a newer build is available.

    Designed to complement rig (which manages R itself) — this script handles
    only RStudio. No elevation needed; RStudio installs per-user to
    %LOCALAPPDATA%\Programs\RStudio.

.PARAMETER Force
    Skip version comparison and always download + install.

.PARAMETER NoCleanup
    Keep the downloaded installer in $env:TEMP after installation.

.PARAMETER DownloadOnly
    Fetch the installer but do not run it.

.PARAMETER RegisterTask
    Register a Windows Scheduled Task to run this script daily at 09:00.
    Save the script to a permanent path first; the task uses $PSCommandPath.

.EXAMPLE
    pwsh -File Update-RStudioDaily.ps1

.EXAMPLE
    pwsh -File Update-RStudioDaily.ps1 -Force -Verbose

.EXAMPLE
    pwsh -File Update-RStudioDaily.ps1 -DownloadOnly

.EXAMPLE
    pwsh -File Update-RStudioDaily.ps1 -RegisterTask

.NOTES
    Author  : Jimmy Briggs / No Clocks, LLC
    Requires: PowerShell 5.1+ or pwsh 7+
    Source  : https://dailies.rstudio.com
    Posit AI: https://docs.posit.co/posit-ai/user/getting-started/
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force,
    [switch]$NoCleanup,
    [switch]$DownloadOnly,
    [switch]$RegisterTask
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$script:DAILIES_URL = 'https://dailies.rstudio.com'
$script:S3_BASE = 'https://s3.amazonaws.com/rstudio-ide-build/electron/windows'

# ── Console helpers ────────────────────────────────────────────────────────────
function Write-Step ([string]$Msg) { Write-Host "  ==> $Msg"  -ForegroundColor Cyan }
function Write-OK   ([string]$Msg) { Write-Host "  [OK] $Msg" -ForegroundColor Green }
function Write-Warn ([string]$Msg) { Write-Host "  [!!] $Msg" -ForegroundColor Yellow }
function Write-Info ([string]$Msg) { Write-Host "       $Msg" -ForegroundColor DarkGray }

# ── 1. Read installed version from registry ────────────────────────────────────
function Get-InstalledRStudio {
    $roots = @(
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($root in $roots) {
        $hit = Get-ItemProperty $root -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match '^RStudio(\s|$)' } |
        Select-Object -First 1
        if ($hit) {
            return [PSCustomObject]@{
                DisplayVersion  = $hit.DisplayVersion
                InstallLocation = $hit.InstallLocation
            }
        }
    }
    return $null
}

# ── 2. Resolve the latest Windows .exe installer URL (multi-strategy) ─────────
function Resolve-LatestInstallerUrl {
    [OutputType([string])]

    # Strategy A: try known redirect-link URL candidates
    $redirectCandidates = @(
        "$script:DAILIES_URL/rstudio/latest/desktop/windows",
        "$script:DAILIES_URL/latest/rstudio/open-source/desktop/windows/x86_64",
        "$script:DAILIES_URL/rstudio/latest/electron/windows"
    )
    foreach ($url in $redirectCandidates) {
        try {
            $r = Invoke-WebRequest -Uri $url -MaximumRedirection 10 `
                -UseBasicParsing -ErrorAction Stop
            $exe = $r.Links.href |
            Where-Object { $_ -match 'rstudio-ide-build/electron/windows/RStudio-[\d\.\-]+\.exe$' } |
            Select-Object -First 1
            if ($exe) { Write-Verbose "Strategy A hit ($url): $exe"; return $exe }
        } catch {
            Write-Verbose "Strategy A miss ($url): $_"
        }
    }

    # Strategy B: scrape main dailies page for direct S3 link
    Write-Verbose "Strategy B: scraping $script:DAILIES_URL..."
    $page = Invoke-WebRequest -Uri $script:DAILIES_URL -UseBasicParsing
    $exe = $page.Links.href |
    Where-Object { $_ -match 'rstudio-ide-build/electron/windows/RStudio-[\d\.\-]+\.exe$' } |
    Select-Object -First 1
    if ($exe) { Write-Verbose "Strategy B hit: $exe"; return $exe }

    # Strategy C: follow /version/<ver> detail page, extract link from there
    Write-Verbose 'Strategy C: looking for /version/ link...'
    $verLink = $page.Links.href |
    Where-Object { $_ -match '^/version/[\d\.+]+$' } |
    Select-Object -First 1
    if ($verLink) {
        $detailUrl = $script:DAILIES_URL + $verLink
        Write-Verbose "  Fetching detail page: $detailUrl"
        $detail = Invoke-WebRequest -Uri $detailUrl -UseBasicParsing
        $exe = $detail.Links.href |
        Where-Object { $_ -match 'rstudio-ide-build/electron/windows/RStudio-[\d\.\-]+\.exe$' } |
        Select-Object -First 1
        if ($exe) { Write-Verbose "Strategy C hit (links): $exe"; return $exe }

        $fnMatch = [regex]::Match($detail.RawContent,
            'RStudio-([\d]+\.[\d]+\.[\d]+-(?:daily-)?\d+)\.exe')
        if ($fnMatch.Success) {
            $exe = "$script:S3_BASE/RStudio-$($fnMatch.Groups[1].Value).exe"
            Write-Verbose "Strategy C hit (construct): $exe"; return $exe
        }
    }

    # Strategy D: regex filename from raw main-page HTML
    Write-Verbose 'Strategy D: regex raw content for RStudio-*.exe...'
    $rawMatch = [regex]::Match($page.RawContent,
        'RStudio-([\d]+\.[\d]+\.[\d]+-(?:daily-)?\d+)\.exe')
    if ($rawMatch.Success) {
        $exe = "$script:S3_BASE/RStudio-$($rawMatch.Groups[1].Value).exe"
        Write-Verbose "Strategy D hit: $exe"; return $exe
    }

    throw (
        "All URL resolution strategies failed.`n" +
        "Please visit $script:DAILIES_URL and download the Windows installer manually."
    )
}

# ── 3. Parse version string from installer filename ────────────────────────────
function Get-VersionFromUrl ([string]$Url) {
    if ($Url -match 'RStudio-([\d\.]+(?:-daily)?-\d+)\.exe') { return $Matches[1] }
    if ($Url -match 'RStudio-([\d\.]+)\.exe') { return $Matches[1] }
    return 'unknown'
}

# ── 4. Version comparison ──────────────────────────────────────────────────────
#   Registry  "2026.04.0+364"       -> base=2026.04.0  build=364
#   URL       "2026.04.0-daily-364" -> base=2026.04.0  build=364
#   Old URL   "2023.09.0-463"       -> base=2023.09.0  build=463
function ConvertTo-VersionInfo ([string]$Raw) {
    $base = $Raw -replace '\+\d+$', ''
    $base = $base -replace '-daily-\d+$', ''
    $base = $base -replace '-\d+$', ''
    $build = if ($Raw -match '[+\-](\d+)$') { [int]$Matches[1] } else { 0 }
    return [PSCustomObject]@{ Base = $base; Build = $build }
}

function Test-NeedsUpdate ([string]$InstalledVer, [string]$LatestUrl) {
    $l = ConvertTo-VersionInfo (Get-VersionFromUrl $LatestUrl)
    $c = ConvertTo-VersionInfo $InstalledVer
    try {
        $vl = [version]($l.Base -replace '[^\d\.]', '.')
        $vc = [version]($c.Base -replace '[^\d\.]', '.')
        if ($vl -gt $vc) { return $true }
        if ($vl -eq $vc) { return $l.Build -gt $c.Build }
        return $false
    } catch {
        Write-Verbose "Version cast failed — defaulting to update. Error: $_"
        return $true
    }
}

# ── 5. Register Windows Scheduled Task ────────────────────────────────────────
function Register-UpdateTask {
    if (-not $PSCommandPath) {
        Write-Warn '-RegisterTask requires the script to be saved to a real file path.'
        return
    }
    $action = New-ScheduledTaskAction -Execute 'pwsh.exe' `
        -Argument "-NonInteractive -WindowStyle Hidden -File `"$PSCommandPath`""
    $trigger = New-ScheduledTaskTrigger -Daily -At '09:00'
    $settings = New-ScheduledTaskSettingsSet `
        -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -MultipleInstances IgnoreNew
    Register-ScheduledTask `
        -TaskName    'Update-RStudioDaily' `
        -Action      $action `
        -Trigger     $trigger `
        -Settings    $settings `
        -Description 'Auto-update RStudio to the latest Posit daily build' `
        -RunLevel    Limited `
        -Force | Out-Null
    Write-OK "Scheduled task 'Update-RStudioDaily' registered (daily at 09:00)."
    Write-Info 'Edit in Task Scheduler (taskschd.msc).'
    Write-Info "Remove: Unregister-ScheduledTask -TaskName 'Update-RStudioDaily'"
}

# ── 6. Check whether RStudio is currently running ──────────────────────────────
function Test-RStudioRunning {
    return [bool](Get-Process -Name 'rstudio' -ErrorAction SilentlyContinue)
}

# ─────────────────────────────────────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '  RStudio Daily Build Updater' -ForegroundColor Magenta
Write-Host '  ════════════════════════════' -ForegroundColor DarkGray
Write-Host "  $script:DAILIES_URL" -ForegroundColor DarkGray
Write-Host ''

if ($RegisterTask) { Register-UpdateTask; return }

# Resolve latest
Write-Step 'Resolving latest Windows daily build...'
$latestUrl = Resolve-LatestInstallerUrl
$latestVer = Get-VersionFromUrl $latestUrl
Write-OK "Latest  : $latestVer"
Write-Info $latestUrl

# Read installed
Write-Step 'Checking installed RStudio...'
$installed = Get-InstalledRStudio
if ($installed) {
    Write-OK "Installed : $($installed.DisplayVersion)"
    if ($installed.InstallLocation) { Write-Info $installed.InstallLocation }
} else {
    Write-Warn 'RStudio not found in registry — will perform a fresh install.'
}

# Should we proceed?
$needsUpdate = $Force -or
(-not $installed) -or
(Test-NeedsUpdate $installed.DisplayVersion $latestUrl)

if (-not $needsUpdate) {
    Write-Host ''
    Write-OK 'Already on the latest build. Use -Force to reinstall.'
    Write-Host ''
    return
}

if ($Force) { Write-Warn '-Force flag set — reinstalling.' }
elseif (-not $installed) { Write-Warn 'No existing install — fresh install.' }
elseif (Test-NeedsUpdate $installed.DisplayVersion $latestUrl) { Write-Warn 'Newer build available — updating.' }

if (Test-RStudioRunning) {
    Write-Host ''
    Write-Warn 'RStudio is currently running. The installer will ask you to close it.'
    Write-Host ''
}

# Installer path in $env:TEMP
$fileName = "RStudio-$latestVer.exe"
$installerPath = Join-Path $env:TEMP $fileName

if (Test-Path $installerPath) {
    Write-Info "Reusing cached installer: $installerPath"
} else {
    Write-Step "Downloading $fileName..."
    try {
        $head = Invoke-WebRequest -Uri $latestUrl -Method Head -UseBasicParsing
        $bytes = [long]($head.Headers['Content-Length'][0])
        Write-Info "Size: ~$([math]::Round($bytes / 1MB, 0)) MB"
    } catch {
        Write-Info 'Size: unavailable'
    }
    Invoke-WebRequest -Uri $latestUrl -OutFile $installerPath -UseBasicParsing
    Write-OK "Saved: $installerPath"
}

if ($DownloadOnly) {
    Write-Host ''
    Write-OK "-DownloadOnly: installer ready at $installerPath"
    Write-Host ''
    return
}

# Silent NSIS install — /S flag, no UAC needed for per-user install
if ($PSCmdlet.ShouldProcess("RStudio $latestVer", 'Silent install (/S)')) {
    Write-Step 'Installing silently (30-60 seconds)...'
    $proc = Start-Process -FilePath $installerPath -ArgumentList '/S' -PassThru -Wait
    if ($proc.ExitCode -ne 0) {
        Write-Error "Installer exited with code $($proc.ExitCode). Try: $installerPath"
        exit $proc.ExitCode
    }
    Write-OK 'Installation complete.'
}

if (-not $NoCleanup) {
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    Write-Info "Installer removed from $env:TEMP."
}

Write-Host ''
Write-OK "RStudio $latestVer is ready!"
Write-Info 'First launch: View > Show/Hide Sidebar -> Install Posit AI -> Sign In.'
Write-Host ''
