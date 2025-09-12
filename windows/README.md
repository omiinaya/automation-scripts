# Windows Automation Scripts

This directory contains PowerShell scripts for automating Windows system configurations.

## Scripts Overview

### toggle-location-services.ps1
**Purpose**: Toggles Windows location services on/off with a single command.

**Prerequisites**:
- Administrator privileges required (Run as Administrator)
- Windows 10/11 compatible

**Usage**:
```powershell
.\toggle-location-services.ps1
```

**What it does**:
1. Toggles the Windows Location service state
2. Updates registry keys for location services
3. Manages the Geolocation Service (lfsvc)
4. Provides clear status feedback

**Registry Keys Modified**:
- `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location` - Controls location access
- Service control for Geolocation Service (lfsvc)

**Compatibility**:
- Windows 10 (all versions)
- Windows 11 (all versions)
- Requires PowerShell 5.1 or later

**Example Usage Scenarios**:
1. **Privacy-focused work session**:
   ```powershell
   # Disable location services for privacy
   .\toggle-location-services.ps1
   # Output: Location services are now disabled
   ```

2. **Enable for location-based apps**:
   ```powershell
   # Re-enable when using maps or weather apps
   .\toggle-location-services.ps1
   # Output: Location services are now enabled
   ```

3. **Quick privacy toggle**:
   ```powershell
   # Run from any directory
   cd C:\path\to\automation-scripts\windows
   .\toggle-location-services.ps1
   ```

## Running Scripts

All scripts in this directory can be executed from PowerShell. Remember to:
1. Open PowerShell as Administrator
2. Navigate to the script directory
3. Run the desired script with `.\script-name.ps1`

## Safety Notes

- These scripts modify system settings
- Always run with administrator privileges
- Review script content before execution
- Changes can be reversed by running the same script again