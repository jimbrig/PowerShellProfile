<#
.SYNOPSIS
    Gets basic information about the computer
.DESCRIPTION
    Gets basic information about the computer including OS, CPU, RAM, and disk space
.EXAMPLE
    Get-PCInfo
.NOTES
    Author: Jimmy Briggs
#>
function Get-PCInfo {
    [CmdletBinding()]
    param()

    process {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $cpu = Get-CimInstance -ClassName Win32_Processor
        $ram = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"

        $ramGB = [math]::Round($ram.Sum / 1GB, 2)
        $diskGB = [math]::Round($disk.Size / 1GB, 2)
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $usedGB = $diskGB - $freeGB
        $usedPct = [math]::Round(($usedGB / $diskGB) * 100, 2)

        $properties = [ordered]@{
            ComputerName = $env:COMPUTERNAME
            OSName = $os.Caption
            OSVersion = $os.Version
            OSBuild = $os.BuildNumber
            CPUName = $cpu.Name
            CPUCores = $cpu.NumberOfCores
            CPULogicalProcessors = $cpu.NumberOfLogicalProcessors
            RAMTotal = "$ramGB GB"
            DiskTotal = "$diskGB GB"
            DiskFree = "$freeGB GB"
            DiskUsed = "$usedGB GB ($usedPct%)"
            LastBoot = $os.LastBootUpTime
            Uptime = (Get-Date) - $os.LastBootUpTime
        }

        $obj = New-Object -TypeName PSObject -Property $properties
        return $obj
    }
}
