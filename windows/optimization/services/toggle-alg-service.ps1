# Toggle Application Layer Gateway Service (ALG) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
# Refactored to use modular ServiceManager system

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Toggle the Application Layer Gateway Service using the ServiceManager module
Invoke-ServiceToggle -ServiceName "ALG" -ServiceDisplayName "Application Layer Gateway Service" -EnableStartupType "Manual"