# Script Templates

This directory contains standardized PowerShell script templates to eliminate boilerplate duplication across the automation scripts project.

## Overview

The templates provide a consistent structure for three types of scripts:
- **Audit scripts** - Check system configurations and compliance status
- **Remediation scripts** - Apply security settings and fix configuration issues
- **Optimization scripts** - Toggle services, adjust visual effects, and modify system settings

## Template Files

### [`audit-script-template.ps1`](audit-script-template.ps1)

Use this template for scripts that:
- Check security settings and compliance
- Audit system configurations
- Verify registry values
- Validate service states

**Key Features:**
- Standardized module import pattern using [`Get-ModulePath`](../../modules/CommonUtilities.psm1:215)
- Admin rights checking with [`Test-AdminRights`](../../modules/CommonUtilities.psm1:60)
- Error handling with [`Handle-CommonError`](../../modules/CommonUtilities.psm1:105)
- Placeholder functions for audit logic
- Formatted output display

### [`remediation-script-template.ps1`](remediation-script-template.ps1)

Use this template for scripts that:
- Apply security configurations
- Fix compliance issues
- Modify registry settings
- Enforce CIS benchmarks

**Key Features:**
- State retrieval before remediation
- Remediation application with error handling
- Post-remediation verification
- Compliance check to skip if already compliant
- Detailed status reporting

### [`optimization-script-template.ps1`](optimization-script-template.ps1)

Use this template for scripts that:
- Toggle Windows services
- Adjust visual effects
- Modify power management settings
- Change system preferences

**Key Features:**
- Current setting retrieval
- Toggle functionality (enable/disable)
- Value-based optimization
- Before/after value comparison
- Success/failure reporting

## How to Use the Templates

### Step 1: Copy the Template

Copy the appropriate template to your target location:

```powershell
# For audit scripts
Copy-Item windows/templates/audit-script-template.ps1 windows/security/audit-your-script.ps1

# For remediation scripts
Copy-Item windows/templates/remediation-script-template.ps1 windows/deferred/security/remediations/your-script.ps1

# For optimization scripts
Copy-Item windows/templates/optimization-script-template.ps1 windows/optimization/services/your-script.ps1
```

### Step 2: Update Script Metadata

Modify the script header with your specific information:

```powershell
$scriptName = "Audit-YourSpecificCheck"
$scriptVersion = "1.0.0"
```

### Step 3: Import Required Modules

Uncomment and add the modules you need:

```powershell
# Import additional modules as needed
Import-Module "$modulePath\RegistryUtils.psm1" -ErrorAction Stop
Import-Module "$modulePath\ServiceManager.psm1" -ErrorAction Stop
```

### Step 4: Implement Your Logic

Replace the `TODO` sections with your specific logic:

**For Audit Scripts:**
```powershell
function Get-AuditResult {
    # Implement your audit logic here
    $result = [PSCustomObject]@{
        Status = "Compliant"  # or "Non-Compliant"
        Message = "Your audit message"
        Details = "Additional details"
    }
    return $result
}
```

**For Remediation Scripts:**
```powershell
function Get-CurrentState {
    # Retrieve current configuration
    $state = [PSCustomObject]@{
        CurrentValue = "current"
        ExpectedValue = "expected"
        IsCompliant = $false
    }
    return $state
}

function Apply-Remediation {
    param([PSCustomObject]$State)
    try {
        # Apply your remediation changes
        return $true
    } catch {
        return $false
    }
}
```

**For Optimization Scripts:**
```powershell
function Get-CurrentSetting {
    # Retrieve current setting value
    $setting = [PSCustomObject]@{
        CurrentValue = 1
        ValueType = "DWORD"
        Path = "HKLM:\..."
    }
    return $setting
}

function Set-OptimizedValue {
    param([object]$Value)
    try {
        # Apply your optimization
        return $true
    } catch {
        return $false
    }
}
```

### Step 5: Customize Main Execution

Adjust the main execution block to fit your specific needs:

```powershell
# Get current setting
$currentSetting = Get-CurrentSetting
$previousValue = $currentSetting.CurrentValue

# Determine target value (customize as needed)
$targetValue = if ($previousValue -eq 1) { 0 } else { 1 }

# Apply optimization
$optimizationSuccess = Set-OptimizedValue -Value $targetValue
```

## CommonUtilities Module Functions

