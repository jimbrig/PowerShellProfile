function Get-WifiNetworks {
    [CmdletBinding()]
    param (
        [Parameter()] [switch] $Save,
        [Parameter()] [string] $OutputPath = "$env:USERPROFILE\Desktop\WiFiNetworks.csv"
    )


    $Result = @()

    $wifi = $(netsh.exe wlan show profiles)

    if ($wifi -match 'There is no wireless interface on the system.') {
        Write-Output $wifi
        exit
    }

    $ListOfSSID = ($wifi | Select-String -Pattern '\w*All User Profile.*: (.*)' -AllMatches).Matches | ForEach-Object { $_.Groups[1].Value }
    # $NumberOfWifi = $ListOfSSID.count
    # Write-Warning "[$(Get-Date)] I've found $NumberOfWifi Wi-Fi Connection settings stored in your system $($env:computername) : "
    foreach ($SSID in $ListOfSSID) {
        try {
            $passphrase = ($(netsh.exe wlan show profiles name=`"$SSID`" key=clear) |
                Select-String -Pattern '.*Key Content.*:(.*)' -AllMatches).Matches |
            ForEach-Object { $_.Groups[1].Value }
        } catch {
            $passphrase = 'N/A'
        }
        $obj = [PSCustomObject]@{
            Name       = ($SSID).Trim()
            PassPhrase = ($passphrase).Trim()
        }
        $Result += $obj
    }

    if ($Save.IsPresent) {
        if (Test-Path $OutputPath) {
            Remove-Item $OutputPath -Force -ea 0
        }
        $Result | Export-Csv $OutputPath -NoClobber -Force
        Write-Output "Saved WiFi networks to $OutputPath"
    } else {
        Write-Output $Result | Format-Table -AutoSize
    }

    return $Result

}
