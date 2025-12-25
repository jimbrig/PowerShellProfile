@{
    Run          = @{
        Path     = @(
            'Tests\System\*.Tests.ps1'
            'Tests\Profile\*.Tests.ps1'
        )
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
    TestResult   = @{
        Enabled      = $true
        OutputFormat = 'NUnitXml'
        OutputPath   = 'Tests\TestResults\TestResults.xml'
    }
    CodeCoverage = @{
        Enabled      = $false
    }
}
