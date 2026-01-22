# Toggle Hyper-V Services startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# IMPORTANT: When to leave Hyper-V Services enabled
# - LEAVE ENABLED if you use Hyper-V virtualization features
# - LEAVE ENABLED if you run virtual machines or containers
# - LEAVE ENABLED if you use Windows Subsystem for Linux (WSL) with virtualization
# - LEAVE ENABLED if you use Docker Desktop with WSL2 backend
# - DISABLE if you don't use virtualization features (performance gain)
# Service Name: vmicsvc* (multiple Hyper-V services exist)
# Default: Manual (Trigger)
# Safe to Disable: Yes (if not using Hyper-V)

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle Hyper-V Services using the CISFramework with automatic elevation
# Note: Multiple Hyper-V services exist (vmicsvc*, vmicheartbeat, etc.)
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "vmicsvc" -ServiceDisplayName "Hyper-V Services" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "vmicsvc" -ServiceDisplayName "Hyper-V Services" -EnableStartupType "Manual" -SkipAdminCheck
}