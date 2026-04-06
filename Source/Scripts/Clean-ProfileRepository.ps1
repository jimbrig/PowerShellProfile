#Requires -Version 7
<#
.SYNOPSIS
    Cleans up unneeded files and folders in the PowerShell profile repository.

.DESCRIPTION
    This script identifies and removes temporary files, backup files, cache files, 
    old logs, and other unneeded files from the PowerShell profile repository to 
    keep it clean and optimized.

.PARAMETER Force
    Forces removal without confirmation prompts.

.PARAMETER MoveToTemp
    Move potentially useful files to Temp/ folder instead of deleting them.

.EXAMPLE
    .\Clean-ProfileRepository.ps1 -WhatIf
    Shows what files would be moved or removed.

.EXAMPLE
    .\Clean-ProfileRepository.ps1 -Force
    Removes all identified files without confirmation.

.EXAMPLE
    .\Clean-ProfileRepository.ps1 -MoveToTemp
    Moves potentially useful files to Temp/ folder for later review.

.NOTES
    Author: Jimmy Briggs <jimmy.briggs@jimbrig.com>
    Date: June 11, 2025
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [switch]$MoveToTemp
)

$RepositoryRoot = $PSScriptRoot | Split-Path
$TempFolder = Join-Path $RepositoryRoot "Temp"

# Ensure Temp folder exists if using MoveToTemp
if ($MoveToTemp -and -not (Test-Path $TempFolder)) {
    New-Item -Path $TempFolder -ItemType Directory -Force | Out-Null
    Write-Host "Created Temp folder: $TempFolder" -ForegroundColor Green
}
Write-Host "Cleaning PowerShell Profile Repository: $RepositoryRoot" -ForegroundColor Green

# Define patterns for files to move to Temp (potentially useful)
$FilePatternsToMove = @(
    # Backup files that might be useful
    "*.bak", "*.backup"
    
    # Old configuration files
    "*.old", "*_old*"
    
    # Archive files
    "*.archive"
    
    # Duplicate files with copy in name
    "*copy*", "*Copy*", "*duplicate*"
)

# Define patterns for files to definitely remove
$FilePatternsToRemove = @(
    # Temporary files
    "*.tmp", "*.temp", "*~"
    
    # Cache files
    "*cache*", "*.cache"
    
    # Log files (older than 30 days)
    "*.log"
    
    # VS Code temporary files
    ".vscode-*"
    
    # PowerShell temporary files
    "*.ps1xml.tmp", "*.format.ps1xml.tmp"
    
    # Windows desktop.ini files
    "desktop.ini"
    
    # Git temporary files
    "*.orig", "*.rej"
    
    # Module cache files
    "modulefast_cache.ps1"
)

# Define folders to move to Temp (potentially useful)
$FoldersToMove = @(
    "_backup"
    "_old" 
    "_archive"
    "Archive"
    "Backup"
    "Old"
)

# Define folders to clean up or remove if empty
$FoldersToClean = @(
    "Temp"
    "_backup"
    "_old" 
    "_archive"
    "cache"
    ".tmp"
)

# Files to definitely keep (whitelist)
$FilesToKeep = @(
    "*.ps1", "*.psm1", "*.psd1", "*.md", "*.yml", "*.yaml", 
    "*.json", "*.xml", "*.csv", "*.txt", "LICENSE", "*.config"
)

function Move-FilesToTemp {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string[]]$Paths,
        [string]$Description,
        [string]$TempFolder,
        [switch]$Force
    )
    
    if ($Paths.Count -eq 0) {
        Write-Host "  No $Description found" -ForegroundColor Gray
        return
    }
    
    Write-Host "  Found $($Paths.Count) $Description to move to Temp/" -ForegroundColor Yellow
    
    foreach ($path in $Paths) {
        if ($WhatIf) {
            Write-Host "    Would move to Temp/: $path" -ForegroundColor Cyan
        } else {
            try {
                $relativePath = [System.IO.Path]::GetRelativePath($RepositoryRoot, $path)
                $tempPath = Join-Path $TempFolder $relativePath
                $tempDir = Split-Path $tempPath -Parent
                
                if (-not (Test-Path $tempDir)) {
                    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
                }
                
                if ($Force -or $PSCmdlet.ShouldProcess($path, "Move to Temp")) {
                    Move-Item -Path $path -Destination $tempPath -Force -ErrorAction Stop
                    Write-Host "    Moved to Temp/: $relativePath" -ForegroundColor Green
                }
            } catch {
                Write-Warning "    Failed to move $path`: $_"
            }
        }
    }
}

