
<#PSScriptInfo

.VERSION 1.0.0

.GUID 54120b1c-a4cb-40ef-9d7e-c3a8ebf30adf

.DESCRIPTION Get the OpenAPI Specification Definition from a specified URI

.AUTHOR Jimmy Briggs <jimmy.briggs@jimbrig.com>

.COMPANYNAME Jimmy Briggs

.COPYRIGHT Jimmy Briggs 2024

.TAGS OpenAPI, REST, API, Swagger, Specification, Definition, YAML, JSON

.LICENSEURI https://gist.github.com/jimbrig/ad4ea326362446a445b32a551f5e4bb0

.PROJECTURI https://github.com/jimbrig/PSScripts/blob/main/Get-OpenApiSpecification

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

.PRIVATEDATA

#>

Function Get-OpenApiDefinition {
    <#
    .SYNOPSIS
        Retrieves the OpenAPI Specification Definition from a specified URI
    .DESCRIPTION
        This function fetches the OpenAPI definition from the specified URI and for every reference,
        downloads the relative file to the destination folder. Currently only works with relative references.
    .PARAMETER Uri
        The source URI of the OpenAPI definition
    .PARAMETER Destination
        The destination path to download all files/folders
    .EXAMPLE
        $Params = @{
            Uri = "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.yaml"
            Destination = "C:\temp\petstore"
        }
        Get-OpenApiDefinition @Params
    .NOTES
        Name: Get-OpenApiDefinition
	#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [Uri]$Uri,
        [Parameter(Mandatory)]
        [String]$Destination
    )

    [uri]$baseUri = ((Split-Path -Path $Uri) -replace '\\', '/') + '/'
    $destinationDir = New-Item -ItemType Directory -Path $Destination -Force

    [HashSet[string]]$files = @()
    [Queue[string]]$queue = @()
    $queue.Enqueue($Uri)

    while ($queue.count -ne 0) {
        $UriToDownload = $queue.Dequeue()
        Write-Debug $UriToDownload

        $definition = Invoke-RestMethod -Uri $UriToDownload
        $path = $baseUri.MakeRelative($UriToDownload)
        $outFilePath = Join-Path $destinationDir $path
        $definition | Out-File -FilePath (New-Item -Path $outFilePath -Force)

        foreach ($ref in (Get-Refs -Definition $definition)) {
            $candidateUri = [uri]::new(([uri]$UriToDownload), $ref)
            #If we have not seen the file yet, process it
            if ($files.Add($candidateUri)) {
                $queue.Enqueue($candidateUri)
            }
        }
    }

    return $files
}

Function Get-Refs {
    param (
        #The OpenAPI definition
        [string]$Definition
    )

    # Look for $ref in the definition
    $refs = $definition.split("`n") | Select-String -Pattern '\$ref: ["'']?([^"''].+?)#/' | ForEach-Object { $_.Matches.Groups[1].Value }

    # Deduplicate the refs
    $uniqueRefs = $refs | Select-Object -Unique

    return $uniqueRefs
}

<#
.DESCRIPTION
    Get the OpenAPI Specification Definition from a specified URI
#>
Param(
    [Parameter(Mandatory)]
    [Uri]$Uri,
    [Parameter(Mandatory)]
    [String]$Destination
)

Get-OpenApiDefinition -Uri $Uri -Destination $Destination
