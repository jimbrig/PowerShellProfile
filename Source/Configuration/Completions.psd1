@{
    Settings = @{
        EnablePredictiveCompletions = $true
        Disabled = $false
        Lazy = $true
    }
    Completions = @{
        'aichat' = @{
            File = 'aichat.completion.ps1'
            Disabled = $false
            Check = {
                Get-Command aichat -ErrorAction SilentlyContinue
            }
        }
        'azcli' = @{
            File = 'azcli.completion.ps1'
            Disabled = $false
            Check = {
                Get-Command az -ErrorAction SilentlyContinue
            }
        }
        'ghcli' = @{
            File = 'ghcli.completion.ps1'
            Disabled = $false
            Check = {
                Get-Command gh -ErrorAction SilentlyContinue
            }
        }
    }
}