function Remove-FilesSafely {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string[]]$Paths,
        [string]$Description,
        [switch]$Force
    )
    
    if ($Paths.Count -eq 0) {
        Write-Host "  No $Description found" -ForegroundColor Gray
        return
    }
    
    Write-Host "  Found $($Paths.Count) $Description" -ForegroundColor Yellow
    
    foreach ($path in $Paths) {
        if ($WhatIf) {
            Write-Host "    Would remove: $path" -ForegroundColor Cyan
        } else {
            try {
                if ($Force -or $PSCmdlet.ShouldProcess($path, "Remove")) {
                    Remove-Item -Path $path -Force -Recurse -ErrorAction Stop
                    Write-Host "    Removed: $path" -ForegroundColor Red
                }
            } catch {
                Write-Warning "    Failed to remove $path`: $_"
            }
        }
    }
}

Write-Host "`nStarting repository cleanup..." -ForegroundColor Cyan

# 1. Move potentially useful files to Temp/ or remove temporary files
if ($MoveToTemp) {
    Write-Host "`n1. Moving potentially useful files to Temp/..." -ForegroundColor Yellow
    $filesToMove = @()
    foreach ($pattern in $FilePatternsToMove) {
        $filesToMove += Get-ChildItem -Path $RepositoryRoot -Recurse -Include $pattern -File -Force -ErrorAction SilentlyContinue
    }
    
    # Filter out files we want to keep and remove duplicates
    $filesToMove = $filesToMove | Where-Object { 
        $file = $_
        $keep = $false
        foreach ($keepPattern in $FilesToKeep) {
            if ($file.Name -like $keepPattern) {
                $keep = $true
                break
            }
        }
        -not $keep
    } | Sort-Object FullName -Unique
    
    Move-FilesToTemp -Paths ($filesToMove | ForEach-Object { $_.FullName }) -Description "potentially useful files" -TempFolder $TempFolder -Force:$Force
    
    # Move potentially useful folders
    $foldersToMove = Get-ChildItem -Path $RepositoryRoot -Directory -Force -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -in $FoldersToMove }
    
    Move-FilesToTemp -Paths ($foldersToMove | ForEach-Object { $_.FullName }) -Description "potentially useful folders" -TempFolder $TempFolder -Force:$Force
}

Write-Host "`n2. Cleaning temporary and backup files..." -ForegroundColor Yellow
$tempFiles = @()
foreach ($pattern in $FilePatternsToRemove) {
    $tempFiles += Get-ChildItem -Path $RepositoryRoot -Recurse -Include $pattern -File -Force -ErrorAction SilentlyContinue
}

# Filter out files we want to keep and remove duplicates
$tempFiles = $tempFiles | Where-Object { 
    $file = $_
    $keep = $false
    foreach ($keepPattern in $FilesToKeep) {
        if ($file.Name -like $keepPattern) {
            $keep = $true
            break
        }
    }
    -not $keep
} | Sort-Object FullName -Unique

Remove-FilesSafely -Paths ($tempFiles | ForEach-Object { $_.FullName }) -Description "temporary/backup files" -Force:$Force

# 3. Remove old log files (older than 30 days)
Write-Host "`n3. Cleaning old log files..." -ForegroundColor Yellow
$oldLogFiles = Get-ChildItem -Path $RepositoryRoot -Recurse -Include "*.log" -File -Force -ErrorAction SilentlyContinue | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }

Remove-FilesSafely -Paths ($oldLogFiles | ForEach-Object { $_.FullName }) -Description "old log files (>30 days)" -Force:$Force

# 4. Clean up specific cache files
Write-Host "`n4. Cleaning PowerShell cache files..." -ForegroundColor Yellow
$cacheFiles = @()

# ModuleFast cache
$moduleFastCache = Join-Path $env:TEMP "modulefast_cache.ps1"
if (Test-Path $moduleFastCache) {
    $cacheFiles += $moduleFastCache
}

# PowerShell module cache
$psModuleCache = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\PowerShell\ModuleAnalysisCache"
if (Test-Path $psModuleCache) {
    $cacheFiles += $psModuleCache
}

Remove-FilesSafely -Paths $cacheFiles -Description "PowerShell cache files" -Force:$Force

