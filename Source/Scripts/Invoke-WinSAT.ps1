#Requires -RunAsAdministrator

<#PSScriptInfo

.VERSION 1.0.0

.GUID cd694bf3-f66f-4206-8dcf-a7a3ed576649

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS Windows System Performance Administrator WinSAT Assessment Tool Score

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/Invoke-WinSAT/

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

1.0.0
Initial Release


.PRIVATEDATA

#>

Function New-WinSATAssessment {
    <#
    .SYNOPSIS
        Invoke the Windows System Assessment Tool (WinSAT) to measure the performance of your system.
    .DESCRIPTION
        Invoke the Windows System Assessment Tool (WinSAT) to measure the performance of your system.
    .PARAMETER CommandLine
        The command line to pass to WinSAT.exe. Default is 'formal'.
    .PARAMETER OutputPath
        The path to save the generated XML result file to. Default is $env:SYSTEMROOT\Performance\WinSAT\WinSAT.xml.
    .EXAMPLE
        # Run a Formal Assessment and Output the Results to the Default Location:
        $result = New-WinSATAssessment -CommandLine features -OutputPath "$env:TEMP\WinSAT.xml"

        # Emit Information about Disks:
        $result.WinSAT.SystemConfig.Disk.Disk | Format-Table -AutoSize

        # Calculated Properties:
        $result.WinSAT.SystemConfig.Disk.Disk | Select-Object -Property Id, DiskNum, WriteCacheEnabled, @{N='Vendor';E={$_.Vendor.'#cdata-section'}}, @{N='Model';E={$_.Model.'#cdata-section'}},@{N='SizeGB';E={[Math]::Round([int64]($_.Size.'#text')/1GB,1)}}
    .LINK
        - https://powershell.one/wmi/root/cimv2/win32_winsat
        - https://powershell.one/code/8.html
        - https://docs.microsoft.com/en-us/windows/win32/winsat/using-winsat
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateSet('formal','dwm','cpu','mem','d3d','disk','media','mfmedia','features')]
        [string]$CommandLine = 'formal',
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath = "$env:SYSTEMROOT\Performance\WinSAT\WinSAT.xml"
    )

    # Ensure Admin Privileges
    If (
        !(
            [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole( [Security.Principal.WindowsBuiltInRole] "Administrator" )
    ) {
        Write-Warning "Run this with Administrator privileges!"; return
    }

    # Use Regex to Parse the Real-Time Status Messages Emitted by WinSAT.exe
    $patternTime = '\d{2}:\d{2}:\d{2}\.\d{2}'
    $patternString = "^> (.*?)\s*('.*'){0,1}$"

    # Run the Tool
    winsat $CommandLine -xml $OutputPath | ForEach-Object {

        # Ignore Feedback About the Time Tests Took:
        $isTime = $_ -match $patternTime

        if (!$isTime) {
            # output the parsed text in a progress bar:
            $IsParsed = $_ -match $patternString
            $status = @{}

            if ($IsParsed) {
                if ($matches[2]) {
                    $status['Status'] = $matches[2]
                }

                Write-Progress -Activity $matches[1] @status

            }
        }
    }

    # Load the XML File
    $xml = [xml]::new()
    $xml.Load($Path)

    # Return
    $xml

}

Get-WinSatScore {
    <#
    .SYNOPSIS
        Get the Windows System Assessment Tool (WinSAT) score for your system.
    .DESCRIPTION
        Get the Windows System Assessment Tool (WinSAT) score for your system.
    .PARAMETER Category
        The category of the score to return. Default is 'WinSPR', which is the lowest score from all available other
        scores. Possible options are: CPU, D3D, Disk, Graphics, Memory, WinSPR. See the NOTES section for more information.
    .NOTES
        Get a list of the possible categories from running:

        ```powershell
        ((Get-CimInstance -ClassName Win32_WinSAT -Property *).CimInstanceProperties).Name
        ```

        should output:

        ```text
        CPUScore
        D3DScore
        DiskScore
        GraphicsScore
        MemoryScore
        TimeTaken
        WinSATAssessmentState
        WinSPRLevel
        ```

        - **CPUScore:** `REAL32` - The CPU score for the computer's processors.
        - **D3DScore:** `REAL32` - The Direct3D score for the computer's graphics adapters.**
        - **DiskScore:** `REAL32` - The Hard Disk's score for the sequential read throughput on the primary hard disk of the machine.
        - **GraphicsScore:** `REAL32` - The Graphics score for the computer's graphics adapters and their capabilities.**
        - **MemoryScore:** `REAL32` - The Memory score for the computer's memory subsystem throughput and capacity.
        - **TimeTaken:** `STRING` - This property must be set to `MostRecentAssessment` in the `WHERE` clause of the `WQL` query.
        - **WinSATAssessmentState:** `UINT32` - The state of the assessment.
            - **WinSATAssessmentState** returns a numeric value. To Translate it into a meaningful text, use the following mapping:

        ```powershell
        $WinSATAssessmentState_map = @{
            0 = 'StateUnknown'
            1 = 'Valid'
            2 = 'IncoherentWithHardware'
            3 = 'NoAssessmentAvailable'
            4 = 'Invalid'
        }
        ```

        - **WinSPRLevel**: `REAL32` - The Base score for the computer. For details on the score value, see the IProvideWinSATResultsInfo::SystemRating property.


        ** After Windows 8.1, WinSAT no longer assess the three-dimensional graphics (gaming) capabilities of the computer and the graphics driver’s ability to render objects and execute shaders using this assessment. For compatibility, WinSAT report sentinel values for the metrics and scores, however these are not calculated in real time.

    .EXAMPLE
        Get-WinSatScore -Category CPU

        # Output: 9.2
    .LINK
        - https://powershell.one/wmi/root/cimv2/win32_winsat
        - https://powershell.one/code/8.html
        - https://docs.microsoft.com/en-us/windows/win32/winsat/using-winsat
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateSet('CPU','D3D','Disk','Graphics','Memory','WinSPR')]
        [string]$Category = 'WinSPR'
    )

    Get-CimInstance -ClassName Win32_WinSAT | Select-Object -Property $Category | ForEach-Object {
        $_.$Category
    }
}

