# Toggle Application Layer Gateway Service (ALG) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Application Layer Gateway Service using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "ALG" -ServiceDisplayName "Application Layer Gateway Service" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "ALG" -ServiceDisplayName "Application Layer Gateway Service" -EnableStartupType "Manual" -SkipAdminCheck
}