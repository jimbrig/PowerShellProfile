Function Update-ModulesReadMe {
    <#
    .SYNOPSIS
    #>

    begin {
        $script:ProfilePath = Split-Path -Path $PROFILE -Parent
        $script:ModulesPath = Join-Path $ProfilePath "Modules"
        $script:READMEPath = Join-Path $ModulesPath "README.md"
    }

    process {
        # get modules
        $Modules = Get-InstalledPSResource | Where-Object { $_.Type -eq 'Module' }
        $ModulesList = $Modules | Select-Object Name, Version | ForEach-Object {
            " - **$($_.Name)** ($($_.Version))"
        }

        # get current content
        $content = Get-Content -Path $READMEPath -Raw

        # update content
        $newContent = $content -replace '(?s)<!-- BEGIN_MODULES -->.*<!-- END_MODULES -->', "<!-- BEGIN_MODULES -->`n$($ModulesList -join "`n")`n<!-- END_MODULES -->"

        # write content
        Set-Content -Path $READMEPath -Value $newContent

        Write-Color "✔️ Successfully updated ", "README.md ", "." -Color "green", "red", "green"
    }

    end {

    }
}

Function New-ModulesFile {
    <#
    .SYNOPSIS
    #>

    begin {
        $script:ProfilePath = Split-Path -Path $PROFILE -Parent
        $script:ModulesPath = Join-Path $ProfilePath "Modules"
        $script:JSONPath = Join-Path $ModulesPath "modules.json"
        $script:YAMLPath = Join-Path $ModulesPath "modules.yml"
        $script:READMEPath = Join-Path $ProfilePath "README.md"
    }

    process {
        # get modules
        $Modules = Get-ChildItem -Directory $ModulesPath

        # create modules.json
        Write-Color "Removing previous ", "modules.json", " file." -Color "green", "red", "green"
        if (test-path $JSONPath) { remove-item -Path $JSONPath }
        $Modules.Name | ConvertTo-Json >> $JSONPath

        # create modules.yaml
        Write-Color "Removing previous ", "modules.yml", " file." -Color "green", "red", "green"
        if (test-path $YAMLPath) { remove-item -Path $YAMLPath }
        $Modules.Name | ConvertTo-Yaml >> $YAMLPath

        # update README.md
        Write-Color "Updating ", "README.md", " file." -Color "green", "red", "green"
        if (test-path $READMEPath) {
            $content = Get-Content -Path $READMEPath -Raw
            $modulesList = @"
### Installed Modules

$(($Modules.Name | Sort-Object | ForEach-Object { "- **$_**" }) -join "`n")

"@
            $newContent = $content -replace '(?s)<!-- BEGIN_MODULES -->.*<!-- END_MODULES -->', "<!-- BEGIN_MODULES -->`n$modulesList<!-- END_MODULES -->"
            Set-Content -Path $READMEPath -Value $newContent
        }

        Write-Color "✔️ Successfully updated ", "modules.json ", "." -Color "green", "red", "green"
        Write-Color "✔️ Successfully updated ", "modules.yml ", "." -Color "green", "red", "green"
        Write-Color "✔️ Successfully updated ", "README.md ", "." -Color "green", "red", "green"
    }

    end {
        $push = Read-Host -Prompt "Push to github? (y/n)"
        if ($push) {
            Set-Location ..
            git add Modules/**
            git commit -m "Updated modules."
            git push
        }
        Write-Color "✔️ Successfully pushed to github."
    }
}

New-ModulesFile

