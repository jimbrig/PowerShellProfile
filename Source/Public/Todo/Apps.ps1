Function Start-GitKraken {
    <#
    .SYNOPSIS
        Starts GitKraken at the current Git Repository (or provided path).
    .DESCRIPTION
        This utility function starts the GitKraken Git Client Program, launching it under the present git repository's
        working directory by default (or provided path).
    .EXAMPLE
        Start-GitKraken
    .EXAMPLE
        Start-GitKraken -Path 'C:\Projects\MyProject'
    .NOTES
        Author: Jimmy Briggs <jimmy.briggs@jimbrig.com>
    #>
    [CmdletBinding()]
    [Alias('gitkraken', 'krak')]
    Param(
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ })]
        [String]$Path = (Get-Location).ProviderPath
    )

    Begin {

        $StartPath = (Get-Location).ProviderPath

        # Ensure Git Repository
        if (-not(Test-Path -Path "$StartPath\.git")) {
            Write-Warning 'Not a Git Repository. Aborting...'
            return
        }

        $GitKrakenCmdPath = Resolve-Path "$Env:LOCALAPPDATA\gitkraken\bin\gitkraken.cmd"

        # Ensure GitKraken
        if (-not(Test-Path -Path $GitKrakenCmdPath)) {
            Write-Warning 'GitKraken Not Found. Aborting...'
            return
        }
    }

    Process {
        Write-Host "Starting GitKraken at $StartPath..." -ForegroundColor Cyan
        Start-Process -FilePath $GitKrakenCmdPath -ArgumentList "--path $StartPath"
    }

    End {
        Write-Host 'Done.' -ForegroundColor Green
    }

}
