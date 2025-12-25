@{
    # PSReadLine Configuration

    # Options
    Options = @{
        EditMode = 'Windows'
        PredictionSource = 'HistoryAndPlugin'
        PredictionViewStyle = 'ListView'
        HistoryNoDuplicates = $true
        HistorySearchCursorMovesToEnd = $true
        TerminateOrphanedConsoleApps = $true
    }

    # Key Handlers
    KeyHandlers = @{
        'Tab' = @{
            Function = 'MenuComplete'
        }
    }

    # Key Bindings
    KeyBindings = @{
        'Alt+RightArrow' = @{
            Function = 'AcceptNextSuggestionWord'
        }
        'Ctrl+Home' = @{
            Function = 'BeginningOfLine'
        }
        'Ctrl+End' = @{
            Function = 'EndOfLine'
        }
        'Ctrl+Shift+Home' = @{
            Function = 'SelectBackwardsLine'
        }
        'Ctrl+Shift+End' = @{
            Function = 'SelectLine'
        }
        # Capture Screen (Interactive Selection from Terminal via "Chord")
        'Ctrl+d,Ctrl+c' = @{
            Function = 'CaptureScreen'
        }
        'Ctrl+Shift+e'   = @{
            Description = 'Edit Current Directory with $Env:Editor'
            ScriptBlock = {
                $currentPath = Get-Location
                if ($Env:Editor) {
                    & $Env:Editor $currentPath
                } else {
                    Write-Host "No editor environment variable set. Will attempt to open with code."
                    if (Get-Command code -ErrorAction SilentlyContinue) {
                        & code $currentPath
                    } else {
                        Write-Host "Launching with notepad"
                        notepad $currentPath
                    }
                }
            }
        }

        'F7' = @{
            BriefDescription = 'History'
            LongDescription = 'Show command history'
            ScriptBlock = {
                $pattern = $null
                [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
                if ($pattern) {
                    $pattern = [regex]::Escape($pattern)
                }

                $history = [System.Collections.ArrayList]@(
                    $last = ''
                    $lines = ''
                    foreach ($line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath)) {
                        if ($line.EndsWith('`')) {
                            $line = $line.Substring(0, $line.Length - 1)
                            $lines = if ($lines) {
                                "$lines`n$line"
                            } else {
                                $line
                            }
                            continue
                        }

                        if ($lines) {
                            $line = "$lines`n$line"
                            $lines = ''
                        }

                        if (($line -cne $last) -and (!$pattern -or ($line -match $pattern))) {
                            $last = $line
                            $line
                        }
                    }
                )
                $history.Reverse()

                $command = $history | Out-GridView -Title History -PassThru
                if ($command) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
                }
            }
        }

        'Alt+(' = @{
            BriefDescription = 'ParenthesizeSelection'
            LongDescription = 'Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis'
            ScriptBlock = {
                param($key, $arg)

                $selectionStart = $null
                $selectionLength = $null
                [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

                $line = $null
                $cursor = $null
                [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
                if ($selectionStart -ne -1) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
                    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
                } else {
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
                    [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
                }
            }
        }

        "Alt+'" = @{
            BriefDescription = 'ToggleQuoteArgument'
            LongDescription = 'Toggle quotes on the argument under the cursor'
            ScriptBlock = {
                param($key, $arg)

                $ast = $null
                $tokens = $null
                $errors = $null
                $cursor = $null
                [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

                $tokenToChange = $null
                foreach ($token in $tokens) {
                    $extent = $token.Extent
                    if ($extent.StartOffset -le $cursor -and $extent.EndOffset -ge $cursor) {
                        $tokenToChange = $token

                        # If the cursor is at the end (it's really 1 past the end) of the previous token,
                        # we only want to change the previous token if there is no token under the cursor
                        if ($extent.EndOffset -eq $cursor -and $foreach.MoveNext()) {
                            $nextToken = $foreach.Current
                            if ($nextToken.Extent.StartOffset -eq $cursor) {
                                $tokenToChange = $nextToken
                            }
                        }
                        break
                    }
                }

                if ($tokenToChange -ne $null) {
                    $extent = $tokenToChange.Extent
                    $tokenText = $extent.Text
                    if ($tokenText[0] -eq '"' -and $tokenText[-1] -eq '"') {
                        # Switch to no quotes
                        $replacement = $tokenText.Substring(1, $tokenText.Length - 2)
                    } elseif ($tokenText[0] -eq "'" -and $tokenText[-1] -eq "'") {
                        # Switch to double quotes
                        $replacement = '"' + $tokenText.Substring(1, $tokenText.Length - 2) + '"'
                    } else {
                        # Add single quotes
                        $replacement = "'" + $tokenText + "'"
                    }

                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                        $extent.StartOffset,
                        $tokenText.Length,
                        $replacement)
                }
            }
        }
    }
}
