<#
.SYNOPSIS
    Gets the uptime of the computer
.DESCRIPTION
    Gets the uptime of the computer in a human-readable format
.EXAMPLE
    Get-PCUptime
.NOTES
    Author: Jimmy Briggs
#>
function Get-PCUptime {
    [CmdletBinding()]
    param()

    process {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $lastBoot = $os.LastBootUpTime
        $uptime = (Get-Date) - $lastBoot

        $properties = [ordered]@{
            ComputerName = $env:COMPUTERNAME
            LastBoot = $lastBoot
            Days = $uptime.Days
            Hours = $uptime.Hours
            Minutes = $uptime.Minutes
            Seconds = $uptime.Seconds
            TotalHours = [math]::Round($uptime.TotalHours, 2)
            TotalDays = [math]::Round($uptime.TotalDays, 2)
            UptimeString = "{0} days, {1} hours, {2} minutes, {3} seconds" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds
        }

        $obj = New-Object -TypeName PSObject -Property $properties
        return $obj
    }
}
