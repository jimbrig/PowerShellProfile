Function Get-ShellApps {
    <#
    .SYNOPSIS
    Retrieves a list of installed shell applications on the system.
    .DESCRIPTION
    This function uses the Shell.Application COM object to access the AppsFolder and lists all installed shell applications.
    #>
    [CmdletBinding()]
    Param ()

    $Shell = New-Object -ComObject Shell.Application
    $AppsFolder = $Shell.Namespace('shell:AppsFolder')
    $AppsFolder.Items() | ForEach-Object {
        $_.Name
    }

}
