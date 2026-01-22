# Toggle Function Discovery Provider Host (fdPHost) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Function Discovery Provider Host using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "fdPHost" -ServiceDisplayName "Function Discovery Provider Host" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "fdPHost" -ServiceDisplayName "Function Discovery Provider Host" -EnableStartupType "Manual" -SkipAdminCheck
}