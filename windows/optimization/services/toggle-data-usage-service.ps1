# Toggle Data Usage service (DusmSvc) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Data Usage service using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "DusmSvc" -ServiceDisplayName "Data Usage" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "DusmSvc" -ServiceDisplayName "Data Usage" -EnableStartupType "Manual" -SkipAdminCheck
}