The templates leverage the [`CommonUtilities.psm1`](../../modules/CommonUtilities.psm1) module which provides:

### [`Get-ModulePath`](../../modules/CommonUtilities.psm1:215)
Returns the absolute path to the modules directory for consistent imports.

```powershell
$modulePath = Get-ModulePath
Import-Module "$modulePath\YourModule.psm1"
```

### [`Test-AdminRights`](../../modules/CommonUtilities.psm1:60)
Checks if the current PowerShell session has administrative privileges.

```powershell
if (Test-AdminRights) {
    Write-Host "Running as Administrator"
}
```

### [`Handle-CommonError`](../../modules/CommonUtilities.psm1:105)
Provides structured error handling with classification and recommendations.

```powershell
try {
    # Your code
} catch {
    $errorInfo = Handle-CommonError -ErrorRecord $_ -Context "Registry modification"
    Write-Error $errorInfo.ErrorMessage
}
```

### [`Wait-OnError`](../../modules/CommonUtilities.psm1:21)
Displays error messages with troubleshooting steps and waits for user input.

```powershell
Wait-OnError -ErrorMessage "Operation failed" -Troubleshooting "Run as Administrator"
```

### [`Test-ServiceExists`](../../modules/CommonUtilities.psm1:77)
Checks if a Windows service exists.

```powershell
if (Test-ServiceExists -ServiceName "Spooler") {
    Write-Host "Print Spooler exists"
}
```

## Best Practices

1. **Keep Functions Simple**: Each function should be under 15 lines of complexity. Break complex logic into smaller functions.

2. **Use Standardized Error Handling**: Always use [`Handle-CommonError`](../../modules/CommonUtilities.psm1:105) for consistent error reporting.

3. **Check Admin Rights Early**: Use [`Test-AdminRights`](../../modules/CommonUtilities.psm1:60) at the beginning of execution.

4. **Import Modules Consistently**: Use [`Get-ModulePath`](../../modules/CommonUtilities.psm1:215) for all module imports.

5. **Provide Clear Output**: Use color-coded messages for status (Green=Success, Red=Error, Yellow=Warning, Cyan=Info).

6. **Document Your Changes**: Update the script header with accurate descriptions and version information.

7. **Test Thoroughly**: Always test scripts in a non-production environment first.

## Function Complexity Guidelines

To maintain the 15-line complexity limit:

- **Do**: Break complex operations into multiple small functions
- **Do**: Use helper functions for repeated logic
- **Don't**: Nest multiple if/else statements deeply
- **Don't**: Put long switch statements in one function
- **Don't**: Combine multiple unrelated operations

Example of good structure:
```powershell
function Get-RegistryValue {
    param([string]$Path, [string]$Name)
    return Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
}

function Compare-Value {
    param([object]$Actual, [object]$Expected)
    return $Actual -eq $Expected
}

function Get-AuditResult {
    $current = Get-RegistryValue -Path "HKLM:\..." -Name "Setting"
    $isCompliant = Compare-Value -Actual $current -Expected 1
    return [PSCustomObject]@{ Status = if ($isCompliant) { "Compliant" } else { "Non-Compliant" } }
}
```

## Migration Guide

When migrating existing scripts to use these templates:

1. **Identify the script type** (audit, remediation, or optimization)
2. **Copy the appropriate template** to a new file
3. **Extract the core logic** from your existing script
4. **Place logic in the appropriate placeholder functions**
5. **Remove duplicated boilerplate** (Wait-OnError, admin checks, etc.)
6. **Update module imports** to use [`Get-ModulePath`](../../modules/CommonUtilities.psm1:215)
7. **Test the migrated script** thoroughly

## Additional Resources

- [`CommonUtilities.psm1`](../../modules/CommonUtilities.psm1) - Core utility functions
- [`RegistryUtils.psm1`](../../modules/RegistryUtils.psm1) - Registry operations
- [`ServiceManager.psm1`](../../modules/ServiceManager.psm1) - Service management
- [`CISRemediation.psm1`](../../modules/CISRemediation.psm1) - CIS benchmark remediation
- [`VisualEffects.psm1`](../../modules/VisualEffects.psm1) - Visual effects management

## Support

For issues or questions about the templates:
1. Check the [`CommonUtilities.psm1`](../../modules/CommonUtilities.psm1) module documentation
2. Review existing scripts that use these templates
3. Consult the project [`README.md`](../../README.md) for general guidelines
