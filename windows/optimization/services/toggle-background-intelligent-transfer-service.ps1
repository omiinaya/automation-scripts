# Toggle Background Intelligent Transfer Service (BITS) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Background Intelligent Transfer Service using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "BITS" -ServiceDisplayName "Background Intelligent Transfer Service" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "BITS" -ServiceDisplayName "Background Intelligent Transfer Service" -EnableStartupType "Manual" -SkipAdminCheck
}