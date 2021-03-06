#
# Specialised shutdown for Windows Core Installations to workaround boxstarter resumption on reboot
# issues with Windows Core
#
Param(
    [Parameter()]
    [switch] $UseStartupWorkaround = $false
)

if ($UseStartupWorkaround) {
    Write-Warning "Cleaning up PowerShell profile workaround for startup items"
    Remove-Item -Force $PROFILE -ErrorAction SilentlyContinue
}

Remove-Item -Force -Recurse "$($env:APPDATA)\SetupFlags" -ErrorAction SilentlyContinue

Stop-Computer -Force
