# Toggle Microsoft Account Sign-in Assistant (wlidsvc) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Microsoft Account Sign-in Assistant using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "wlidsvc" -ServiceDisplayName "Microsoft Account Sign-in Assistant" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "wlidsvc" -ServiceDisplayName "Microsoft Account Sign-in Assistant" -EnableStartupType "Manual" -SkipAdminCheck
}