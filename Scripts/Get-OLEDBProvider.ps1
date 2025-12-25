
<#PSScriptInfo

.VERSION 1.0.0

.GUID c713e0eb-2464-4428-8562-6f371dde791d

.AUTHOR Jimmy Briggs

.COMPANYNAME

.COPYRIGHT

.TAGS OLEDB Provider Connection Database

.LICENSEURI

.PROJECTURI https://github.com/jimbrig

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Initial Release

.PRIVATEDATA

#>

<#
    .SYNOPSIS
    Returns a list of OLEDB providers installed on the system.
    .DESCRIPTION
    Returns a list of OLEDB providers installed on the system.
    .NOTES
    ## About
    
    OLE DB Providers are used to connect to different data sources. This function returns a list of OLE DB 
    Providers installed on the system.

    *NOTE: OLE DB providers are 32-bits and 64-bits aware/specific.*

    ## Properties
    The following properties are returned for each OLE DB Provider:
        
        - Name (`SOURCES_NAME`)  
        - Description (`SOURCES_DESCRIPTION`)  
        - CLSID (`SOURCES_CLSID`)  
        - Type (`SOURCES_TYPE`)  

    ## Types
    The following are the possible `SOURCES_TYPES` for an OLE DB Provider:
    
    - `0` - Binder
    - `1` - DataSource_MDP
    - `2` - DataSource_TDP
    - `3` - Enumerator

    .EXAMPLE
    Get-OLEDBProvider
    Default with no parameters. This will return the name, description, type, and CLSID (GUID) of each provider.    
    .EXAMPLE
    Get-OLEDBProvider | ?{$_.SOURCES_DESCRIPTION.IndexOf('SQL Server') -ge 0}
    Returns the same information as the default, but only for providers that have 'SQL Server' in the description.
    .EXAMPLE
    Get-OLEDBProvider | Format-Table -AutoSize
    Returns the same information as the default, but in a table format.
    .EXAMPLE
    Get-OLEDBProvider | Format-List
    Returns the same information as the default, but in a list format.
    .EXAMPLE
    Get-OLEDBProvider | Out-GridView
    Returns the same information as the default, but in a grid view format.
    .EXAMPLE
    Get-OLEDBProvider | ConvertTo-Csv > .\OLEDBProviders.csv
    Returns the same information as the default, but in a CSV file in the current working directory.  
    .LINK
    https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ms711269(v=vs.85)
    .LINK
    https://learn.microsoft.com/en-us/dotnet/api/system.data.oledb.oledbenumerator.getrootenumerator?view=dotnet-plat-ext-6.0
    .LINK
    http://dbadailystuff.com/list-all-ole-db-providers-in-powershell
    .LINK
    https://github.com/josepmv/dbadailystuff/blob/master/list_all_OLEDB_Provider.ps1
    
#>
[CmdletBinding()]
Param ()    
$providers = [System.Data.OleDb.OleDbEnumerator]::GetRootEnumerator() # New-Object System.Data.OleDb.OleDbEnumerator
ForEach ($provider in $providers) {
    $p = New-Object PSObject
    For ($i = 0; $i -lt $provider.FieldCount; $i++) {
        $p | Add-Member -MemberType NoteProperty -Name $provider.GetName($i) -Value $provider.GetValue($i)
    }

    $p | Select-Object SOURCES_NAME, SOURCES_DESCRIPTION, SOURCES_TYPE, SOURCES_CLSID
}
