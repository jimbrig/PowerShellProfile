<#
    .SYNOPSIS
        PowerShell (Core) Scripts Data Configuration File
    .DESCRIPTION
        This file is used as both reference as well as for managing and maintaining a library of installed
        PowerShell scripts. This file is used to define the scripts that are installed and available for use
        in the current environment for the current user.
    .NOTES
        File Name      : PowerShell.Scripts.psd1
        Author         : Jimmy Briggs
        Prerequisites  : PowerShell Core Version 7+ and the Microsoft.PowerShell.PSResourceGet Module
    .LINK
        https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.psresourceget/about/about_psresourceget
    .LINK
        https://www.powershellgallery.com/profiles/jimbrig
    .EXAMPLE
        Import-Module -Name 'Microsoft.PowerShell.PSResourceGet'
        Install-PSResource -RequiredResourceFile '.\Scripts\PowerShell.Scripts.psd1'
#>

@{
    "Add-GodModeShortcut"         = @{}
    "Add-ScriptSignature"         = @{}
    "ConvertTo-Markdown"          = @{}
    "ConvertTo-NuSpec"            = @{}
    "Export-PowerCfg"             = @{}
    "Export-PowerQuery"           = @{}
    "Extract-DacPac"              = @{}
    "Extract-IconFromExe"         = @{}
    "FidoScript"                  = @{}
    "Format-ShortDateRegistry"    = @{}
    "Get-GithubRelease"           = @{}
    "Get-InstalledApps"           = @{}
    "Get-OLEDBProvider"           = @{}
    "Get-OpenApiSpecificaion"     = @{}
    "Install-NerdFont"            = @{}
    "Install-OfficeRibbonXEditor" = @{}
    "Invoke-CompactWSLDisk"       = @{}
    "New-RestorePoint"            = @{}
    "New-TrayNotify"              = @{}
    "Read-HostSecret"             = @{}
    "Remove-OldDrivers"           = @{}
    "Set-FolderIcon"              = @{}
    "Set-OfficeInsider"           = @{}
    "Test-IsAdmin"                = @{}
    "Trace-NetworkAdapter"        = @{}
    "Update-PSHelp"               = @{}
    "Update-PSModules"            = @{}
}
