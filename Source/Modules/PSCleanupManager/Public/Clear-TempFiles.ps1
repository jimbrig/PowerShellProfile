Function Clear-TempFiles {
    <#
    .SYNOPSIS
    Clears temporary files and system caches to free up disk space and improve performance.
    .DESCRIPTION
    This function performs a series of cleanup tasks across the filesystem's temporary directories.
    #>
    [CmdletBinding()]
    param()

    Begin {
        Write-Debug "[BEGIN]: Clear-TempFiles"
    }

    Process {
        Write-Debug "[PROCESS]: Clear-TempFiles"
    }

    End {
        Write-Debug "[END]: Clear-TempFiles"
    }
}
