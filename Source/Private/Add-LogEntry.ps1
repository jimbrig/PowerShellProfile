Function Add-LogEntry {
    <#
    .SYNOPSIS
        Adds an entry to a log file and outputs to the console.

    .DESCRIPTION
        This function adds an entry to a log file and sends its output to the console host.
        Output sent to the log file includes time stamps. Those are not generally needed for the console output and
        the could take up too much space. You can pass directions to indent output or indicate that something
        was a Success, Warning, or Failure. Everything else is marked as Info. Info data is sent to the screen
        in the default white font, but everything else uses appropriate colors.

    .PARAMETER LogFile
        The path to the log file. If the file does not exist, it will be created. Set as a DefaultParameter for easier
        use: $PSDefaultParameterValues['Add-LogEntry:LogFile'] = 'C:\Logs\MyLog.log'

    .PARAMETER Output
        The text to be written to the log file and displayed on the console.

    .PARAMETER ClearLog
    Overwrites the current logfile with this entry only. Generally would be used at the start of the script.

    .PARAMETER BlankLine
    Still outputs the timespamp, but does not include any data. Useful for separating sections of the log.

    .PARAMETER IndentSize
    The number of spaces that text is indented by. The default is 4.

    .PARAMETER Indent
    Data that you want to indent by IndentSize x Indent spaces. Can help readability in some situations.

    .PARAMETER IsError
    Marks the entry as [Error] in the logfile and colours the data in RED in the host.

    .PARAMETER IsPrompt
    Marks the entry as [Prompt] in the logfile and colours the data in YELLOW in the host.

    .PARAMETER IsSuccess
    Marks the entry as [Success] in the logfile and colours the data in GREEN in the host.

    .PARAMETER IsWarning
    Marks the entry as [Warning] in the logfile and colours the data in YELLOW in the host.

    .PARAMETER IsDebug
    Marks the entry as [Debug] in the logfile and colours the data in CYAN in the host.

    .EXAMPLE
        Add-LogEntry -Output "This is a test"

    .EXAMPLE
        Add-LogEntry -Output "This is a test" -IsError

    .EXAMPLE
        Add-LogEntry -Output "This is a test" -IsSuccess

    .EXAMPLE
        Add-LogEntry -Output 'Checking if all required Windows Features are installed:'
        ForEach ($RequiredWindowsFeature in $RequiredWindowsFeatures) {
            Add-LogEntry -Output $RequiredWindowsFeature -Indent 1
            If (-not(Get-WindowsFeature -Name $RequiredWindowsFeature).Installed) {
                Add-LogEntry -Output 'Feature is missing, will attempt to install now.' -Indent 2
                Try {
                    $null = Add-WindowsFeature -Name $RequiredWindowsFeature -ErrorAction Stop
                    Add-LogEntry -Output 'Success' -IsSuccess -indent 2
                } catch {
                    Add-LogEntry -Output "Failed to install '$RequiredWindowsFeature'" -Indent 2 -IsError
                }
            }
        }

    .EXAMPLE
        Add-LogEntry -Output "Querying Computer: $Computer"
        Add-LogEntry -Output "Processor: $CPU" -Indent 1
        Add-LogEntry -Output "Memory: $RAM" -Indent 1

    .NOTES
        Name: Add-LogEntry

    .LINK
        https://github.com/kieranwalsh/PowerShell/blob/main/Add-LogEntry/add-LogEntry.ps1
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Alias('Message')]
        [string]$Output = $(if (
                (-not($BlankLine) -and (-not($Clearlog))) -and
                ($null -eq $Output)
            ) {
                $Output = Read-Host 'Please specify the output you wish to log'
            } Elseif ($BlankLine) {
                $Output = ''
            }
        ),
        [int]$IndentSize = 4,
        [string]$LogFile = 'C:\Windows\Temp\file.log',
        [switch]$BlankLine,
        [switch]$ClearLog,
        [int]$Indent,
        [switch]$IsDebug,
        [switch]$IsError,
        [switch]$IsPrompt,
        [switch]$IsSuccess,
        [switch]$IsWarning
    )

    $ForegroundColor = 'White'
    if ($Indent) {
        $Space = ($IndentSize * $Indent) + 1
    } Else {
        $Space = 1
    }
    $Type = 'INFO'
    if ($IsDebug) {
        $Type = '[DEBUG]'
        $ForegroundColor = 'Cyan'
    }
    if ($IsError) {
        $Type = '[ERROR]'
        $ForegroundColor = 'Red'
    }
    if ($IsPrompt) {
        $Type = '[PROMPT]'
        $ForegroundColor = 'Yellow'
    }
    if ($IsSuccess) {
        $Type = '[SUCCESS]'
        $ForegroundColor = 'Green'
    }
    if ($IsWarning) {
        $Type = '[WARNING]'
        $ForegroundColor = 'Yellow'
    }

    Write-Host -Object $Output -ForegroundColor $ForegroundColor
    if ($BlankLine) {
        '{0,-22}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Out-File -FilePath $LogFile -Encoding 'utf8' -Append
    } Elseif ($ClearLog) {
        Clear-Content -Path $LogFile
    } Else {
        "{0,-22}{1,-11}{2,-$Space}{3}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Type, ' ', $Output | Out-File -FilePath $LogFile -Encoding 'utf8' -Append
    }
}
