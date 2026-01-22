# Toggle BitLocker Drive Encryption service (BDESVC) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# IMPORTANT: When to leave BitLocker Drive Encryption service enabled
# - LEAVE ENABLED if you use BitLocker encryption for drive security
# - LEAVE ENABLED if you have encrypted drives on your system
# - LEAVE ENABLED if you use Windows device encryption
# - DISABLE if you don't use drive encryption (minimal impact)
# Service Name: BDESVC
# Default: Manual (Trigger)
# Safe to Disable: Yes (if not using BitLocker)

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the BitLocker service using the CISFramework with automatic elevation
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "BDESVC" -ServiceDisplayName "BitLocker Drive Encryption" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "BDESVC" -ServiceDisplayName "BitLocker Drive Encryption" -EnableStartupType "Manual" -SkipAdminCheck
}