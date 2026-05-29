# Environment and package management functions
Function Update-Environment {
    try {
        Refresh-Profile
        Refresh-Path
        Refresh-Module
        Refresh-Function
        Refresh-Alias
        Refresh-Variable
    } catch {
        Write-Error "Failed to update environment: $_"
    }
}



Function Update-Chocolatey {
    try {
        choco upgrade all -y
    } catch {
        Write-Error "Failed to update Chocolatey packages: $_"
    }
}

Function Update-Scoop {
    try {
        scoop update
        scoop update *
    } catch {
        Write-Error "Failed to update Scoop packages: $_"
    }
}

Function Update-Python {
    try {
        python -m pip install --upgrade pip
        pip list --outdated --format=json | ConvertFrom-Json | ForEach-Object {
            pip install -U $_.name
        }
    } catch {
        Write-Error "Failed to update Python packages: $_"
    }
}

Function Update-Node {
    try {
        npm update -g
    } catch {
        Write-Error "Failed to update Node packages: $_"
    }
}

Function Update-R {
    try {
        Rscript -e "update.packages(ask = FALSE)"
    } catch {
        Write-Error "Failed to update R packages: $_"
    }
}

Function Update-Pip {
    try {
        python -m pip install --upgrade pip
        pip freeze | ForEach-Object {
            pip install -U $_.Split('==')[0]
        }
    } catch {
        Write-Error "Failed to update Pip packages: $_"
    }
}

Function Update-Windows {
    try {
        Install-WindowsUpdate -AcceptAll -AutoReboot
    } catch {
        Write-Error "Failed to update Windows: $_"
    }
}
