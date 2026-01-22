# Toggle Payments and NFC/SE Manager service (SEMgrSvc) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Payments and NFC/SE Manager service using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "SEMgrSvc" -ServiceDisplayName "Payments and NFC/SE Manager" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "SEMgrSvc" -ServiceDisplayName "Payments and NFC/SE Manager" -EnableStartupType "Manual" -SkipAdminCheck
}