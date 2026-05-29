Function Get-PublicIP() {
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0)]$IP
    )

    try {
        if ($IP) {
            $ipinfo = Invoke-RestMethod http://ipinfo.io/$IP/json
        } else {
            $ipinfo = Invoke-RestMethod http://ipinfo.io/json
        }
        [PSCustomObject]@{
            IP           = $ipinfo.ip
            City         = $ipinfo.city
            Region       = $ipinfo.region
            Country      = $ipinfo.country
            Coord        = $ipinfo.loc
            Organization = $ipinfo.org
            Postal       = $ipinfo.Postal
            TimeZone     = $ipinfo.timezone
        }
    } catch {
        Write-Error "$($_.Exception.Message)"
    }
}
