# Toggle Device Management Wireless Application Protocol (WAP) Push service (dmwappushservice) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Device Management WAP Push service using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "dmwappushservice" -ServiceDisplayName "Device Management Wireless Application Protocol (WAP) Push" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "dmwappushservice" -ServiceDisplayName "Device Management Wireless Application Protocol (WAP) Push" -EnableStartupType "Manual" -SkipAdminCheck
}