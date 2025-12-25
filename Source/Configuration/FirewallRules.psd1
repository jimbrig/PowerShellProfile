@{
    Programs = @(
        'C:\\Program Files\\R\\R-*\\bin\\R.exe'
        'C:\\Program Files\\R\\R-*\\bin\\Rscript.exe'
        'C:\\Program Files\\R\\R-*\\bin\\Rterm.exe'
        'C:\\Program Files\\R\\R-*\\bin\\Rgui.exe'
        'C:\\Program Files\\R\\R-*\\bin\\Rcmd.exe'
        'C:\\Program Files\\RStudio\\rstudio.exe'
        'C:\\Program Files\\Positron\\Positron.exe'
        'C:\\Program Files\\PowerShell\\7\\pwsh.exe'
        'C:\\Program Files\\PowerShell\\7-preview\\pwsh-preview.exe'
        'C:\\Program Files\\Git\\cmd\\git.exe'
        'C:\\Program Files\\GitHub CLI\\gh.exe'
        'C:\\Program Files\\Docker\\Docker\\resources\\bin\\docker.exe'
    )

    Ports = @(
        22    # SSH
        23    # Telnet
        80    # HTTP
        443   # HTTPS
        3000  # Docker
        3838  # Shiny
        8000  # Shiny
        8080  # Shiny
        8888  # Jupyter
        5432  # PostgreSQL
        6432  # PgBouncer
    )
}
