# Toggle IP Helper service (iphlpsvc) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the IP Helper service using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "iphlpsvc" -ServiceDisplayName "IP Helper" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "iphlpsvc" -ServiceDisplayName "IP Helper" -EnableStartupType "Manual" -SkipAdminCheck
}