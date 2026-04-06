# Windows dialog and UI interaction functions
Function Get-Folder {
    [CmdletBinding(ConfirmImpact = 'None')]
    [OutputType([String[]])]
    Param(
        [Alias('InitialDirectory', 'RootFolder')]
        [String]$Path = "$pwd",
        [Switch]$NoNewFolder,
        [Alias('Description')]
        [String]$Title
    )

    Begin {
        Write-Verbose -Message "Starting [$($MyInvocation.Mycommand)]"
    }

    Process {
        try {
            Add-Type -AssemblyName System.Windows.Forms

            $FolderBrowserDialog = New-Object -TypeName System.Windows.Forms.FolderBrowserDialog
            $FolderBrowserDialog.RootFolder = 'MyComputer'
            $FolderBrowserDialog.SelectedPath = $Path
            if ($NoNewFolder) { $FolderBrowserDialog.ShowNewFolderButton = $false }
            if ($Title) { $FolderBrowserDialog.Description = $Title }

            $Result = $FolderBrowserDialog.ShowDialog()

            if ($Result -eq 'OK') {
                [array] $ReturnArray = $FolderBrowserDialog.SelectedPath
                Write-Output -InputObject (, $ReturnArray)
            }
        } catch {
            Write-Error "Failed to get folder: $_"
        }
    }

    End {
        Write-Verbose -Message "Ending [$($MyInvocation.Mycommand)]"
    }
}

Function Get-File {
    [CmdletBinding(ConfirmImpact = 'None')]
    [OutputType([String[]])]
    Param(
        [Alias('InitialDirectory')]
        [String]$Path = "$pwd",
        [Switch]$MultiSelect,
        [String]$Filter = "All files|*.*",
        [String]$Title = "Select File"
    )

    Begin {
        Write-Verbose -Message "Starting [$($MyInvocation.Mycommand)]"
    }

    Process {
        try {
            Add-Type -AssemblyName System.Windows.Forms

            $OpenFileDialog = New-Object -TypeName System.Windows.Forms.OpenFileDialog
            $OpenFileDialog.InitialDirectory = $Path
            $OpenFileDialog.Filter = $Filter
            $OpenFileDialog.Multiselect = $MultiSelect
            $OpenFileDialog.Title = $Title

            $Result = $OpenFileDialog.ShowDialog()

            if ($Result -eq 'OK') {
                Write-Output -InputObject $OpenFileDialog.FileNames
            }
        } catch {
            Write-Error "Failed to get file: $_"
        }
    }

    End {
        Write-Verbose -Message "Ending [$($MyInvocation.Mycommand)]"
    }
}

Function Invoke-Notepad {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [String]$Path
    )

    Process {
        try {
            if ($Path) {
                Start-Process notepad.exe -ArgumentList $Path
            } else {
                Start-Process notepad.exe
            }
        } catch {
            Write-Error "Failed to invoke Notepad: $_"
        }
    }
}
