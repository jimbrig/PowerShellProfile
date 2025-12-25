---
name: Temp Functions Integration
overview: Integrate, refactor, or delete 51 temp files from Private/temp and Public/temp into the main profile structure, following naming conventions and avoiding duplicates.
todos:
  - id: delete-empty
    content: Delete 5 empty/stub files from temp folders
    status: pending
  - id: delete-dupes
    content: Delete 5 duplicate/superseded files from temp folders
    status: pending
  - id: private-logging
    content: Merge Logging-Functions.ps1 into Private/Logging.ps1
    status: pending
  - id: private-lazyload
    content: Create Private/LazyLoad.ps1 from LazyLoad-Functions.ps1
    status: pending
  - id: private-aliases
    content: Create Private/Aliases.ps1 from Import-Aliases.ps1
    status: pending
  - id: public-direct
    content: Move 16 well-formed Public functions to Source/Public
    status: pending
  - id: refactor-defender
    content: Fix typo and docs in Optimize-DefenderExclusions.ps1
    status: pending
  - id: refactor-tempfiles
    content: Rename and add docs to Remove-TempFiles.ps1
    status: pending
  - id: refactor-network
    content: Add docs to Reset-NetworkStack.ps1
    status: pending
  - id: split-navigation
    content: Split Navigation.ps1 into individual functions or keep grouped
    status: pending
  - id: split-admin
    content: Split AdminTools.ps1 into individual functions
    status: pending
  - id: split-dialog
    content: Split DialogTools.ps1 into individual functions
    status: pending
  - id: split-environment
    content: Split Environment.ps1 into individual functions
    status: pending
  - id: split-hashing
    content: Split HashingTools.ps1 into individual functions
    status: pending
  - id: move-profile-tools
    content: Move ProfileTools.ps1 as Edit-PSProfile.ps1
    status: pending
  - id: decide-allpsresources
    content: Decide on Update-AllPSResources.ps1 integration approach
    status: pending
---

# Temp Functions Integration Plan

This plan categorizes all 51 temp files and provides specific recommendations for each.---

## 1. Delete Empty/Stub Files (5 files)

These files have no content and should be removed:| File | Location | Reason ||------|----------|--------|| `Write-OperationStatus.ps1` | Private/temp | 0 lines || `Get-WifiPasswords.ps1` | Public/temp | 0 lines || `Set-PowerPlan.ps1` | Public/temp | 0 lines || `FileSystem.ps1` | Public/temp | 0 lines || `System.ps1` | Public/temp | Only stubs/placeholders |---

## 2. Delete Duplicates/Superseded (5 files)

| File | Location | Reason ||------|----------|--------|| `Invoke-ProfileReload.ps1` | Public/temp | Already exists in [Source/Public/Invoke-ProfileReload.ps1](Source/Public/Invoke-ProfileReload.ps1) || `Uninstall-DuplicatePSModules.ps1` | Public/temp | Superseded by [Remove-OldModules.ps1](Source/Public/Remove-OldModules.ps1) || `Update-PSModules.ps1` | Public/temp | Less robust than existing solutions || `Apps.ps1` | Public/temp | Duplicate of `Start-GitKraken.ps1` || `FunctionsToFinishAndSeparate.ps1` | Public/temp | Collection of duplicates already split to other files |---

## 3. Private Functions to Integrate (3 files)

### 3.1 Merge into [Source/Private/Logging.ps1](Source/Private/Logging.ps1)

- **Source**: `Logging-Functions.ps1`
- **Functions**: `Write-ProfileLog`, `Initialize-DebugLog`, `Measure-ProfileBlock`
- **Action**: Review existing `Logging.ps1` and merge or replace with these enhanced versions

### 3.2 Create: `Source/Private/LazyLoad.ps1`

- **Source**: `LazyLoad-Functions.ps1`
- **Functions**: `Register-LazyCompletion`
- **Purpose**: Helper for completion registration

### 3.3 Create: `Source/Private/Aliases.ps1`

- **Source**: `Import-Aliases.ps1`
- **Functions**: `Import-AliasFile`
- **Purpose**: Helper for loading alias files from `.ps1` or `.psd1`

---

## 4. Public Functions - Direct Integration (16 files)

