@{
    ExclusionPaths      = @(
        "C:\\Program Files\\PowerShell\\7",
        "C:\\Program Files\\PowerShell\\7-preview",
        "C:\\Program Files\\R",
        "C:\\Program Files\\R\\bin",
        "C:\\Program Files\\RStudio",
        "C:\\Program Files\\Docker",
        "C:\\Program Files\\Docker\\Docker",
        "C:\\Program Files\\Docker\\cli-plugins",
        'N:\\',
        'X:\\'
    )
    ExclusionExtensions = @(
        '.exe',
        '.dll',
        '.cmd',
        '.bat',
        '.ps1',
        '.psm1',
        '.psd1',
        '.R',
        '.Rmd',
        '.Rprofile',
        '.Rhistory',
        '.Rproj',
        '.Rproj.user',
        '.RData',
        '.rda',
        '.rds',
        '.py',
        '.sh',
        '.bash',
        '.zsh',
        '.c',
        '.cpp',
        '.js',
        '.json',
        '.ts',
        '.tsx',
        '.jsx',
        '.xml',
        '.yaml',
        '.yml'
    )
    ExclusionProcesses  = @(
        # PowerShell
        'powershell.exe',
        'pwsh.exe',
        'pwsh-preview.exe',
        # R
        'R.exe',
        'Rscript.exe',
        'Rterm.exe',
        'Rgui.exe',
        'Rcmd.exe',
        'Rfe.exe',
        'RSetReg.exe',
        'open.exe',
        'rstudio.exe',
        'RStudio.exe',
        'Positron.exe',
        # Python
        'python.exe',
        'pip.exe',
        'uv.exe',
        'poetry.exe',
        # Docker
        'docker.exe',
        'Docker Desktop.exe',
        'Docker desktop.exe',
        'DockerCli.exe',
        'com.docker.admin.exe',
        'com.docker.backend.exe',
        'com.docker.diagnose.exe',
        'compose-bridge.exe',
        'docker-compose.exe',
        'docker.exe',
        'extension-admin.exe',
        'kubectl.exe',
        'docker-credential-wincred.exe',
        'docker-credential-desktop.exe',
        'hub-tool.exe',
        # dotnet
        'dotnet.exe',
        # git
        'git.exe',
        'git-bash.exe',
        'git-cmd.exe',
        'bash.exe',
        'sh.exe',
        'git-lfs.exe',
        'git-gui.exe',
        'gitk.exe',
        'tig.exe',
        # gh
        'gh.exe',
        # chrome
        'chrome.exe',
        'chrome_proxy.exe',
        'chromium.exe',
        # VSCode
        'Code.exe',
        'Code - Insiders.exe',
        'code-tunnel.exe',
        # pandoc
        'pandoc.exe',
        # quarto
        'quarto.exe',
        'quarto.js',
        # powertoys
        'PowerToys.exe'
    )
}