$FailingThreshold = 6.5

$WinSatResults = Get-CimInstance Win32_WinSAT | Select-Object CPUScore, DiskScore, GraphicsScore, MemoryScore, WinSPRLevel

$WinSatHealth = foreach ($Result in $WinSatResults) {
    if ($Result.CPUScore -lt $FailingThreshold) { "CPU Score is $($result.CPUScore). This is less than $FailingThreshold" }
    if ($Result.DiskScore -lt $FailingThreshold) { "Disk Score is $($result.Diskscore). This is less than $FailingThreshold" }
    if ($Result.GraphicsScore -lt $FailingThreshold) { "Graphics Score is $($result.GraphicsScore). This is less than $FailingThreshold" }
    if ($Result.MemoryScore -lt $FailingThreshold) { "RAM Score is $($result.MemoryScore). This is less than $FailingThreshold" }
    if ($Result.WinSPRLevel -lt $FailingThreshold) { "Average WinSPR Score is $($result.winsprlevel). This is less than $FailingThreshold" }
}
if (!$WinSatHealth) {
$AllResults = ($Winsatresults | out-string)
$WinSatHealth = "Healthy. $AllResults"
}

Write-Host $WinSatHealth -ForegroundColor Green


# <#

# .SYNOPSIS
#     Invoke WinSAT to measure the performance of your system.

# .DESCRIPTION
#     Invoke the Windows System Assessment Tool (WinSAT) to measure the performance of your system.

# .PARAMETER OutDir
#     The directory to save the generated XML result files to. Default is $env:TEMP. You can change this via the $env:WinSATResults environment variable.

# .PARAMETER XML
#     Output the results as XML. Default is $true.

# .PARAMETER CSV
#     Output the results as CSV. Default is $false.

# .PARAMETER HTML
#     Output the results as HTML. Default is $false.

# .PARAMETER EXAMPLE
#     Show example usage of the function.

# .PARAMETER LogFile
#     The path to the log file to write to. Default is $env:TEMP\Invoke-WinSAT.log.

# .EXAMPLE
#     Invoke-WinSAT
# #>
# [CmdletBinding()]
# Param(
#     [Parameter(Mandatory=$false)]
#     [ValidateNotNullOrEmpty()]
#     [string]$OutDir = "$Env:SystemRoot\Performance\WinSAT\DataStore",
#     [Parameter(Mandatory=$false)]
#     [ValidateNotNullOrEmpty()]
#     [switch]$XML = $true,
# )





# <#
# .SYNOPSIS
#     Invoke the Windows System Assessment Tool (WinSAT) to measure the performance of your system.
# #>

# # Invoke the Windows System Assessment Tool (WinSAT) to measure the performance of your system.


# Get-CimInstance -ClassName Win32_WinSAT

# winsat query

# # get the freshest file that starts with "Formal" from the WinSAT datastore:
# $path = Get-ChildItem -Path 'C:\Windows\Performance\WinSAT\DataStore\*Formal.*.xml' | Sort-Object -Property CreationTime -Descending | Select-Object -First 1 -ExpandProperty FullName

# # read the file content
# $content = Get-Content -Path $Path -Raw

# # the default output looks aweful:
# $content

# # prettify it:
# ([xml]$content).Save([Console]::Out)


# # get the freshest file that starts with "Formal" from the WinSAT datastore:
# $path = Get-ChildItem -Path 'C:\Windows\Performance\WinSAT\DataStore\*Formal.*.xml' | Sort-Object -Property CreationTime -Descending | Select-Object -First 1 -ExpandProperty FullName

# # load xml content
# $xml = [xml]::new()
# $xml.Load($Path)

# # access node with data:
# $xml.WinSAT.Metrics.CPUMetrics.CompressionMetric

# # access node with data:
# $node = $xml.WinSAT.Metrics.CPUMetrics.CompressionMetric
# 'CPU Compression Performance is {0} {1}' -f $node.'#text', $node.units


# # get the freshest file that starts with "Formal" from the WinSAT datastore:
# $path = Get-ChildItem -Path 'C:\Windows\Performance\WinSAT\DataStore\*Formal.*.xml' | Sort-Object -Property CreationTime -Descending | Select-Object -First 1 -ExpandProperty FullName

# # load xml content
# $xml = [xml]::new()
# $xml.Load($Path)

# # access node with data:
# $xml.WinSAT.SystemConfig

# $xml.WinSAT.SystemConfig.Processor.Instance.Signature


# $xml.WinSAT.SystemConfig.Processor.Instance.Signature.Manufacturer

# $Path = "$env:temp\myreport.xml"
# winsat formal -xml $Path
# $xml = [xml]::new()
# $xml.Load($Path)
