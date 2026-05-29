function Get-RebootLogs() {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [int] $MaxEvents
    )
    begin {}

    process {
        try {
            $params = @{
                FilterHashTable = @{
                    LogName = 'System'
                    ID      = '1074'
                }
                ComputerName    = $ComputerName.ToUpper()
                ErrorAction     = 'SilentlyContinue'
                Verbose         = $VerbosePreference
            }
            If ($MaxEvents) {
                $params['MaxEvents'] = $MaxEvents
            }
            Write-Verbose "Gathering $($params.LogName) logs from $($params.ComputerName) with ID 1074."
            Get-WinEvent @params | Where-Object { $_.ID -eq '1074' }
        } catch {
            Write-Error "$($_.Exception.Message)"
        }
    }

    end {}
}
