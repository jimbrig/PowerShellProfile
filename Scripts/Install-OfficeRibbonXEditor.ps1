
<#PSScriptInfo

.VERSION 1.0

.GUID 9a32944c-90c0-4486-be91-9a2aed3de926

.AUTHOR Jimmy Briggs

.COMPANYNAME Jimmy Briggs

.COPYRIGHT Jimmy Briggs | 2022

.TAGS Excel Ribbon Installation Utility Tool UI

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
    A script for installing and configuring the Office RibbonX Editor utility program. 

.NOTES
    Note that by default this script will download the zip archive "OfficeCustomUIEditorFiles.zip" from 
    https://bettersolutions.com's official download URI by default into the User's Downloads folder.
    
    It will then extract the downloaded zip archive to the provided destintion directory provided via the `Destination`
    Parameter. If the `Destination` Parameter is not provided, the script will extract the zip archive to the User's
    ~/tools folder by default.

    **CONFIGURATION**
    This script, in addition to downloading the portable version of the program, also configures the application via
    an XML configuration file. The configuration file is located in the same directory as the extracted program files.
    
    The original, default XML configuration is initially backed up and a new configuration is written for the latest 
    version of DotNet. The new configuration XML is then output back to the extracted program file's directory.

    This is the configuration XML used:

    <?xml version="1.0"?>
    <configuration>
        <appSettings>
            <!--   User application and configured property settings go here.-->
            <!--   Example: <add key="settingName" value="settingValue"/> -->
        </appSettings>
        <startup>
            <supportedRuntime version="v6.0.5"/>
            <supportedRuntime version="v2.0.50727"/>
        </startup>
    </configuration>

.PARAMETER Destination
    The path to the destination folder where the downloaded program should be placed. If not provided, the script will
    default to the User's ~/tools folder. 

.EXAMPLE
    PS> .\Install-OfficeRibbonXEditor.ps1 -Destination "C:\Temp"
    
    Will install OfficeRibbonX Editor to user's temporary folder.

.LINK 
    https://bettersolutions.com
    https://bettersolutions.com/vba/ribbon/OfficeCustomUIEditorFiles.zip
#> 
[CmdletBinding()]
Param(
    [Parameter(Position = 0, HelpMessage = 'Specify the path to the destination directory to place the downloaded executable.')]
    [string]$Destination = "$HOME\tools\OfficeCustomUIEditor"
)

$URI = 'https://bettersolutions.com/vba/ribbon/OfficeCustomUIEditorFiles.zip'
$OutFile = "$HOME\Downloads\OfficeCustomUIEditorFiles.zip"
$DestDir = $Destination # "$HOME\tools\OfficeCustomUIEditor"

If (!(Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir -Force
}

Write-Host "Downloading 'OfficeCustomUIEditorFiles.zip' to ~/Downloads." -ForegroundColor Yellow
$ProgressPreference = 'SilentlyContinue'
Invoke-RestMethod -Method Get -Uri $URI -OutFile $OutFile -ContentType 'application/zip' -MaximumRetryCount 5 -RetryIntervalSec 5
$ProgressPreference = 'Continue'

If (Test-Path $OutFile) {
    Write-Host "Successfully downloaded 'OfficeCustomUIEditorFiles.zip' to ~/Downloads." -ForegroundColor Green
} Else {
    Write-Host "Failed to download 'OfficeCustomUIEditorFiles.zip' to ~/Downloads." -ForegroundColor Red
    throw    
}

Write-Host "Extracting 'OfficeCustomUIEditorFiles.zip' to $DestDir." -ForegroundColor Yellow
Expand-Archive -Path $OutFile -DestinationPath $DestDir

If (Test-Path "$DestDir\CustomUIEditor.exe") {
    Write-Host "Successfully extracted 'OfficeCustomUIEditorFiles.zip' to $DestDir." -ForegroundColor Green
} Else {
    Write-Host "Failed to extract 'OfficeCustomUIEditorFiles.zip' to $DestDir." -ForegroundColor Red
    throw
}

Write-Host "Deleting 'OfficeCustomUIEditorFiles.zip' from ~/Downloads." -ForegroundColor Yellow
Remove-Item -Path $OutFile -Force

If (Test-Path $OutFile) {
    Write-Host "Failed to delete 'OfficeCustomUIEditorFiles.zip' from ~/Downloads." -ForegroundColor Red
    throw
} Else {
    Write-Host "Successfully deleted 'OfficeCustomUIEditorFiles.zip' from ~/Downloads." -ForegroundColor Green
}


$DefaultConfig = "$DestDir\CustomUIEditor.exe.config"

If (Test-Path $DefaultConfig) {
    Write-Host "Backing up the default configuration file..." -ForegroundColor Yellow
    Move-Item -Path $DefaultConfig -Destination "$DestDir\CustomUIEditor.exe.config.bak" -Force
    If (Test-Path "$DestDir\CustomUIEditor.exe.config.bak") {
        Write-Host "Successfully backed up the default configuration file." -ForegroundColor Green
    } Else {
        Write-Host "Failed to back up the default configuration file." -ForegroundColor Red
    }
}

Write-Host "Configuring the Office RibbonX Editor." -ForegroundColor Yellow
$DotNetRunTimeVersion = 'v6.0.5'
$DotNetRunTimeVersionDefault = 'v2.0.50727'

$XML = ((
@"
<?xml version="1.0"?>
<configuration>
    <appSettings>
        <!--   User application and configured property settings go here.-->
        <!--   Example: <add key="settingName" value="settingValue"/> -->
    </appSettings>
    <startup>
        <supportedRuntime version="$($DotNetRunTimeVersion)"/>
        <supportedRuntime version="$($DotNetRunTimeVersionDefault)"/>
    </startup>
</configuration>
"@).TrimEnd()).TrimStart()

$XML | Out-File -FilePath "$DestDir\CustomUIEditor.exe.config" -Encoding ASCII -Force

If (Test-Path $DestDir\CustomUIEditor.exe.config) {
    Write-Host "Successfully configured the Office RibbonX Editor." -ForegroundColor Green
} Else {
    Write-Host "Failed to configure the Office RibbonX Editor." -ForegroundColor Red
}

Write-Host "Opening 'CustomUIEditor.exe' from $DestDir." -ForegroundColor Yellow
& "$DestDir\CustomUIEditor.exe"

Write-Host "Installation complete." -ForegroundColor Green

# End Script
