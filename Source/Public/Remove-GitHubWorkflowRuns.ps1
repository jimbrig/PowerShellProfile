Function Remove-GitHubWorkflowRuns {
    <#
    .SYNOPSIS
        Leverages GitHub CLI to call the GitHub API to remove workflow runs.
    .DESCRIPTION
        This function removes workflow runs from a specified GitHub repository using the GitHub CLI.
    .PARAMETER Owner
        The owner of the GitHub repository.
    .PARAMETER Repository
        The name of the GitHub repository.
    #>
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [string]$Repository
    )

    Begin {
        Write-Verbose "[Begin]: Get-GitHubRateLimits"
        if (-not(Get-Command -Name gh -ErrorAction SilentlyContinue)) {
            Write-Host "GitHub CLI (gh) is not installed. Please install it to use this function."
            exit 1
        }
    }

    Process {
        Write-Verbose "[Process]: Get-GitHubRateLimits"
        $workflowRuns = gh api repos/$Owner/$Repository/actions/runs --paginate --jq '.workflow_runs[].id'
        Write-Host "Discovered $($workflowRuns.Count) workflow runs."
        ForEach ($runId in $workflowRuns) {
            Write-Host "Removing workflow run with ID: $runId"
            gh api repos/$Owner/$Repository/actions/runs/$runId -X DELETE
        }
    }

    End {
        Write-Verbose "[End]: Get-GitHubRateLimits"
        Write-Host "All workflow runs have been removed."
    }
}
