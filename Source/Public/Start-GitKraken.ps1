Function Start-GitKraken {
    <#
    .SYNOPSIS
        Starts GitKraken
    .DESCRIPTION
        Starts GitKraken with optional parameters
    .PARAMETER Path
        Path to open in GitKraken
    .PARAMETER NewTab
        Open in a new tab
    .EXAMPLE
        Start-GitKraken
    .EXAMPLE
        Start-GitKraken -Path C:\Projects\MyRepo
    .EXAMPLE
        Start-GitKraken -Path C:\Projects\MyRepo -NewTab
    #>
    [CmdletBinding()]
    [Alias('gitkraken', 'krak')]
    Param(
        [Parameter(Position = 0, Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ })]
        [String]$Path = (Get-Location).ProviderPath
    )

    Begin {
        Write-Verbose "[BEGIN]: Start-GitKraken"

        $StartPath = (Get-Location).ProviderPath

        # Ensure Git Repository
        if (-not(Test-Path -Path "$StartPath\.git")) {
            Write-Warning 'Not a Git Repository. Aborting...'
            return
        }

        $GitKrakenCmdPath = Get-Command gitkraken.cmd -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source

        if (-not $GitKrakenCmdPath) {
            Write-Error "GitKraken not found in PATH"
            return
        }

    }

    process {

        $arguments = @()

        if ($Path) {
            $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
            if ($resolvedPath) {
                $arguments += "--path=`"$resolvedPath`""
            } else {
                Write-Warning "Path not found: $Path"
            }
        }

        if ($NewTab) {
            $arguments += "--new-tab"
        }

        Write-Verbose "Starting GitKraken with arguments: $arguments"
        Write-Host "Starting GitKraken at $StartPath..." -ForegroundColor Cyan
        Start-Process -FilePath $GitKrakenCmdPath -ArgumentList $arguments -NoNewWindow -ErrorAction SilentlyContinue
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to start GitKraken. Exit code: $LASTEXITCODE"
        } else {
            Write-Verbose "GitKraken started successfully."
        }
    }

    End {
        Write-Verbose "[END]: Start-GitKraken"
    }
}
