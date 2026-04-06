Function Search-History {
    <#
    .SYNOPSIS
        Searches the command history for a specific command or keyword.
    .DESCRIPTION
        This function searches the command history for a specific command or keyword and returns the matching entries.
    .PARAMETER SearchTerm
        The term to search for in the command history.
    #>
    [Alias("histsearch")]
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$SearchTerm
    )

    Begin {
        Write-Verbose "[Begin]: Search-History"
        $HistFile = (Get-PSReadLineOption).HistorySavePath
        if (-not(Test-Path -Path $HistFile)) {
            Write-Host "History file not found. Please ensure that PSReadLine is configured to save history."
            exit 1
        }
    }

    Process {
        Write-Verbose "[Process]: Search-History"
        Select-String -Path $HistFile -Pattern $SearchTerm | ForEach-Object {
            $entry = $_.Line
            $timestamp = $_.LineNumber
            Write-Host "[$timestamp] $entry"
        }
    }

    End {
        Write-Verbose "[End]: Search-History"
    }
}
