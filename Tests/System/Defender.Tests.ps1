#Requires -Module Pester

<#
    .SYNOPSIS
        Tests Windows Defender exclusion configuration.

    .DESCRIPTION
        Verifies that the development tool paths, file extensions, and processes
        expected by this environment are present in the Windows Defender exclusion
        lists. Reading preferences requires elevation, so these tests are skipped
        when the session is not running as administrator.
#>

Describe 'Windows Defender Checks' -Tag 'System', 'Defender', 'RequiresAdmin' {

    BeforeDiscovery {
        $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
        if ($IsAdmin) { $script:SkipDefenderChecks = $null } else { $script:SkipDefenderChecks = $true }
    }

    BeforeAll {
        # BeforeAll always runs even when every It is skipped, so guard the
        # elevated call: only read preferences when admin and never let a failed
        # read throw and fail the whole block (the It blocks skip when non-admin).
        $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
        if ($IsAdmin) {
            $MpPrefs = Get-MpPreference -ErrorAction SilentlyContinue
            $script:DefenderExclusionPaths = $MpPrefs.ExclusionPath
            $script:DefenderExclusionExtensions = $MpPrefs.ExclusionExtension
            $script:DefenderExclusionProcesses = $MpPrefs.ExclusionProcess
        }

        $script:TestPaths = @(
            'C:\Program Files\Docker',
            'C:\Program Files\Docker\cli-plugins',
            'C:\Program Files\Docker\Docker',
            'C:\Program Files\PowerShell\7',
            'C:\Program Files\PowerShell\7-preview',
            'C:\Program Files\R',
            'C:\Program Files\R\bin',
            'C:\Program Files\RStudio',
            'N:\',
            'X:\'
        )

        $script:TestExtensions = @(
            '.bash',
            '.bat',
            '.c',
            '.cmd',
            '.cpp',
            '.dll',
            '.exe',
            '.js',
            '.json',
            '.jsx',
            '.ps1',
            '.psd1',
            '.psm1',
            '.py',
            '.R',
            '.rda',
            '.RData',
            '.rds',
            '.Rhistory',
            '.Rmd',
            '.Rprofile',
            '.Rproj',
            '.sh',
            '.ts',
            '.tsx',
            '.xml',
            '.yaml',
            '.yml',
            '.zsh',
            'csv',
            'json',
            'rda',
            'RData',
            'rds',
            'Renviron',
            'Rhistory',
            'Rmd',
            'Rnw',
            'Rprofile',
            'Rproj',
            'tsv',
            'xml',
            'yaml',
            'yml'
        )

        $script:TestPrograms = @(
            'bash.exe',
            'C:\rtools45\usr\bin\make.exe',
            'chrome.exe',
            'chrome_proxy.exe',
            'chromium.exe',
            'Code - Insiders.exe',
            'code-tunnel.exe',
            'Code.exe',
            'com.docker.admin.exe',
            'com.docker.backend.exe',
            'com.docker.diagnose.exe',
            'compose-bridge.exe',
            'Docker Desktop.exe',
            'docker-compose.exe',
            'docker-credential-desktop.exe',
            'docker-credential-wincred.exe',
            'docker.exe',
            'DockerCli.exe',
            'dotnet.exe',
            'extension-admin.exe',
            'gh.exe',
            'git-bash.exe',
            'git-cmd.exe',
            'git-gui.exe',
            'git-lfs.exe',
            'git.exe',
            'gitk.exe',
            'hub-tool.exe',
            'kubectl.exe',
            'open.exe',
            'pandoc.exe',
            'pip.exe',
            'poetry.exe',
            'Positron.exe',
            'powershell.exe',
            'PowerToys.exe',
            'pwsh-preview.exe',
            'pwsh.exe',
            'python.exe',
            'quarto.exe',
            'quarto.js',
            'R.exe',
            'Rcmd.exe',
            'Rfe.exe',
            'Rgui.exe',
            'Rscript.exe',
            'RSetReg.exe',
            'rstudio.exe',
            'Rterm.exe',
            'sh',
            'tig',
            'uv'
        )
    }

    It 'Checks Defender Exclusions Exist for Paths' -Skip:$SkipDefenderChecks {
        $script:TestPaths | ForEach-Object { $script:DefenderExclusionPaths | Should -Contain $_ }
    }

    It 'Checks Defender Exclusions Exist for Extensions' -Skip:$SkipDefenderChecks {
        $script:TestExtensions | ForEach-Object { $script:DefenderExclusionExtensions | Should -Contain $_ }
    }

    It 'Checks Defender Exclusions Exist for Programs' -Skip:$SkipDefenderChecks {
        $script:TestPrograms | ForEach-Object { $script:DefenderExclusionProcesses | Should -Contain $_ }
    }

}
