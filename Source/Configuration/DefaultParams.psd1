@{
    # General parameters
    'Out-File:Encoding'                      = 'utf8'

    # Module update parameters
    'Update-Module:Confirm'                  = $False
    'Update-Module:Force'                    = $True
    'Update-Module:Scope'                    = 'CurrentUser'
    'Update-Module:ErrorAction'              = 'SilentlyContinue'

    # PSResource update parameters
    'Update-PSResource:Confirm'              = $False
    'Update-PSResource:Force'                = $True
    'Update-PSResource:ErrorAction'          = 'SilentlyContinue'

    # Help update parameters
    'Update-Help:Force'                      = $True
    'Update-Help:ErrorAction'                = 'SilentlyContinue'

    # PSReadLine parameters
    'Set-PSReadLineOption:WarningAction'     = 'SilentlyContinue'
    'Set-PSReadLineOption:ErrorAction'       = 'SilentlyContinue'
    'Set-PSReadLineKeyHandler:WarningAction' = 'SilentlyContinue'
    'Set-PSReadLineKeyHandler:ErrorAction'   = 'SilentlyContinue'
}
