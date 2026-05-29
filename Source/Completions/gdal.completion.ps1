<#
    .SYNOPSIS
        Registers GDAL shell completion for PowerShell.
    .DESCRIPTION
        Uses GDAL JSON usage metadata to provide native PowerShell completion.
    .LINK
        https://gdal.org/en/stable/programs/gdal.html
#>

$gdalCommand = Get-Command gdal -ErrorAction SilentlyContinue
if (-not $gdalCommand) {
    Write-Debug 'gdal command not found; skipping GDAL completion registration.'
    return
}

$script:GdalUsageRoot = $null
$script:GdalUsageLoadAttempted = $false

function Get-GdalUsageRoot {
    if ($script:GdalUsageLoadAttempted) {
        return $script:GdalUsageRoot
    }

    $script:GdalUsageLoadAttempted = $true
    try {
        $json = & $gdalCommand.Source --json-usage 2>$null
        if ($LASTEXITCODE -eq 0 -and $json) {
            $script:GdalUsageRoot = $json | ConvertFrom-Json -Depth 100
        }
    } catch {
        $script:GdalUsageRoot = $null
    }

    return $script:GdalUsageRoot
}

function Get-GdalUsageNode {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Root,
        [Parameter(Mandatory = $true)]
        [string[]]$Tokens
    )

    $node = $Root
    foreach ($token in $Tokens) {
        if ([string]::IsNullOrWhiteSpace($token) -or $token.StartsWith('-')) {
            break
        }

        $nextNode = $node.sub_algorithms | Where-Object { $_.name -eq $token } | Select-Object -First 1
        if (-not $nextNode) {
            break
        }

        $node = $nextNode
    }

    return $node
}

function Get-GdalUsageSuggestions {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Node
    )

    $subCommands = @($Node.sub_algorithms | ForEach-Object { $_.name })
    $inputOptions = @($Node.input_arguments | ForEach-Object { "--$($_.name)" })
    $outputOptions = @($Node.output_arguments | ForEach-Object { "--$($_.name)" })

    return @($subCommands + $inputOptions + $outputOptions | Where-Object { $_ } | Sort-Object -Unique)
}

$defaultSuggestions = @('convert', 'dataset', 'driver', 'info', 'mdim', 'pipeline', 'raster', 'vector', 'vsi')
$gdalCompleter = {
    param(
        $wordToComplete,
        $commandAst,
        $cursorPosition
    )

    $line = $commandAst.ToString()
    if ([string]::IsNullOrWhiteSpace($line)) {
        return
    }

    $tokens = [regex]::Matches($line, '[^\s]+') | ForEach-Object { $_.Value }
    if (-not $tokens -or @('gdal', 'gdal.exe') -notcontains $tokens[0]) {
        return
    }

    $hasTrailingSpace = [string]::IsNullOrEmpty($wordToComplete) -or ($cursorPosition -gt 0 -and $line.Length -ge $cursorPosition -and [char]::IsWhiteSpace($line[$cursorPosition - 1]))
    $args = if ($tokens.Count -gt 1) { @($tokens[1..($tokens.Count - 1)]) } else { @() }
    $pathTokens = if (-not $hasTrailingSpace -and $args.Count -gt 0) { @($args[0..($args.Count - 2)]) } else { $args }
    $effectiveWordToComplete = if ($hasTrailingSpace) { '' } else { $wordToComplete }

    $root = Get-GdalUsageRoot
    $suggestions = if ($root) {
        $node = Get-GdalUsageNode -Root $root -Tokens $pathTokens
        Get-GdalUsageSuggestions -Node $node
    } else {
        $defaultSuggestions
    }

    $suggestions |
    Where-Object { $_ -and $_ -like "$effectiveWordToComplete*" } |
    Sort-Object -Unique |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -Native -CommandName gdal -ScriptBlock $gdalCompleter
Register-ArgumentCompleter -Native -CommandName gdal.exe -ScriptBlock $gdalCompleter
