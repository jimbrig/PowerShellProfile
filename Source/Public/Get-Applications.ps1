Function Get-Applications() {
    [CmdletBinding()]
    param()
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    Get-ChildItem -Path $RegPath | Get-ItemProperty |
        Sort-Object DisplayName
}
