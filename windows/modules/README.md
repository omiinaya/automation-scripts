# Windows PowerShell Modules

A collection of modular PowerShell modules for Windows system administration and automation.

## Overview

This collection provides reusable PowerShell modules for common Windows administration tasks, including:

- **WindowsUtils**: Administrative privilege checks, elevation, and common utilities
- **PowerManagement**: Power scheme operations and power management
- **RegistryUtils**: Registry operations and manipulation
- **WindowsUI**: Consistent UI output and formatting
- **ModuleIndex**: Main index module for importing all modules

## Installation

1. Copy the entire `modules` folder to your PowerShell modules directory or project location
2. Import the main module using one of these methods:

### Method 1: Import all modules at once
```powershell
Import-Module .\windows\modules\ModuleIndex.psm1
Initialize-WindowsModules
```

### Method 2: Import individual modules
```powershell
Import-Module .\windows\modules\WindowsUtils.psm1
Import-Module .\windows\modules\PowerManagement.psm1
Import-Module .\windows\modules\RegistryUtils.psm1
Import-Module .\windows\modules\WindowsUI.psm1
```

## Quick Start

```powershell
# Import all modules
Import-Module .\windows\modules\ModuleIndex.psm1

# Check if running as administrator
if (Test-AdminRights) {
    Write-StatusMessage -Message "Running as Administrator" -Type Success
}

# Get current power schemes
$schemes = Get-PowerSchemes
Display-Table -Data $schemes -Title "Available Power Schemes"

# Set high performance mode
$highPerf = Get-PowerSchemeByName -Name "High performance"
if ($highPerf) {
    Set-PowerScheme -SchemeGUID $highPerf.GUID
}

# Test registry operations
if (Test-RegistryKey -KeyPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion") {
    Write-StatusMessage -Message "Registry key exists" -Type Success
}
```

## Module Documentation

### WindowsUtils Module
Provides administrative utilities and system information.

**Key Functions:**
- `Test-AdminRights` - Check if running with admin privileges
- `Invoke-Elevation` - Request elevation if needed
- `Get-SystemInfo` - Get basic system information
- `Get-CurrentUserInfo` - Get current user information
- `Test-ServiceExists` - Check if a Windows service exists
- `Restart-ServiceSafely` - Restart Windows services with error handling
- `Wait-ProcessExit` - Wait for a process to exit

### PowerManagement Module
Provides power scheme management and power setting utilities.

**Key Functions:**
- `Get-PowerSchemes` - List all available power schemes
- `Get-ActivePowerScheme` - Get the currently active power scheme
- `Set-PowerScheme` - Set a power scheme as active by GUID
- `Get-PowerSchemeByName` - Find power scheme by name
- `Get-PowerSetting` - Get value of a specific power setting
- `Set-PowerSetting` - Set value of a specific power setting
- `Get-PowerSettingGUID` - Find power setting GUID by name
- `Get-PowerSettings` - Get common power settings for current scheme
- `Get-BatteryInfo` - Get battery status and information
- `Copy-PowerScheme` - Create a copy of an existing power scheme
- `Remove-PowerScheme` - Delete a power scheme

### RegistryUtils Module
Provides registry operations and manipulation functions.

**Key Functions:**
- `Test-RegistryKey` - Check if a registry key exists
- `Test-RegistryValue` - Check if a registry value exists
- `Get-RegistryValue` - Get value of a registry key
- `Set-RegistryValue` - Set value of a registry key
- `Remove-RegistryValue` - Remove a registry value
- `Remove-RegistryKey` - Remove a registry key and subkeys
- `New-RegistryKey` - Create a new registry key
- `Export-RegistryKey` - Export registry key to .reg file
- `Import-RegistryFile` - Import registry settings from .reg file
- `Find-RegistryValue` - Search for registry values by name or data

### WindowsUI Module
Provides consistent UI output and formatting functions.

**Key Functions:**
- `Write-StatusMessage` - Write formatted status messages
- `Write-SectionHeader` - Write section headers
- `Write-ProgressBar` - Display progress bars
- `Show-Menu` - Display selection menus
- `Show-Confirmation` - Show yes/no confirmation prompts
- `Show-Table` - Display data in formatted tables
- `Show-List` - Display items in bulleted lists
- `Show-Pause` - Pause execution and wait for user input
- `Clear-ScreenWithHeader` - Clear screen with title header
- `Show-SystemBanner` - Display system information banner

## Examples

### Example 1: Working with Power Schemes
```powershell
# Import modules
Import-Module .\windows\modules\ModuleIndex.psm1

# List all power schemes
$schemes = Get-PowerSchemes
$schemes | Format-Table -AutoSize

# Find high performance scheme
$highPerf = Get-PowerSchemeByName -Name "High performance"

# Set it as active
if ($highPerf) {
    Set-PowerScheme -SchemeGUID $highPerf.GUID
}
```

### Example 2: Registry Operations
```powershell
# Import modules
Import-Module .\windows\modules\ModuleIndex.psm1

# Check if registry key exists
if (Test-RegistryKey -KeyPath "HKLM:\SOFTWARE\MyApp") {
    Write-StatusMessage -Message "Key exists" -Type Success
}

# Set a registry value
Set-RegistryValue -KeyPath "HKLM:\SOFTWARE\MyApp" -ValueName "Setting1" -ValueData "MyValue" -ValueType String

# Get the value
$value = Get-RegistryValue -KeyPath "HKLM:\SOFTWARE\MyApp" -ValueName "Setting1"
```

### Example 3: Power Settings Management
```powershell
# Import modules
Import-Module .\windows\modules\ModuleIndex.psm1

# Get current power settings
$settings = Get-PowerSettings
$settings | Format-Table -AutoSize

# Disable sleep mode
$sleepGuid = Get-PowerSettingGUID -SettingName "Sleep after"
if ($sleepGuid) {
    Set-PowerSetting -SettingGUID $sleepGuid -Value 0
}

# Set monitor timeout to 10 minutes
$monitorGuid = Get-PowerSettingGUID -SettingName "Turn off display after"
if ($monitorGuid) {
    Set-PowerSetting -SettingGUID $monitorGuid -Value 10
}
```

## Example Scripts

The `examples` folder contains practical scripts that demonstrate how to use the modules:

- `disable-sleep-mode.ps1` - Disables sleep mode
- `disable-screen-timeout.ps1` - Disables screen timeout
- `set-lid-close-nothing.ps1` - Sets laptop lid close action to "Do nothing"
- `set-high-performance.ps1` - Activates high performance power scheme

## Best Practices

1. **Always check admin rights** with `Test-AdminRights` before making system changes
2. **Use error handling** with try/catch blocks for critical operations
3. **Provide user feedback** using the WindowsUI module functions
4. **Test registry operations** before applying changes
5. **Document your scripts** with proper help and examples

## Troubleshooting

### Module Import Issues
```powershell
# Check if modules are loaded
Get-Module -ListAvailable

# Force reimport
Import-Module .\windows\modules\ModuleIndex.psm1 -Force
```

### Permission Issues
```powershell
# Check admin rights
Test-AdminRights

# Request elevation if needed
Invoke-Elevation
```

### Power Settings Not Applying
```powershell
# Ensure you're using the correct GUID
Get-PowerSettingGUID -SettingName "Sleep after"

# Verify the setting was applied
Get-PowerSetting -SettingGUID $guid
```

## Support

For issues or questions:
1. Check the built-in help: `Get-Help <Command-Name>`
2. Use the module info function: `Get-WindowsModuleInfo`
3. Test modules: `Test-WindowsModules`
4. Review example scripts in the `examples` folder