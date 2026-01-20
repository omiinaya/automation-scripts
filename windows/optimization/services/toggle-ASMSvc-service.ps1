# Toggle Application Service Management Service (ASMSvc) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular ServiceManager system

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the ASMSvc service using the ServiceManager module
Invoke-ServiceToggle -ServiceName "ASMSvc" -ServiceDisplayName "Application Service Management Service" -EnableStartupType "Automatic"