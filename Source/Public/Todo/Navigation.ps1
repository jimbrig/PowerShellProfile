# Navigation functions for common locations and directory traversal

Function Set-LocationParent {
    try {
        Set-Location -Path '..'
    } catch {
        Write-Error "Failed to set location to Parent: $_"
    }
}

Function Set-LocationRoot {
    try {
        Set-Location -Path '/'
    } catch {
        Write-Error "Failed to set location to Root: $_"
    }
}

Function Set-LocationHome {
    try {
        Set-Location -Path $HOME
    } catch {
        Write-Error "Failed to set location to Home: $_"
    }
}

Function Set-LocationBin {
    try {
        # Set location to the Bin directory under the user's profile
        $binPath = Join-Path -Path $env:USERPROFILE -ChildPath 'bin'
        if (Test-Path $binPath) {
            Set-Location -Path $binPath
        } else {
            Write-Warning "Bin directory not found: $binPath"
        }
    } catch {
        Write-Error "Failed to set location to Bin: $_"
    }
}

Function Set-LocationTools {
    try {
        # Set location to the Tools directory under the user's profile
        $toolsPath = Join-Path -Path $env:USERPROFILE -ChildPath 'tools'
        if (Test-Path $toolsPath) {
            Set-Location -Path $toolsPath
        } else {
            Write-Warning "Tools directory not found: $toolsPath"
        }
    } catch {
        Write-Error "Failed to set location to Tools: $_"
    }
}

Function Set-LocationTemp {
    try {
        # Set location to the temporary directory
        $tempPath = $env:TEMP
        if (Test-Path $tempPath) {
            Set-Location -Path $tempPath
        } else {
            Write-Warning "Temporary directory not found: $tempPath"
        }
    } catch {
        Write-Error "Failed to set location to Temp: $_"
    }
}

Function Set-LocationConfig {
    try {
        # Set location to the configuration directory under the user's profile
        $configPath = Join-Path -Path $env:USERPROFILE -ChildPath '.config'
        if (Test-Path $configPath) {
            Set-Location -Path $configPath
        } else {
            Write-Warning "Configuration directory not found: $configPath"
        }
    } catch {
        Write-Error "Failed to set location to Config: $_"
    }
}

Function Set-LocationOneDrive {
    try {
        # Set location to the OneDrive directory under the user's profile
        $oneDrivePath = Join-Path -Path $env:USERPROFILE -ChildPath 'OneDrive'
        if (Test-Path $oneDrivePath) {
            Set-Location -Path $oneDrivePath
        } else {
            Write-Warning "OneDrive directory not found: $oneDrivePath"
        }
    } catch {
        Write-Error "Failed to set location to OneDrive: $_"
    }
}

Function Set-LocationDotFiles {
    try {
        # Set location to the dotfiles directory under the user's profile
        $dotFilesPath = Join-Path -Path $env:USERPROFILE -ChildPath '.dotfiles'
        if (Test-Path $dotFilesPath) {
            Set-Location -Path $dotFilesPath
        } else {
            Write-Warning "Dotfiles directory not found: $dotFilesPath"
        }
    } catch {
        Write-Error "Failed to set location to Dotfiles: $_"
    }
}

Function Set-LocationDesktop {
    try {
        Set-Location -Path "$env:USERPROFILE\Desktop"
    } catch {
        Write-Error "Failed to set location to Desktop: $_"
    }
}

Function Set-LocationDownloads {
    try {
        Set-Location -Path "$env:USERPROFILE\Downloads"
    } catch {
        Write-Error "Failed to set location to Downloads: $_"
    }
}

Function Set-LocationDocuments {
    try {
        Set-Location -Path "$env:USERPROFILE\Documents"
    } catch {
        Write-Error "Failed to set location to Documents: $_"
    }
}

Function Set-LocationPictures {
    try {
        Set-Location -Path "$env:USERPROFILE\Pictures"
    } catch {
        Write-Error "Failed to set location to Pictures: $_"
    }
}

Function Set-LocationMusic {
    try {
        Set-Location -Path "$env:USERPROFILE\Music"
    } catch {
        Write-Error "Failed to set location to Music: $_"
    }
}

Function Set-LocationVideos {
    try {
        Set-Location -Path "$env:USERPROFILE\Videos"
    } catch {
        Write-Error "Failed to set location to Videos: $_"
    }
}

Function Set-LocationDevDrive {
    try {
        Set-Location -Path 'Dev:'
    } catch {
        Write-Error "Failed to set location to DevDrive: $_"
    }
}

Function Set-LocationPSProfile {
    try {
        # Set location to the PowerShell profile directory
        $profilePath = [System.IO.Path]::GetDirectoryName($PROFILE)
        if ($profilePath) {
            Set-Location -Path $profilePath
        } else {
            Write-Error "Failed to determine PowerShell profile path."
        }
    } catch {
        Write-Error "Failed to set location to PowerShell profile: $_"
    }
}

Function Set-LocationWSL {
    try {
        $WSLPath = '\\wsl.localhost\Ubuntu\'
        Set-Location -Path $WSLPath
    } catch {
        Write-Error "Failed to set location to WSL: $_"
    }
}

Function cd... {
    try {
        Set-Location -Path '..\..'
    } catch {
        Write-Error "Failed to change directory: $_"
    }
}

Function cd.... {
    try {
        Set-Location -Path '..\..\..'
    } catch {
        Write-Error "Failed to change directory: $_"
    }
}

# Drive shortcuts
Function HKLM: {
    try {
        Set-Location HKLM:
    } catch {
        Write-Error "Failed to set location to HKLM: $_"
    }
}

Function HKCU: {
    try {
        Set-Location HKCU:
    } catch {
        Write-Error "Failed to set location to HKCU: $_"
    }
}

Function Env: {
    try {
        Set-Location Env:
    } catch {
        Write-Error "Failed to set location to Env: $_"
    }
}
