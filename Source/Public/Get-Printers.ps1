Function Get-Printers() {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [String] $ComputerName
    )

    $Params = @{
        ClassName = 'CIM_Printer'
    }
    if ($ComputerName) { $Params += @{ComputerName = $ComputerName } }
    Get-CimInstance @Params | Select-Object Name, Drivername, Portname, Status, SystemName, local, shared, CapabilityDescriptions
}
