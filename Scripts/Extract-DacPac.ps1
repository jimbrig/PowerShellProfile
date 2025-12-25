
<#PSScriptInfo

.VERSION 1.0.0

.GUID 3988abfc-2bfd-436d-83f0-67da5ccd8361

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT

.TAGS DacPac MSSQL SQL Server Database Automation Tool

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES
    sqlpackage

.RELEASENOTES


.PRIVATEDATA

#>

<# 


.SYNOPSIS
            Extracts a dacpac from a database
.DESCRIPTION 
    A Script to extract a .dacpac file from a database. 
.PARAMETER ServerName
    The name of the server to connect to
.PARAMETER DatabaseName
    The name of the database to extract the dacpac from on the server
.PARAMETER UserName
    The username to use when connecting to the server
.PARAMETER Password
            The password to use when connecting to the server
.PARAMETER DacPacPath
    The path to output the created dacpac
.PARAMETER Overwrite
    Whether or not to overwrite the dacpac if it already exists
.EXAMPLE
Extract-DacPacFromDB -ServerName "mydb.database.windows.net" -DatabaseName "dev" -UserName "admin" -Password "P@ssword1" -DacPacPath "~\Desktop\mydb.dev.dacpac" -Overwrite $true

# Extract DacPac
.NOTES
    This function is used to extract a dacpac from a database and wraps the `sqlpackage` command line utility.
.LINK
    https://docs.microsoft.com/en-us/sql/relational-databases/tools/sqlpackage
#> 
Param (
    [Parameter(Mandatory = $true)]
    [String]
    $ServerName,
    [Parameter(Mandatory = $true)]
    [String]
    $DatabaseName,
    [Parameter(Mandatory = $true)]
    [String]
    $UserName,
    [Parameter(Mandatory = $true)]
    [SecureString]
    $Password,
    [Parameter(Mandatory = $true)]
    [String]
    $DacPacPath,
    [Parameter(Mandatory = $false)]
    [bool]
    $Overwrite = $true
)

If (!(Get-Command sqlpackage)) {
    throw 'The sqlpackage command line utility is not installed or not found on your system PATH.'
}

$DacPacPath = $DacPacPath.Replace('~', $HOME)    

$Password = ConvertFrom-SecureString -SecureString $Password -AsPlainText

sqlpackage /a:extract /of:true /sdn:"$DatabaseName" /sp:"$Password" /ssn:"$ServerName" /su:"$UserName" /tf:"$DacPacPath"
