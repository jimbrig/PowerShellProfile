Function Get-SystemUptime {
    <#
    #>
    [CmdletBinding()]
    Param ()

    $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
    $LastBootUpTime = [Management.ManagementDateTimeConverter]::ToDateTime($OperatingSystem.LastBootUpTime)
    $SystemUptime = (Get-Date) - $LastBootUpTime

    $SystemUptime | Format-Table -AutoSize

}
