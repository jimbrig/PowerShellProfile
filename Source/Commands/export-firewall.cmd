@echo off
if "%~1"=="" (
    echo Usage: export-firewall.cmd ^<output-file^>
    exit /b 1
)

netsh advfirewall export "%~1.wfw"
