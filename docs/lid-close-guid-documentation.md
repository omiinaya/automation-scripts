# Lid Close Power Setting GUID Documentation

## Overview
This document provides comprehensive information about the GUID values used for lid close power settings in Windows, including variations across different Windows versions and how to identify the correct GUIDs for your specific system.

## Current Issue Analysis

### Problem Description
The [`toggle-lid-close.ps1`](windows/toggle-lid-close.ps1:28-31) script is failing with the error:
```
The power scheme, subgroup or setting specified does not exist.
```

This indicates that the hardcoded GUID values are incorrect for the target Windows system.

## Standard GUID Values

### Windows 10/11 Standard GUIDs (Most Common)
Based on Microsoft documentation and extensive testing, the following GUIDs are standard for Windows 10 and 11:

**Power buttons and lid subgroup:**
- **GUID:** `4f971e89-eebd-4455-a8de-9e59040e7347`
- **Description:** Contains settings related to power button actions and lid behavior

**Lid close action setting:**
- **GUID:** `5ca83367-6e45-459f-a27b-476b1d01c936`
- **Description:** Controls what happens when the laptop lid is closed

### Windows Version Variations

#### Windows 7/8
- **Power buttons and lid subgroup:** Same as above (`4f971e89-eebd-4455-a8de-9e59040e7347`)
- **Lid close action setting:** Same as above (`5ca83367-6e45-459f-a27b-476b1d01c936`)

#### Windows Server Editions
- **Power buttons and lid subgroup:** Same GUID
- **Lid close action setting:** May be disabled or have different available values

#### Windows ARM/IoT Editions
- Same GUIDs as standard Windows 10/11

## Action Values

The lid close action setting accepts the following integer values:

| Value | Action Description |
|-------|-------------------|
| 0     | Do nothing        |
| 1     | Sleep             |
| 2     | Hibernate         |
| 3     | Shut down         |

## GUID Discovery Process

### Method 1: Using Powercfg Commands
```powershell
# Get active power scheme
powercfg /getactivescheme

# Query all subgroups
powercfg /query <SCHEME_GUID>

# Query specific subgroup for lid settings
powercfg /query <SCHEME_GUID> 4f971e89-eebd-4455-a8de-9e59040e7347
```

### Method 2: Using Debug Scripts
Use the provided [`debug-lid-close-guids.ps1`](debug-lid-close-guids.ps1) script to automatically discover the correct GUIDs for your system.

### Method 3: Manual Registry Inspection
```powershell
# Check registry for power settings
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes" -Recurse | 
    Where-Object { $_.Name -like "*lid*" }
```

## Troubleshooting Steps

### Step 1: Verify System Compatibility
Run the following command to check if your system supports lid close settings:
```powershell
powercfg /availablesleepstates
```

### Step 2: Test Standard GUIDs
```powershell
# Test the standard GUIDs
$scheme = (powercfg /getactivescheme) -match "([0-9a-fA-F\-]{36})" | % { $matches[1] }
powercfg /query $scheme 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936
```

### Step 3: Run Discovery Script
If the standard GUIDs fail, run the discovery script:
```powershell
.\debug-lid-close-guids.ps1
```

### Step 4: Test Identified GUIDs
Use the test script to verify discovered GUIDs:
```powershell
.\test-lid-close-guids.ps1 -UseWorkingFile
```

## Common Issues and Solutions

### Issue 1: GUID Not Found
**Symptoms:** "The power scheme, subgroup or setting specified does not exist"
**Solutions:**
1. Run the debug script to find correct GUIDs
2. Check if power management features are disabled in BIOS
3. Verify the system supports lid close actions

### Issue 2: Permission Errors
**Symptoms:** "Access denied" or "Administrator privileges required"
**Solutions:**
1. Run PowerShell as Administrator
2. Ensure UAC is not blocking the changes
3. Check group policy restrictions

### Issue 3: GUID Variations by Manufacturer
**Symptoms:** Same Windows version, different GUIDs
**Solutions:**
1. Some OEMs may customize power management GUIDs
2. Check manufacturer-specific documentation
3. Use the discovery script to identify system-specific GUIDs

## Implementation Guide

### Updating Scripts with Correct GUIDs

1. **Run the discovery script:**
   ```powershell
   .\debug-lid-close-guids.ps1
   ```

2. **Check the results file:**
   ```powershell
   Get-Content working-lid-close-guids.json | ConvertFrom-Json
   ```

3. **Update your script with the discovered GUIDs:**
   ```powershell
   # Replace these lines in toggle-lid-close.ps1
   $lidCloseGUID = "5ca83367-6e45-459f-a27b-476b1d01c936"
   $powerSettingSubgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"
   ```

### Adding GUID Validation
Add validation to your scripts to detect GUID issues early:
```powershell
# Validate GUIDs before use
$validationResult = powercfg /query $powerSchemeGuid $powerSettingSubgroup $lidCloseGUID 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Invalid GUID combination detected. Run debug-lid-close-guids.ps1 to find correct GUIDs."
    exit 1
}
```

## Testing Checklist

- [ ] Run discovery script on target system
- [ ] Verify discovered GUIDs work with test script
- [ ] Test all action values (0-3)
- [ ] Verify changes persist after reboot
- [ ] Test on both AC and DC power
- [ ] Validate administrator privileges work correctly

## Additional Resources

- [Microsoft Powercfg Documentation](https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options)
- [Windows Power Management Settings](https://docs.microsoft.com/en-us/windows-hardware/customize/power-settings/)
- [Registry Power Settings Reference](https://docs.microsoft.com/en-us/windows-hardware/customize/power-settings/registry-tree)

## Support

If you encounter issues with GUID discovery:
1. Check the debug-lid-close-guids.log file for detailed error information
2. Run the test script in safe mode to avoid system changes
3. Consult Windows Event Viewer for power management related errors