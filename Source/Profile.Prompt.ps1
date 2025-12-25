#Requires -Modules "PSCalendar"

# TODO: integrate with oh-my-posh
Function Prompt {
    <#
    .SYNOPSIS
        Sets the PowerShell prompt to a custom format.
    .DESCRIPTION
        Creates a custom prompt that displays a calendar in the upper right corner of the console.
    .LINK
        https://go.microsoft.com/fwlink/?LinkID=225750
    #>
    [CmdletBinding()]
    Param()

    $fill = [system.management.automation.host.buffercell]::new(' ', $host.UI.RawUI.BackgroundColor, $host.UI.RawUI.BackgroundColor, 'complete')

    #define a rectangle with an upper left corner X distance from the edge
    $left = $host.UI.RawUI.WindowSize.width - 42

    #need to adjust positioning based on buffer size of the console
    #is the cursor beyond the window size, ie have we scrolled down?
    if ($host.UI.RawUI.CursorPosition.Y -gt $host.UI.RawUI.WindowSize.Height) {
        $top = $host.UI.RawUI.CursorPosition.Y - $host.UI.RawUI.WindowSize.Height
    } else {
        $top = 0
    }
    #    System.Management.Automation.Host.Rectangle new(int left, int top, int right, int bottom)
    $r = [System.Management.Automation.Host.Rectangle]::new($left, 0, $host.UI.RawUI.WindowSize.width, $top + 10)

    #clear the area for the calendar display
    $host.UI.RawUI.SetBufferContents($r, $fill)

    #show the calendar in the upper right corner of the console
    $pos = [system.management.automation.host.coordinates]::new($left, 0)
    Show-PSCalendar -Position $pos

    "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";

}
