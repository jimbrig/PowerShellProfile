<#
.SYNOPSIS
    Converts all jpg+png files to webp format in the current directory.
.DESCRIPTION
    Converts all jpg+png files to webp format in the current directory.
.EXAMPLE
    cwebp-multi
.NOTES
    Version      : 0.1.1
    Created by   : asheroto
.LINK
    Project Site: https://github.com/asheroto/cwebp-multi
#>

Get-ChildItem |`
        Where-Object { $_.Extension -eq ".jpg" -or $_.Extension -eq ".png" } |`
            ForEach-Object { Invoke-Expression ("cwebp " + $_.Name + " -o " + $_.BaseName + ".webp") }
