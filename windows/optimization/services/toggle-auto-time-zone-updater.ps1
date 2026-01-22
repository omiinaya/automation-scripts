# Toggle Auto Time Zone Updater service (tzautoupdate) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Auto Time Zone Updater service using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "tzautoupdate" -ServiceDisplayName "Auto Time Zone Updater" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "tzautoupdate" -ServiceDisplayName "Auto Time Zone Updater" -EnableStartupType "Manual" -SkipAdminCheck
}