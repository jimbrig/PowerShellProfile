#Requires -Module Pester

<#
    .SYNOPSIS
        Tests the Docker installation.

    .DESCRIPTION
        Verifies the Docker CLI is installed and Docker Compose v2 is available.
        The engine-reachability check only runs when the Docker Desktop Service
        (com.docker.service) is running; it is skipped otherwise, since the
        engine is not expected to be running at all times.
#>

BeforeDiscovery {
    $script:DockerCliAvailable = [bool] (Get-Command docker -ErrorAction SilentlyContinue)

    $DockerService = Get-Service -Name 'com.docker.service' -ErrorAction SilentlyContinue
    $script:DockerEngineRunning = $DockerCliAvailable -and $DockerService -and ($DockerService.Status -eq 'Running')
}

Describe 'Docker Installation and Configuration' -Tag 'System', 'Docker' {

    It 'Checks that the Docker CLI is installed' {
        Get-Command docker -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Checks that Docker Compose v2 is available' -Skip:(-not $DockerCliAvailable) {
        $PSNativeCommandUseErrorActionPreference = $false
        docker compose version 2>&1 | Out-Null
        $LASTEXITCODE | Should -Be 0 -Because 'the "docker compose" (v2) subcommand should be installed'
    }

    It 'Checks that the Docker engine is reachable' -Skip:(-not $DockerEngineRunning) {
        $PSNativeCommandUseErrorActionPreference = $false
        docker info 2>&1 | Out-Null
        $LASTEXITCODE | Should -Be 0 -Because 'the Docker engine should respond while Docker Desktop Service is running'
    }
}
