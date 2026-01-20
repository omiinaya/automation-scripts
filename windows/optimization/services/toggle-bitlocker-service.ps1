# Toggle BitLocker Drive Encryption service (BDESVC) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular ServiceManager system

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the BitLocker service using the ServiceManager module
Invoke-ServiceToggle -ServiceName "BDESVC" -ServiceDisplayName "BitLocker Drive Encryption" -EnableStartupType "Manual"