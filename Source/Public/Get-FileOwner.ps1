Function Get-FileOwner() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Path,

        [switch]$Recursive
    )

    $LastWrite = @{
        Name       = 'Last Write Time'
        Expression = { $_.LastWriteTime.ToString('u') }
    }
    $Owner = @{
        Name       = 'File Owner'
        Expression = { (Get-Acl $_.FullName).Owner }
    }
    $HostName = @{
        Name       = 'Host Name'
        Expression = { $env:COMPUTERNAME }
    }

    Get-ChildItem @PSBoundParameters |
        Select-Object $HostName, $Owner, Name, Directory, $LastWrite, Length
}
