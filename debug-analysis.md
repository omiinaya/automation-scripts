# Debug Analysis: toggle-lid-close.ps1 One-Way Toggle Issue

## Problem Description
The `toggle-lid-close.ps1` script reports working correctly when toggling from "Sleep" to "Do nothing", but fails to toggle back from "Do nothing" to "Sleep".

## Root Cause Analysis

After examining the code, I've identified several potential issues in the parsing and state detection logic:

### 1. **Critical Issue: Incorrect GUID Structure in PowerCFG Query**

The script is using the wrong parameter structure for the powercfg query command:

**Current (incorrect) usage:**
```powershell
$lidSettings = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
```

**Correct usage should be:**
```powershell
$lidSettings = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
```

However, the actual structure should include the subgroup parameter explicitly. The issue is that the GUIDs are being passed in the wrong order or format.

### 2. **PowerCFG Query Structure Analysis**

Based on PowerShell PowerManagement module, the correct query format is:
```powershell
powercfg /query <SCHEME_GUID> <SUBGROUP_GUID> <SETTING_GUID>
```

In the script:
- `$lidCloseGUID` (5ca83367-6e45-459f-a27b-476b1d01c936) - This is actually the **SETTING_GUID**
- `$powerSettingSubgroup` (4f971e89-eebd-4455-a8de-9e59040e7347) - This is the **SUBGROUP_GUID**

The structure appears correct, but there might be an issue with how the powercfg output is being parsed.

### 3. **Parsing Issues Identified**

Looking at the regex patterns:

```powershell
if ($line -match "Current DC Power Setting Index:\s+0x([0-9a-fA-F]+)")
if ($line -match "Current AC Power Setting Index:\s+0x([0-9a-fA-F]+)")
```

**Potential Issues:**
1. **Case sensitivity**: The regex might not match if the case is different
2. **Whitespace variations**: Extra spaces or tabs might break the regex
3. **Output format changes**: Different Windows versions might format the output differently

### 4. **State Detection Logic Issues**

The script has these fallback defaults:
```powershell
if ($null -eq $currentDC) { $currentDC = 1 }  # Default to Sleep (1)
if ($null -eq $currentAC) { $currentAC = 1 }  # Default to Sleep (1)
```

This creates a **dangerous fallback scenario**:
- If parsing fails, the script assumes the current state is "Sleep" (1)
- This would cause the toggle logic to always set it to "Do nothing" (0)
- When actually in "Do nothing" state, it would incorrectly toggle back to "Do nothing" instead of "Sleep"

### 5. **Verification Logic Flaws**

The verification step uses:
```powershell
$verificationPassed = ($verifiedDC -eq $newValue -and $verifiedAC -eq $newValue) -or
                      ($verifiedDC -eq $newValue -or $verifiedAC -eq $newValue)
```

This logic is flawed because:
- It uses OR logic which is too permissive
- It might report success even when only one value changed

## Proposed Fixes

### Fix 1: Improve Regex Patterns
```powershell
# More flexible regex patterns
$line -match "Current\s+DC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)"
$line -match "Current\s+AC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)"
```

### Fix 2: Better Error Handling
```powershell
# Instead of defaulting to 1, throw an error if parsing fails
if ($null -eq $currentDC -or $null -eq $currentAC) {
    throw "Failed to parse current lid close settings from powercfg output"
}
```

### Fix 3: Enhanced Debugging
```powershell
# Add detailed logging
Write-Host "Raw powercfg output:"
$lidSettings | ForEach-Object { Write-Host "  $_" }

Write-Host "Parsed values:"
Write-Host "  DC: $currentDC"
Write-Host "  AC: $currentAC"
```

### Fix 4: Use Module Functions
Instead of direct powercfg calls, use the PowerManagement module functions:

```powershell
$lidSetting = Get-PowerSetting -SettingGUID $lidCloseGUID -PowerSchemeGUID $powerScheme
$currentDC = $lidSetting.DCValue
$currentAC = $lidSetting.ACValue
```

### Fix 5: Fix Verification Logic
```powershell
# Stricter verification
$verificationPassed = ($verifiedDC -eq $newValue -and $verifiedAC -eq $newValue)
```

## Testing Strategy

1. **Manual PowerCFG Test**: Run `powercfg /query <scheme> 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936` to see actual output format

2. **State Change Test**: Set lid close to "Do nothing" manually, then run the script to verify it toggles back

3. **Edge Case Testing**: Test with different power schemes and power states

## Conclusion

The most likely root cause is **parsing failure** combined with **dangerous fallback defaults**. When the regex fails to extract the actual values, the script defaults to assuming the current state is "Sleep", causing it to always toggle to "Do nothing" regardless of the actual current state.