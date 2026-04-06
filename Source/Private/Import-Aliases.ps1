Function Import-AliasFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
                if (-not (Test-Path $_ -PathType Leaf)) {
                    throw "File not found: $_"
                }
                $extension = [System.IO.Path]::GetExtension($_).ToLower()
                if ($extension -notin @('.ps1', '.psd1')) {
                    throw "Unsupported file type. Only .ps1 and .psd1 files are supported."
                }
                return $true
            })]
        [string]$AliasFile
    )

    Begin {
        Write-Verbose "[BEGIN]: Import-AliasFile"

        # aliases need to first import the _Import.ps1 file
        if (-not $Global:AliasesImports) {
            $AliasImportFile = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath "Profile/Aliases/_Imports.ps1"
            try {
                Write-Verbose "Importing alias dependencies from ${AliasImportFile}"
                . $AliasImportFile
            } catch {
                Write-Warning "Failed to import alias dependencies from $AliasImportFile. Ensure it exists and is accessible."
                return
            }
            # check if the import was successful
            if (-not $Global:AliasesImports) {
                Write-Warning "Failed to initialize alias imports. Ensure _Imports.ps1 sets the Global:AliasesImports variable."
                return
            }
        }

        $AliasFile = Resolve-Path -Path $AliasFile -ErrorAction Stop
        $AliasFileType = [System.IO.Path]::GetExtension($AliasFile).ToLower()
    }

    Process {
        Write-Verbose "[PROCESS]: Import-Aliases for file: $AliasFile"

        try {
            if ($AliasFileType -eq ".ps1") {
                # If it's a .ps1 file, dot source it to load aliases
                Write-Verbose "Dot sourcing alias file: $AliasFile"
                . $AliasFile
                Write-Verbose "Successfully loaded aliases from $AliasFile"
            } elseif ($AliasFileType -eq ".psd1") {
                # If it's a .psd1 file, import it as PowerShell Data File
                Write-Verbose "Importing alias file as PowerShell Data File: $AliasFile"
                $Aliases = Import-PowerShellDataFile -Path $AliasFile -ErrorAction Stop

                ForEach ($alias in $Aliases.GetEnumerator()) {
                    try {
                        Set-Alias -Name $alias.Key -Value $alias.Value -Scope Global -ErrorAction Stop
                        Write-Verbose "Set command alias: $($alias.Key) -> $($alias.Value)"
                    } catch {
                        Write-Warning ("Failed to set command alias {0} -> {1}: {2}" -f $alias.Key, $alias.Value, $_.Exception.Message)
                    }
                }

                Write-Verbose "Successfully imported $($Aliases.Count) command aliases"
            }
        } catch {
            Write-Error "An error occurred while importing aliases from ${AliasFile}: $_"
        }
    }

    End {
        Write-Verbose "[END]: Import-Aliases"
    }
}
