# PowerShell Modules

> [!NOTE]
> *This folder is the default location for all installed PowerShell Core modules for the current user.*

## Contents

<!-- TOC -->

- [PowerShell Modules](#powershell-modules)
  - [Contents](#contents)
  - [Overview](#overview)
  - [Module Management](#module-management)
    - [Configuration and Backup](#configuration-and-backup)
  - [Modules](#modules)
    - [Notes](#notes)

<!-- /TOC -->

## Overview

This document provides a comprehensive overview of PowerShell Core modules installed in my environment.

While these modules are excluded from version control (`.gitignore`), they are essential for my daily workflows.

## Module Management

The profile manages modules using configuration files and scripts to ensure consistency across environments.

### Configuration and Backup

- **Configuration Files**:
  - [modules.json](https://github.com/jimbrig/PowerShell/blob/main/Modules/modules.json)
  - [modules.yml](https://github.com/jimbrig/PowerShell/blob/main/Modules/modules.yml)
- **Management Scripts**:
  - [modules.ps1](https://github.com/jimbrig/PowerShell/blob/main/Modules/modules.ps1) - Module backup and management
  - [Remove-OldModules.ps1](https://github.com/jimbrig/PowerShell/blob/main/Modules/Remove-OldModules.ps1) - Cleanup script

## Modules

<!-- BEGIN_MODULES -->
- **Benchpress** (1.3.8)
- **BuildHelpers** (2.0.16)
- **Cobalt** (0.4.0)
- **CompletionPredictor** (0.1.1)
- **ComputerCleanup** (1.2.0)
- **Configuration** (1.6.0)
- **CredentialManager** (2.0)
- **DataMashup** (0.1.9)
- **DesktopManager** (0.0.3)
- **DockerCompletion** (1.2704.0.241216)
- **EZOut** (2.0.6)
- **F7History** (1.4.7)
- **Firewall-Manager** (1.1.1)
- **FormatMarkdownTable** (1.0.4)
- **Hcl2PS** (0.6.1)
- **HelpOut** (0.5.5)
- **ImportExcel** (7.8.10)
- **InvokeBuild** (5.12.1)
- **jwtPS** (1.1.3)
- **Metadata** (1.5.7)
- **Microsoft.PowerShell.ConsoleGuiTools** (0.7.7)
- **Microsoft.PowerShell.Crescendo** (1.1.0)
- **Microsoft.PowerShell.PSResourceGet** (1.0.6)
- **Microsoft.PowerShell.SecretManagement** (1.1.2)
- **Microsoft.PowerShell.SecretStore** (1.0.6)
- **Microsoft.PowerShell.ThreadJob** (2.1.0)
- **Microsoft.PowerShell.WhatsNew** (0.5.5)
- **Microsoft.WinGet.Client** (1.10.90)
- **Microsoft.WinGet.CommandNotFound** (1.0.4.0)
- **ModuleBuilder** (3.1.0)
- **ModuleFast** (0.5.1)
- **PackageManagement** (1.4.8.1)
- **Pester** (5.6.1)
- **Plaster** (1.1.4)
- **platyPS** (0.14.2)
- **platyPS** (0.14.1)
- **Posh** (0.2)
- **posh-git** (1.1.0)
- **PoshCodex** (1.0.8)
- **powershell-yaml** (0.4.11)
- **PowerShellBuild** (0.6.2)
- **PowerShellGet** (3.0.23)
- **ps-menu** (1.0.9)
- **ps2exe** (1.0.14)
- **PSAI** (0.4.0)
- **psake** (4.9.1)
- **psake** (4.9.0)
- **PSBashCompletions** (1.2.6)
- **PSClearHost** (1.0.0)
- **PSCodeHealth** (0.2.26)
- **PSCompletions** (5.2.5)
- **PSConfigFile** (0.1.36)
- **pscredentialmanager** (1.0.11)
- **PSDates** (1.0.5)
- **PSDepend** (0.3.8)
- **PSEverything** (3.3.0)
- **PSFileTransfer** (5.55.0)
- **PSFunctionInfo** (1.4.0)
- **PSFzf** (2.6.7)
- **PSGitHubChat** (0.1.0)
- **PSHelp.Copilot** (1.0.6)
- **PSJsonCredential** (2.2.0)
- **PSLog** (5.55.0)
- **PSNotes** (0.2.0.1)
- **PSOpenAI** (4.12.2)
- **PSReadLine** (2.4.0)
- **PSScriptAnalyzer** (1.23.0)
- **PSScriptTools** (2.50.0)
- **PSSoftware** (1.0.29)
- **PSSQLite** (1.1.0)
- **PSStucco** (0.6.1)
- **PSTypeExtensionTools** (1.10.1)
- **PSWindowsUpdate** (2.2.1.5)
- **PSWinVitals** (0.7.0)
- **PSWriteColor** (1.0.1)
- **PSWriteExcel** (0.1.15)
- **PSWriteHTML** (1.28.0)
- **PwshSpectreConsole** (2.1.1)
- **Sampler** (0.118.1)
- **ShowDemo** (0.1.7)
- **SysInfo** (1.2.0)
- **TabExpansionPlusPlus** (1.2)
- **Terminal-Icons** (0.11.0)
- **TerminalGuiDesigner** (0.0.1)
- **VSCodeBackup** (0.5.0)
- **WifiTools** (1.8.4)
- **WindowsCredentialManager** (0.0.1)
- **WindowsSandboxTools** (1.1.0)
- **WingetTools** (1.7.0)
- **Write-ObjectToSQL** (1.13)
- **WTToolBox** (1.15.0)
- **ZLocation** (1.4.3)
<!-- END_MODULES -->

### Notes

- This list will be kept up to date as new modules are added or removed.
- Modules are excluded from version control to keep the repository clean and lightweight.
- To replicate this setup, use the [PowerShellGet](https://learn.microsoft.com/en-us/powershell/scripting/gallery/overview) module to install the listed modules.
