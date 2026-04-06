Function Get-SourceCode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Function
    )

    $null = Get-Command -Name $Function -ErrorAction SilentlyContinue
    $Alias = (Get-Alias -Name $Function -ErrorAction SilentlyContinue).ResolvedCommand.Name
    if ($Alias) {
        Write-Warning "'$Function' is an alias for '$Alias'. Running 'Get-Definition -Function $Alias'."
        $Function = $Alias
    }
    $FunctionDefinition = (Get-Command -name $Function | Select-Object -ExpandProperty Definition)
    $returnDefinition = [System.Text.StringBuilder]::New()

    $null = $returnDefinition.Append("function $Function`() {")
    $null = $returnDefinition.Append($FunctionDefinition)
    $null = $returnDefinition.Append('}')

    $returnDefinition.ToString()
}
