# Toggle Link-Layer Topology Discovery Mapper (lltdsvc) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Link-Layer Topology Discovery Mapper using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "lltdsvc" -ServiceDisplayName "Link-Layer Topology Discovery Mapper" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "lltdsvc" -ServiceDisplayName "Link-Layer Topology Discovery Mapper" -EnableStartupType "Manual" -SkipAdminCheck
}