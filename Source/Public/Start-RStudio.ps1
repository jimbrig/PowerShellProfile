Function Start-RStudio {
    <#
    .SYNOPSIS
        Starts RStudio IDE at the current working directory (or provided path).
    .DESCRIPTION
        This utility function starts the RStudio IDE, launching it under the working directory by default (or provided path).
    .EXAMPLE
        Start-RStudio
    .EXAMPLE
        Start-RStudio -Path 'C:\Projects\MyProject'
    .NOTES
        Author: Jimmy Briggs <jimmy.briggs@jimbrig.com>
    #>
    [CmdletBinding()]
    [Alias('rstudio')]
    Param(
        [Parameter(Mandatory = $false)]
        [String]$Path = (Get-Location).ProviderPath
    )

    Begin {

        $RprojFile = Get-ChildItem -Path $Path -Filter '*.Rproj' -File | Select-Object -First 1

        # If a *.Rproj file is in current wd use that:
        if ($RprojFile) {
            Write-Host "Found RStudio Project File: $($RprojFile.FullName)" -ForegroundColor Cyan
            Start-Process -FilePath $RprojFile.FullName
            return
        }

        # ensure absolute path
        $StartPath = $Path | Resolve-Path
        $ExePath = "$Env:PROGRAMFILES\RStudio\rstudio.exe" | Resolve-Path
        $LogPath = "$Env:TEMP\rstudiostart.log" | Resolve-Path
        Write-Verbose "RStudio Startup Log File: $LogPath"

        if (-not(Test-Path -Path $ExePath)) {
            Write-Warning 'RStudio not found. Aborting...'
            return
        }
    }

    Process {
        Write-Host "Starting RStudio at $StartPath..." -ForegroundColor Cyan
        Start-Process -FilePath $ExePath -ArgumentList $StartPath -RedirectStandardOutput $LogPath
    }
}
