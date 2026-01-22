# Toggle Windows Search service (WSearch) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# IMPORTANT: When to leave Windows Search service enabled
# - LEAVE ENABLED if you rely on Windows file search functionality
# - LEAVE ENABLED if you use Start Menu search frequently
# - LEAVE ENABLED if you search files and folders regularly
# - DISABLE for maximum performance gain (big impact on CPU/RAM usage)
# Service Name: WSearch
# Default: Automatic
# Safe to Disable: Yes (big performance gain if disabled)

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Windows Search service using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "WSearch" -ServiceDisplayName "Windows Search" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "WSearch" -ServiceDisplayName "Windows Search" -EnableStartupType "Manual" -SkipAdminCheck
}