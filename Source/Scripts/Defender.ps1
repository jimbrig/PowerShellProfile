
# Define Custom Defender Exclusions
$DefenderExclusionsData = Import-PowerShellDataFile -Path "$PSScriptRoot\..\Configuration\DefenderExclusions.psd1"

$PathExclusions = $DefenderExclusionsData.ExclusionPaths | ForEach-Object { Resolve-Path $_ -ErrorAction SilentlyContinue }
$ExtensionExclusions = $DefenderExclusionsData.ExclusionExtensions
$ProcessExclusions = $DefenderExclusionsData.ExclusionProcesses

$MpPrefs = Get-MpPreference
$CurrentExcludedPaths = $MpPrefs.ExclusionPath
$CurrentExcludedExtensions = $MpPrefs.ExclusionExtension
$CurrentExcludedProcesses = $MpPrefs.ExclusionProcess

# Filter out any exclusions that already exist
$PathExclusions = $PathExclusions | Where-Object { $_ -notin $CurrentExcludedPaths }
$ExtensionExclusions = $ExtensionExclusions | Where-Object { $_ -notin $CurrentExcludedExtensions }
$ProcessExclusions = $ProcessExclusions | Where-Object { $_ -notin $CurrentExcludedProcesses }

# Initialize Progress
$i = 0
$n = $PathExclusions.Count + $ExtensionExclusions.Count + $ProcessExclusions.Count
if ($n -eq 0) {
    Write-Host "No new exclusions to add."
    return
}
$pct = $i / $n

Write-Progress -Activity "Adding Defender Exclusions" -Status "Processing..." -PercentComplete ($pct * 100)

ForEach ($Path in $PathExclusions) {
    Add-MpPreference -ExclusionPath $Path
    $i++
    $pct = $i / $n
    Write-Progress -Activity "Adding Defender Exclusions" -Status "Processing Path: $Path" -PercentComplete ($pct * 100)
}

Write-Progress -Activity "Adding Defender Exclusions" -Status "Processing..." -PercentComplete ($pct * 100)

ForEach ($Extension in $ExtensionExclusions) {
    Add-MpPreference -ExclusionExtension $Extension
    $i++
    $pct = $i / $n
    Write-Progress -Activity "Adding Defender Exclusions" -Status "Processing Extension: $Extension" -PercentComplete ($pct * 100)
}

Write-Progress -Activity "Adding Defender Exclusions" -Status "Processing..." -PercentComplete ($pct * 100)

ForEach ($Process in $ProcessExclusions) {
    Add-MpPreference -ExclusionProcess $Process
    $i++
    $pct = $i / $n
    Write-Progress -Activity "Adding Defender Exclusions" -Status "Processing Process: $Process" -PercentComplete ($pct * 100)
}

Write-Progress -Activity "Adding Defender Exclusions" -Status "Completed" -Completed
Write-Host "Defender exclusions have been updated successfully."

# Output the current exclusions for verification
$MpPrefs = Get-MpPreference
Write-Host "Current Defender Exclusions:"
Write-Host "Paths: $($MpPrefs.ExclusionPath -join ', ')"
Write-Host "Extensions: $($MpPrefs.ExclusionExtension -join ', ')"
Write-Host "Processes: $($MpPrefs.ExclusionProcess -join ', ')"


# Remove-MpPreference -ExclusionPath 'C:\\Program Files\\Docker'
# Remove-MpPreference -ExclusionPath 'C:\\Program Files\\Docker\\cli-plugins'
# Remove-MpPreference -ExclusionPath 'C:\\Program Files\\Docker\\Docker'
# Remove-MpPreference -ExclusionPath 'C:\\Program Files\\PowerShell\\7'
# Remove-MpPreference -ExclusionPath 'C:\\Program Files\\PowerShell\\7-preview'
# Remove-MpPreference -ExclusionPath 'C:\\Program Files\\R'
# Remove-MpPreference -ExclusionPath 'C:\\Program Files\\R\\bin'
# Remove-MpPreference -ExclusionPath 'C:\\Program Files\\RStudio'
