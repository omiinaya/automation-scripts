# Toggle Connected User Experiences and Telemetry service (DiagTrack) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular ServiceManager system

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Connected User Experiences and Telemetry service using the ServiceManager module
Invoke-ServiceToggle -ServiceName "DiagTrack" -ServiceDisplayName "Connected User Experiences and Telemetry" -EnableStartupType "Manual"