Function Get-CurrentUser {
    <#
        .SYNOPSIS
            Retrieves the current user's information.
        .DESCRIPTION
            This function retrieves the current user's name, domain, and SID.
        .EXAMPLE
            Get-CurrentUser
        .INPUTS
            None
        .OUTPUTS
            [PSCustomObject] containing Name and Domain properties.
    #>
    [CmdletBinding()]
    Param ()

    Begin {
        Write-Verbose "[BEGIN]: Get-CurrentUser"
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    }

    Process {
        Write-Verbose "[PROCESS]: Get-CurrentUser"
        $parts = $identity.Name -split '\\'
        $user = [PSCustomObject]@{
            Name  = $parts[1]
            Domain = $parts[0]
            SID   = $identity.User.Value
        }
    }

    End {
        Write-Verbose "[END]: Get-CurrentUser"
        return $user
    }
}
