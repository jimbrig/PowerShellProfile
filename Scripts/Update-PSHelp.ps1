
<#PSScriptInfo

.VERSION 1.0

.GUID fa4bd2b4-8634-471f-a085-4742ce105e76

.AUTHOR jimmy

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES ThreadJob

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<#

.DESCRIPTION
    Update Help More Quickly using ThreadJob
#>
#Requires -Version 7 -Module ThreadJob
Param(
    [string[]]$Name = @(),
    [Microsoft.PowerShell.Commands.UpdateHelpScope]$Scope = 'CurrentUser',
    $ThrottleLimit = 30
)

try {
    #TODO: Remove help redundancies from different repos and only fetch for the latest version
    [Collections.Generic.List[Management.Automation.Job2]]$updateInfoJobs = Get-Module -ListAvailable |
        Where-Object HelpInfoUri -Match '^https?://' |
        ForEach-Object {
            $module = $PSItem
            Start-ThreadJob -InputObject $module -Name $module.Name -ThrottleLimit $ThrottleLimit {
                Update-Help -Module $input.Name -Scope $using:Scope -ErrorAction SilentlyContinue -Verbose
            }
        }


    #Track Job Progress
    $jobCount = $updateInfoJobs.Count

    Write-Progress -Id 1 -Activity 'Updating Help' -Status "0/$jobCount" -PercentComplete 0
    $completedCount = 0
    while ($updateInfoJobs.State -contains 'Running') {
        $completedJob = $updateInfoJobs | Wait-Job -Any

        $completedCount++
        [int]$percentComplete = $completedCount / $jobCount * 100
        Write-Verbose "Completed $($completedJob.Name) help"
        Write-Progress -Id 1 -Activity 'Updating Help' -Status "$completedCount/${jobCount}: Updated $($completedJob.Name)" -PercentComplete $percentComplete
        $completedJob | Receive-Job -Wait -AutoRemoveJob
        [void]$updateInfoJobs.Remove($completedJob)
    }
} finally {
    $updateInfoJobs | Remove-Job -Force
}
