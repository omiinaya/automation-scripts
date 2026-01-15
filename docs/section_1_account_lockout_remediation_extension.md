# Section 1 Account Lockout Remediation Extension

## Overview

This document summarizes the extension of the CIS script generator to handle all Section 1 controls, including both password policies (1.1.1-1.1.7) and account lockout controls (1.2.1-1.2.4).

## What Was Extended

### Password Policy Controls (Already Complete)
The script generator already supported password policy controls:
- **1.1.1**: Enforce password history
- **1.1.2**: Maximum password age  
- **1.1.3**: Minimum password age
- **1.1.4**: Minimum password length
- **1.1.5**: Password complexity requirements
- **1.1.6**: Relax minimum password length limits
- **1.1.7**: Store passwords using reversible encryption

### Account Lockout Controls (Newly Added)
The following account lockout controls were added:

#### 1.2.1 - Account Lockout Duration
- **CIS Benchmark**: Ensure 'Account lockout duration' is set to '15 or more minute(s)'
- **Setting Name**: `LockoutDuration`
- **Recommended Value**: 15 minutes
- **Template Pattern**: Security policy template using secedit

#### 1.2.2 - Account Lockout Threshold  
- **CIS Benchmark**: Ensure 'Account lockout threshold' is set to '5 or fewer invalid logon attempt(s), but not 0'
- **Setting Name**: `LockoutBadCount`
- **Recommended Value**: 5 attempts
- **Template Pattern**: Security policy template using secedit

#### 1.2.3 - Allow Administrator Account Lockout
- **CIS Benchmark**: Ensure 'Allow Administrator account lockout' is set to 'Enabled'
- **Setting Name**: `AllowAdministratorAccountLockout`
- **Recommended Value**: 1 (Enabled)
- **Template Pattern**: Security policy template using secedit

#### 1.2.4 - Reset Account Lockout Counter After
- **CIS Benchmark**: Ensure 'Reset account lockout counter after' is set to '15 or more minute(s)'
- **Setting Name**: `ResetLockoutCount`
- **Recommended Value**: 15 minutes
- **Template Pattern**: Security policy template using secedit

## Technical Implementation

### Files Created

#### Remediation Scripts
- `windows/security/remediations/1.2.1-remediate-account-lockout-duration.ps1`
- `windows/security/remediations/1.2.2-remediate-account-lockout-threshold.ps1`
- `windows/security/remediations/1.2.3-remediate-allow-administrator-account-lockout.ps1`
- `windows/security/remediations/1.2.4-remediate-reset-account-lockout-counter-after.ps1`

#### Test Scripts
- `helpers/test_account_lockout_remediation.py` - Validation script
- `helpers/debug_import.py` - Debugging utility

### Framework Compatibility

All new scripts follow the existing CISRemediation framework patterns:

1. **Standardized Structure**: Each script follows the same template pattern
2. **Module Integration**: Uses `ModuleIndex.psm1` for module imports
3. **Admin Rights Check**: Includes elevation handling
4. **Security Policy Templates**: Uses secedit-based remediation
5. **Error Handling**: Comprehensive try-catch blocks
6. **Verbose Output Support**: Supports both silent and verbose modes

### Setting Names

The account lockout settings use the following secedit parameter names:
- `LockoutDuration` - Account lockout duration (minutes)
- `LockoutBadCount` - Account lockout threshold (attempts)  
- `AllowAdministratorAccountLockout` - Administrator account lockout (0/1)
- `ResetLockoutCount` - Reset lockout counter after (minutes)

## Validation

All scripts have been validated using the automated test script:
- ✅ CIS Benchmark header
- ✅ CmdletBinding attribute
- ✅ Module import pattern
- ✅ Admin rights check
- ✅ Security policy template
- ✅ CISRemediation framework integration
- ✅ Error handling
- ✅ CIS ID referencing

## Usage

### Running Individual Remediation
```powershell
# Run with verbose output
.\windows\security\remediations\1.2.1-remediate-account-lockout-duration.ps1 -Verbose

# Run silently (returns boolean compliance status)
.\windows\security\remediations\1.2.1-remediate-account-lockout-duration.ps1
```

### Batch Remediation
```powershell
# Import modules
$modulePath = Join-Path $PSScriptRoot "windows\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force

# Run all account lockout remediations
$results = @()
$results += Invoke-CISRemediation -CIS_ID "1.2.1" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $template1 -SettingName "LockoutDuration"
$results += Invoke-CISRemediation -CIS_ID "1.2.2" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $template2 -SettingName "LockoutBadCount"
$results += Invoke-CISRemediation -CIS_ID "1.2.3" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $template3 -SettingName "AllowAdministratorAccountLockout"
$results += Invoke-CISRemediation -CIS_ID "1.2.4" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $template4 -SettingName "ResetLockoutCount"

# Export results
Export-CISRemediationResults -Results $results -OutputPath "remediation_results.csv"
```

## Backward Compatibility

The extension maintains full backward compatibility:
- No changes to existing password policy scripts
- No modifications to core framework modules
- Existing audit scripts remain unchanged
- All new functionality uses established patterns

## Future Considerations

- The scripts currently handle standalone Windows systems
- Domain environments require manual policy changes (as documented)
- Consider adding registry-based fallback for settings not supported by secedit
- Future enhancements could include group policy template generation

## Conclusion

The script generator now comprehensively handles all Section 1 controls of the CIS Microsoft Windows 11 Benchmark, providing complete coverage for both password policies and account lockout policies using standardized, maintainable patterns.