# 5. Remove empty directories
Write-Host "`n5. Removing empty directories..." -ForegroundColor Yellow
$emptyDirs = Get-ChildItem -Path $RepositoryRoot -Recurse -Directory -Force | 
    Where-Object { 
        $_.Name -in $FoldersToClean -or
        (Get-ChildItem -Path $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0 
    } |
    Sort-Object FullName -Descending

Remove-FilesSafely -Paths ($emptyDirs | ForEach-Object { $_.FullName }) -Description "empty directories" -Force:$Force

# 6. Identify potential duplicate files (same name, different locations)
Write-Host "`n6. Identifying potential duplicate files..." -ForegroundColor Yellow
$allFiles = Get-ChildItem -Path $RepositoryRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @(".ps1", ".psm1", ".psd1") }

$duplicates = $allFiles | Group-Object Name | Where-Object { $_.Count -gt 1 }

if ($duplicates) {
    Write-Host "  Found potential duplicates:" -ForegroundColor Yellow
    foreach ($group in $duplicates) {
        Write-Host "    $($group.Name):" -ForegroundColor Cyan
        foreach ($file in $group.Group) {
            $relativePath = $file.FullName.Replace($RepositoryRoot, "")
            Write-Host "      $relativePath" -ForegroundColor White
        }
    }
    Write-Host "  Review these manually to determine which to keep" -ForegroundColor Yellow
}

# 7. Repository size report
Write-Host "`n7. Repository size analysis..." -ForegroundColor Yellow
$totalSize = (Get-ChildItem -Path $RepositoryRoot -Recurse -File -Force -ErrorAction SilentlyContinue | 
    Measure-Object -Property Length -Sum).Sum

$folderSizes = Get-ChildItem -Path $RepositoryRoot -Directory | ForEach-Object {
    $size = (Get-ChildItem -Path $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | 
        Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        Folder = $_.Name
        SizeMB = [math]::Round($size / 1MB, 2)
        SizeGB = [math]::Round($size / 1GB, 3)
    }
} | Sort-Object SizeMB -Descending

Write-Host "  Total repository size: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host "  Largest folders:" -ForegroundColor Cyan
$folderSizes | Select-Object -First 10 | Format-Table -AutoSize

# 8. Recommendations
Write-Host "`n8. Cleanup recommendations:" -ForegroundColor Green
Write-Host "  ✓ Consider archiving old documentation in Docs/ folder" -ForegroundColor White
Write-Host "  ✓ Review Tests/ folder for outdated test files" -ForegroundColor White
Write-Host "  ✓ Check Profile/Functions/ for unused functions" -ForegroundColor White
Write-Host "  ✓ Review Scripts/ folder for scripts that could be moved to modules" -ForegroundColor White
Write-Host "  ✓ Consider using .gitignore to prevent temporary files from being tracked" -ForegroundColor White

# Show summary
Write-Host "`nCleanup Summary:" -ForegroundColor Green
Write-Host "- Files moved to Temp: $($movedFiles.Count)" -ForegroundColor Yellow
Write-Host "- Files removed: $($removedFiles.Count)" -ForegroundColor Red
Write-Host "- Folders removed: $($removedFolders.Count)" -ForegroundColor Red

if ($movedFiles.Count -gt 0) {
    Write-Host "`nFiles moved to Temp folder (review and delete manually if not needed):" -ForegroundColor Cyan
    $movedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
}

if ($removedFiles.Count -gt 0 -or $removedFolders.Count -gt 0) {
    Write-Host "`nItems permanently removed:" -ForegroundColor Red
    $removedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    $removedFolders | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
}

Write-Host "`nProfile repository cleanup completed!" -ForegroundColor Green

<#
.EXAMPLE
    # Preview what would be cleaned up (WhatIf mode)
    .\Scripts\Clean-ProfileRepository.ps1 -WhatIf

.EXAMPLE
    # Move potentially useful files to Temp folder instead of deleting
    .\Scripts\Clean-ProfileRepository.ps1 -MoveToTemp

.EXAMPLE
    # Clean up with confirmation prompts
    .\Scripts\Clean-ProfileRepository.ps1 -Confirm

.EXAMPLE
    # Silent cleanup without prompts
    .\Scripts\Clean-ProfileRepository.ps1 -Force

.EXAMPLE
    # Move to Temp and force without prompts
    .\Scripts\Clean-ProfileRepository.ps1 -MoveToTemp -Force
#>
