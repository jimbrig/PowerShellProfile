function Get-WindowsBuild() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true
        )]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    begin {
        $Table = New-Object System.Data.DataTable
        $Table.Columns.AddRange(@("ComputerName", "Windows Edition", "Version", "OSBuild"))
    }

    process {
        Foreach ($Computer in $ComputerName) {
            $Code = {
                $ProductName = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName).ProductName
                try {
                    $Version = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID -ErrorAction Stop).ReleaseID
                } catch {
                    $Version = "N/A"
                }
                $CurrentBuild = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuild).CurrentBuild
                $UBR = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name UBR).UBR
                $OSVersion = $CurrentBuild + "." + $UBR

                $TempTable = New-Object System.Data.DataTable
                $TempTable.Columns.AddRange(@("ComputerName", "Windows Edition", "Version", "OSBuild"))
                [void]$TempTable.Rows.Add($env:COMPUTERNAME, $ProductName, $Version, $OSVersion)

                return $TempTable
            }

            if ($Computer -eq $env:COMPUTERNAME) {
                $Result = Invoke-Command -ScriptBlock $Code
                [void]$Table.Rows.Add($Result.Computername, $Result.'Windows Edition', $Result.Version, $Result.'OSBuild')
            } else {
                if (Test-Connection $Computer -count 1 -ErrorAction SilentlyContinue) {
                    try {
                        $Result = Invoke-Command -ComputerName $Computer -ScriptBlock $Code -ErrorAction Stop
                        [void]$Table.Rows.Add($Result.Computername, $Result.'Windows Edition', $Result.Version, $Result.'OSBuild')
                    } catch {
                        $_
                    }
                } else {
                    [void]$Table.Rows.Add($Computer, "OFFLINE", "OFFLINE", "OFFLINE")
                }
            }
        }
    }
    end {
        Return $Table
    }
}
