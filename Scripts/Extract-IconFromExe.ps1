
<#PSScriptInfo

.VERSION 1.0

.GUID 028d12d4-b633-4bc8-a6c4-a50642ae017c

.AUTHOR Jimmy Briggs

.COMPANYNAME Jimmy Briggs

.COPYRIGHT Jimmy Briggs | 2022

.TAGS PowerShell Icons Extraction Utility Tool Pictures

.LICENSEURI

.PROJECTURI https://github.com/jimbrig

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
    A script for extracting an icon (.ico) from an executable (.exe). 

.LINK 
    https://community.spiceworks.com/topic/592770-extract-icon-from-exe-powershell

.EXAMPLE
    .\Extract-IconFromExe.ps1 -Path "C:\Windows\System32\calc.exe" -Destination "C:\Temp" -Name "Calculator" -Format "ico"

.PARAMETER Path
    The path to the executable file.

.PARAMETER Destination
    The path to the destination folder.

.PARAMETER Name
    The name of the icon file.

.PARAMETER Format
    The format of the icon file.
#> 
[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(Position = 0, Mandatory,HelpMessage = 'Specify the path to the file.')]
    [ValidateScript({ Test-Path $_ })]
    [string]$Path,

    [Parameter(HelpMessage = 'Specify the folder to save the file.')]
    [ValidateScript({ Test-Path $_ })]
    [string]$Destination = '.',

    [parameter(HelpMessage = 'Specify an alternate base name for the new image file. Otherwise, the source name will be used.')]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter(HelpMessage = 'What format do you want to use? The default is png.')]
    [ValidateSet('ico','bmp','png','jpg','gif')]
    [string]$Format = 'png'
)

Write-Verbose "Starting $($MyInvocation.MyCommand)"

Try {
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
} Catch {
    Write-Warning 'Failed to import System.Drawing'
    Throw $_
}

Switch ($format) {
    'ico' { $ImageFormat = 'icon' }
    'bmp' { $ImageFormat = 'Bmp' }
    'png' { $ImageFormat = 'Png' }
    'jpg' { $ImageFormat = 'Jpeg' }
    'gif' { $ImageFormat = 'Gif' }
}

$file = Get-Item $path
Write-Verbose "Processing $($file.fullname)"
#convert destination to file system path
$Destination = Convert-Path -Path $Destination

if ($Name) {
    $base = $Name
} else {
    $base = $file.BaseName
}

#construct the image file name
$out = Join-Path -Path $Destination -ChildPath "$base.$format"

Write-Verbose "Extracting $ImageFormat image to $out"
$ico = [System.Drawing.Icon]::ExtractAssociatedIcon($file.FullName)

if ($ico) {
    #WhatIf (target, action)
    if ($PSCmdlet.ShouldProcess($out, 'Extract icon')) {
        $ico.ToBitmap().Save($Out,$Imageformat)
        Get-Item -Path $out
    }
} else {
    #this should probably never get called
    Write-Warning "No associated icon image found in $($file.fullname)"
}

Write-Verbose "Ending $($MyInvocation.MyCommand)"


