# File hashing and cryptographic functions
Function Get-MD5Hash {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path
    )
    try {
        Get-FileHash -Algorithm MD5 -Path $Path
    } catch {
        Write-Error "Failed to get MD5 hash: $_"
    }
}

Function Get-SHA1Hash {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path
    )
    try {
        Get-FileHash -Algorithm SHA1 -Path $Path
    } catch {
        Write-Error "Failed to get SHA1 hash: $_"
    }
}

Function Get-SHA256Hash {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path
    )
    try {
        Get-FileHash -Algorithm SHA256 -Path $Path
    } catch {
        Write-Error "Failed to get SHA256 hash: $_"
    }
}