These are well-formed single-function files ready for integration:| Temp File | Target Name | Notes ||-----------|-------------|-------|| `Get-PublicIP.ps1` | `Get-PublicIP.ps1` | Uses ipinfo.io API, returns structured object || `Get-PCInfo.ps1` | `Get-PCInfo.ps1` | System info via CIM || `Get-PCUptime.ps1` | `Get-PCUptime.ps1` | Uptime via CIM || `Get-WindowsBuild.ps1` | `Get-WindowsBuild.ps1` | Windows version from registry || `Get-FolderSize.ps1` | `Get-FolderSize.ps1` | Folder size with remote support || `Get-IPv4NetworkInfo.ps1` | `Get-IPv4NetworkInfo.ps1` | Network calculations || `Get-GitHubRateLimits.ps1` | `Get-GitHubRateLimits.ps1` | GitHub CLI wrapper || `Remove-GitHubWorkflowRuns.ps1` | `Remove-GitHubWorkflowRuns.ps1` | GitHub CLI wrapper || `Search-History.ps1` | `Search-History.ps1` | PSReadLine history search || `Stop-SelectedProcess.ps1` | `Stop-SelectedProcess.ps1` | Interactive process killer || `Start-RStudio.ps1` | `Start-RStudio.ps1` | App launcher || `Start-GitKraken.ps1` | `Start-GitKraken.ps1` | App launcher (use newer version) || `Update-WinGet.ps1` | `Update-WinGet.ps1` | WinGet wrapper || `Get-DuplicatePSModules.ps1` | `Get-DuplicatePSModules.ps1` | Companion to Remove-OldModules || `Remove-Application.ps1` | `Remove-Application.ps1` | Depends on Get-Applications || `Get-EnvironmentVariables.ps1` | `Get-EnvironmentVariables.ps1` | 561 lines, comprehensive env analysis |---

## 5. Public Functions - Needs Refactoring (4 files)

### 5.1 `Optimize-DefenderExclusions.ps1`

- **Issue**: Typo `Funciton` -> `Function`
- **Action**: Fix typo, add docs, move to Public

### 5.2 `Remove-TempFiles.ps1`

- **Issue**: Internal function named `Remove-AllTempFiles`, needs docs
- **Action**: Rename to match file, add proper help, move to Public

### 5.3 `Reset-NetworkStack.ps1`

- **Issue**: Missing docs, requires admin
- **Action**: Add docs and ShouldProcess, move to Public

### 5.4 `Import-Completion.ps1`

- **Issue**: Depends on `$CompletionScripts` hashtable
- **Action**: Review if needed with current completion system; may be obsolete

---

## 6. Multi-Function Files to Split (6 files)

### 6.1 `Navigation.ps1` (230 lines, ~25 functions)

Split into individual files in `Source/Public/`:

- `Set-LocationHome.ps1`
- `Set-LocationDesktop.ps1`
- `Set-LocationDownloads.ps1`
- `Set-LocationDocuments.ps1`
- `Set-LocationConfig.ps1`
- `Set-LocationOneDrive.ps1`
- `Set-LocationDotFiles.ps1`
- `Set-LocationDevDrive.ps1`
- `Set-LocationPSProfile.ps1`
- `Set-LocationWSL.ps1`
- etc.

**Alternative**: Keep as single `Navigation.ps1` in Public if preferred for organization.

### 6.2 `AdminTools.ps1` (180 lines, ~10 functions)

Split into individual files in `Source/Public/`:

- `Invoke-Admin.ps1`
- `Invoke-DISM.ps1`
- `Invoke-SFC.ps1`
- `Get-SFCLogs.ps1`
- `Invoke-CheckDisk.ps1`
- `Get-WinSAT.ps1`
- `Invoke-TakeOwnership.ps1`

### 6.3 `DialogTools.ps1` (102 lines, 3 functions)

Split into individual files in `Source/Public/`:

- `Get-Folder.ps1` (folder browser dialog)
- `Get-File.ps1` (file open dialog)
- `Invoke-Notepad.ps1` (notepad launcher)

### 6.4 `Environment.ps1` (79 lines, 7 functions)

Split into individual files in `Source/Public/`:

- `Update-Chocolatey.ps1`
- `Update-Scoop.ps1`
- `Update-Python.ps1`
- `Update-Node.ps1`
- `Update-R.ps1`
- `Update-Pip.ps1`
- `Update-Windows.ps1`

### 6.5 `HashingTools.ps1` (37 lines, 3 functions)

Split into individual files in `Source/Public/`:

- `Get-MD5Hash.ps1`
- `Get-SHA1Hash.ps1`
- `Get-SHA256Hash.ps1`

### 6.6 `ProfileTools.ps1` (38 lines, 1 function)

- Move as `Edit-PSProfile.ps1` to Public

---

## 7. Files Requiring Decision (4 files)

| File | Issue | Options ||------|-------|---------|| `Update-AllPSResources.ps1` | 966 lines, very comprehensive | A) Integrate as-is, B) Create separate module, C) Use simpler Update-WinGetPackages instead || `Get-Applications.ps1` | Short 8-line stub | Complete or delete || `Get-Printers.ps1` | Simple wrapper | Integrate or skip (trivial) || `Reset-NetworkAdapter.ps1` | Simple wrapper | Integrate or skip (trivial) |---

## Summary Statistics

| Category | Count ||----------|-------|| Delete (empty/stub) | 5 || Delete (duplicates) | 5 || Private integration | 3 || Public direct integration | 16 || Public needs refactor | 4 || Multi-function to split | 6 files (~50+ functions) || Requires decision | 4 || **Total** | **51 files** |---

## Recommended Execution Order

1. Delete empty and duplicate files first
2. Integrate Private helper functions