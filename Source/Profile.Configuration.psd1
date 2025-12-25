@{
    Settings = @{
        Order = @(
            'Aliases',
            'Completions',
            'Functions',
            'Modules',
            'DefaultParams',
            'PSReadLine',
            'Style',
            'Prompt'
        )
    }
    Components = @{
        Aliases = @{
            Disabled = $false
            File = 'Aliases.psd1'
        }
        Completions = @{
            Disabled = $false
            File = 'Completions.psd1'
        }
        Functions = @{
            Disabled = $false
            File = 'Functions.psd1'
        }
        Modules = @{
            Disabled = $false
            File = 'Modules.psd1'
        }
        DefaultParams = @{
            Disabled = $false
            File = 'DefaultParams.psd1'
        }
        PSReadLine    = @{
            Disabled = $false
            File     = 'PSReadLine.psd1'
        }
        Style = @{
            Disabled = $false
            File = 'Style.psd1'
        }
        Prompt = @{
            Disabled = $false
            File = 'Prompt.psd1'
        }
    }
}
