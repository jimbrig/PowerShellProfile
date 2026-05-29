Function Get-GitHubRateLimits {
    <#
    .SYNOPSIS
        Leverages GitHub CLI to call the GitHub API to retrieve rate limit details.
    #>
    [CmdLetBinding()]
    Param()

    Begin{
        Write-Verbose "[Begin]: Get-GitHubRateLimits"
        if (-not(Get-Command -Name gh -ErrorAction SilentlyContinue)) {
            Write-Host "GitHub CLI (gh) is not installed. Please install it to use this function."
            exit 1
        }
    }

    Process {
        Write-Verbose "[Process]: Get-GitHubRateLimits"
        $cmd = "gh api -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' /rate_limit"
        & $cmd
    }

    End {
        Write-Verbose "[End]: Get-GitHubRateLimits"
    }
}
