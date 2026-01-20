# Toggle ActiveX Installer service (AxInstSV) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular ServiceManager system

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the ActiveX Installer service using the ServiceManager module
Invoke-ServiceToggle -ServiceName "AxInstSV" -ServiceDisplayName "ActiveX Installer" -EnableStartupType "Manual"