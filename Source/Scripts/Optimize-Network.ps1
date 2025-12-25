Invoke-OptimizeNetwork {
    <#
    .SYNOPSIS
        Optimize network settings for better performance.
    .DESCRIPTION
        Applies a series of network tweaks using `netsh` to enhance TCP performance.

        - Disable TCP heuristics
        - Set congestion provider to CTCP
        - Enable Receive Side Scaling (RSS)
        - Enable Explicit Congestion Notification (ECN)
        - Disable TCP timestamps
        - Enable TCP Fast Open
        - Set Initial Congestion Window (ICW) to 10
        - Set MTU to 1500 for Wi-Fi and Ethernet interfaces
    .FUNCTIONALITY
        Network Optimization
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Begin {
        Write-Debug '[Begin]: Invoke-OptimizeNetwork'
        $ErrorActionPreference = 'Stop'
        Write-Host 'Applying network tweaks...' -ForegroundColor Cyan
    }

    Process {
        Write-Debug '[Process]: Invoke-OptimizeNetwork'

        Write-Host 'Disabling TCP heuristics...' -ForegroundColor Yellow
        netsh int tcp set heuristics disabled

        Write-Host 'Setting congestion provider to CTCP...' -ForegroundColor Yellow
        netsh int tcp set supplemental template=internet congestionprovider=ctcp

        Write-Host 'Enabling Receive Side Scaling (RSS)...' -ForegroundColor Yellow
        netsh int tcp set global rss=enabled

        Write-Host 'Enabling Explicit Congestion Notification (ECN)...' -ForegroundColor Yellow
        netsh int tcp set global ecncapability=enabled

        Write-Host 'Disabling TCP timestamps...' -ForegroundColor Yellow
        netsh int tcp set global timestamps=disabled

        Write-Host 'Enabling TCP Fast Open...' -ForegroundColor Yellow
        netsh int tcp set global fastopen=enabled

        Write-Host 'Setting Initial Congestion Window (ICW) to 10...' -ForegroundColor Yellow
        netsh int tcp set global fastopenfallback=enabled

        Write-Host 'Setting MTU to 1500 for Wi-Fi and Ethernet interfaces...' -ForegroundColor Yellow
        netsh int tcp set supplemental template=custom icw=10

        Write-Host 'Applying MTU settings...' -ForegroundColor Yellow
        netsh interface ipv4 set subinterface 'Wi-Fi' mtu=1500 store=persistent

        Write-Host 'Applying MTU settings for Ethernet...' -ForegroundColor Yellow
        netsh interface ipv4 set subinterface Ethernet mtu=1500 store=persistent

    }

    End {
        Write-Debug '[End]: Invoke-OptimizeNetwork'
        Write-Host 'Network tweaks applied successfully.' -ForegroundColor Green
    }

}

Invoke-UndoOptimizeNetwork {
    <#
    #>
    [CmdletBinding()]
    param()

    Begin {
        Write-Debug
    }

    Process {
        Write-Debug

        netsh int tcp set heuristics enabled
        netsh int tcp set supplemental template=internet congestionprovider=default
        netsh int tcp set global rss=default
        netsh int tcp set global ecncapability=default
        netsh int tcp set global timestamps=default
        netsh int tcp set global fastopen=default
        netsh int tcp set global fastopenfallback=default
        netsh int tcp set supplemental template=custom icw=4
        netsh interface ipv4 set subinterface 'Wi-Fi' mtu=1500 store=persistent
        netsh interface ipv4 set subinterface Ethernet mtu=1500 store=persistent
    }

    End {
        Write-Debug
    }
}
