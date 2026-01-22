# Toggle Bluetooth User Support Service startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular CISFramework system with automatic elevation

# Import the ModuleIndex module which includes all modules including ServiceManager
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Bluetooth User Support Service using the CISFramework with automatic elevation
# Note: Service name varies by user session (BluetoothUserService_*)
Invoke-CISScript -ScriptType "ServiceToggle" -ServiceName "BluetoothUserService" -ServiceDisplayName "Bluetooth User Support Service" -AutoElevate -ScriptBlock {
    Invoke-ServiceToggle -ServiceName "BluetoothUserService" -ServiceDisplayName "Bluetooth User Support Service" -EnableStartupType "Manual" -SkipAdminCheck
}