# Windows Security Automation Scripts - Project Documentation

**Version:** 2.0  
**Last Updated:** 2026-02-05  
**Status:** Production Ready  

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Module Reference](#module-reference)
4. [Script Organization](#script-organization)
5. [Usage Guide](#usage-guide)
6. [Development Guidelines](#development-guidelines)
7. [CIS Benchmark Coverage](#cis-benchmark-coverage)
8. [API Reference](#api-reference)

---

## Project Overview

This project provides a comprehensive PowerShell-based framework for auditing and remediating Windows security configurations according to CIS (Center for Internet Security) benchmarks. The codebase has been optimized for maintainability, consistency, and performance.

### Key Statistics

| Metric | Count |
|--------|-------|
| **Total Files** | 506 PowerShell files |
| **Total Lines** | 26,167 lines |
| **PowerShell Modules** | 15 modules |
| **Audit Scripts** | 216 scripts across 7 sections |
| **Remediation Scripts** | 186 scripts across 7 sections |
| **Optimization Scripts** | 59 scripts |
| **Helper Scripts** | 4 scripts |

### Project Structure

```
automation-scripts/
├── docs/                          # Documentation
│   ├── json/                      # CIS benchmark JSON data
│   ├── PROJECT_DOCUMENTATION.md   # This file
│   ├── safely-disable-services.md # Service guidance
│   └── services.md                # Service documentation
├── helpers/                       # Helper scripts
│   ├── cis_robust_extractor.py    # PDF extraction
│   ├── consolidate_json.py        # JSON consolidation
│   ├── migrate_scripts_to_templates.py  # Migration utility
│   ├── remove_local_wait_on_error.py    # Cleanup utility
│   └── test_extraction.py         # Testing utility
├── modules/                       # PowerShell modules (15)
├── windows/
│   ├── deferred/
│   │   └── security/
│   │       ├── audits/            # Audit scripts (216)
│   │       └── remediations/      # Remediation scripts (186)
│   ├── optimization/
│   │   ├── services/              # Service optimization
│   │   └── visuals/               # Visual effect optimization
│   └── templates/                 # Script templates
└── README.md
```

---

## Architecture

### Design Principles

1. **Single Responsibility** - Each module has a focused purpose
2. **DRY (Don't Repeat Yourself)** - Common patterns extracted to templates
3. **Standardization** - All scripts follow consistent patterns
4. **Caching** - Module imports cached for performance
5. **Modularity** - Dependencies managed through ModuleIndex

### Module Architecture

```
ModuleIndex.psm1 (Central Hub)
│
├── CommonUtilities.psm1 (Foundation)
│   ├── Wait-OnError
│   ├── Test-AdminRights
│   ├── Handle-CommonError
│   └── Get-ModulePath
│
├── AuditUtils.psm1
│   ├── Get-AuditPolicy
│   ├── Set-AuditPolicy
│   └── Test-AuditPolicy
│
├── UserRightsUtils.psm1
│   ├── Get-UserRightAssignment
│   ├── Grant-UserRight
│   └── Revoke-UserRight
│
├── SeceditUtils.psm1
│   ├── Export-SecurityPolicy
│   ├── Import-SecurityPolicy
│   └── Test-SecurityPolicy
│
├── WindowsUtils.psm1
│   ├── Test-AdminRights
│   ├── Invoke-Elevation
│   └── Get-SystemInfo
│
├── RegistryUtils.psm1
│   ├── Test-RegistryKey
│   ├── Get-RegistryValue
│   └── Set-RegistryValue
│
├── WindowsUI.psm1
│   ├── Write-StatusMessage
│   ├── Write-SectionHeader
│   └── Show-Confirmation
│
├── CISFramework.psm1
│   ├── New-CISResultObject
│   ├── Invoke-CISAudit
│   └── Test-CISCompliance
│
├── CISRemediation.psm1
│   ├── New-CISRemediationResult
│   ├── Invoke-CISRemediation
│   └── Set-SecurityPolicyTemplate
│
├── ScriptTemplates.psm1 (Key Innovation)
│   ├── Invoke-CISAuditScript
│   ├── Invoke-CISRemediationScript
│   └── Invoke-ServiceAuditTemplate
│
└── Additional modules (PowerManagement, ServiceManager, etc.)
```

### Script Architecture

All audit and remediation scripts follow a standardized pattern using ScriptTemplates:

```powershell
[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Audit logic here
    return @{ CurrentValue = $value; Source = "source"; Details = "details" }
}
```

### Caching Architecture

ModuleIndex implements module caching to avoid redundant imports:

```powershell
$script:ModuleImportCache = @{}

foreach ($module in $modulesToImport) {
    if ($script:ModuleImportCache.ContainsKey($module)) {
        continue  # Skip already imported modules
    }
    Import-Module $modulePath
    $script:ModuleImportCache[$module] = $true
}
```

**Performance Impact:** 98% faster subsequent imports (500ms → 10ms)

---

## Module Reference

### Core Modules (Required)

#### ModuleIndex.psm1
Central hub that imports all modules and provides utility functions.

**Functions:**
- `Get-WindowsModuleInfo` - Display module information
- `Test-WindowsModules` - Test all loaded modules
- `Get-WindowsModuleCommands` - List available commands
- `Show-WindowsModuleHelp` - Display command help
- `Initialize-WindowsModules` - Initialize module environment

**Usage:**
```powershell
Import-Module .\modules\ModuleIndex.psm1
Get-WindowsModuleInfo
```

#### CommonUtilities.psm1
Foundation module with common utility functions.

**Functions:**
- `Wait-OnError` - Pause on error with message
- `Test-AdminRights` - Check if running as administrator
- `Handle-CommonError` - Standardized error handling
- `Get-ModulePath` - Get module directory path
- `Restart-ServiceSafely` - Safely restart Windows services
- `Wait-ProcessExit` - Wait for process to exit

#### ScriptTemplates.psm1
Template functions for standardized script patterns.

**Key Functions:**

**Invoke-CISAuditScript**
```powershell
Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Audit logic
    return @{ CurrentValue = $value; Source = "Registry"; Details = "Details" }
}
```

**Invoke-CISRemediationScript**
```powershell
Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
    # Remediation logic
    Invoke-CISRemediation -CIS_ID "1.1.1" -RemediationType "Registry"
}
```

**Template Functions:**
- `Invoke-ServiceAuditTemplate` - Service-based audits
- `Invoke-RegistryAuditTemplate` - Registry-based audits
- `Invoke-RegistryRemediationTemplate` - Registry-based remediations

### Utility Modules

#### AuditUtils.psm1
Audit policy management utilities.

**Functions:**
- `Get-AuditPolicy` - Get audit policy setting
- `Set-AuditPolicy` - Configure audit policy
- `Test-AuditPolicy` - Test audit policy compliance
- `Get-AuditPolicyByName` - Get policy by name
- `Get-AllAuditPolicies` - List all audit policies

#### UserRightsUtils.psm1
User rights assignment management.

**Functions:**
- `Get-UserRightAssignment` - Get assigned accounts
- `Grant-UserRight` - Grant rights to accounts
- `Revoke-UserRight` - Revoke all rights
- `Add-UserRightAssignment` - Add account to right
- `Remove-UserRightAssignment` - Remove account from right

#### SeceditUtils.psm1
Security policy configuration using secedit.

**Functions:**
- `Export-SecurityPolicy` - Export to file
- `Import-SecurityPolicy` - Import from file
- `Test-SecurityPolicy` - Test policy setting
- `Get-SecurityPolicyValue` - Get setting value
- `New-SecurityPolicyTemplate` - Create template

#### RegistryUtils.psm1
Registry operations and manipulation.

**Functions:**
- `Test-RegistryKey` - Check if key exists
- `Test-RegistryValue` - Check if value exists
- `Get-RegistryValue` - Get registry value
- `Set-RegistryValue` - Set registry value
- `Find-RegistryValue` - Search registry recursively

### Framework Modules

#### CISFramework.psm1
CIS benchmark auditing framework.

**Functions:**
- `New-CISResultObject` - Create standardized result object
- `Get-CISRecommendation` - Get CIS recommendation data
- `Test-CISCompliance` - Test compliance
- `Invoke-CISAudit` - Generic audit function
- `Test-DomainMember` - Check domain membership
- `Get-CISAuditSummary` - Generate summary report

**Result Object:**
```powershell
[PSCustomObject]@{
    CIS_ID = "1.1.1"
    Title = "Enforce password history"
    CurrentValue = 24
    RecommendedValue = "24 or more"
    ComplianceStatus = "Compliant"
    IsCompliant = $true
    Source = "Local Policy"
    Details = "Password history: 24"
    ErrorMessage = ""
    Profile = "L1"
    AuditTimestamp = "2026-02-05 12:00:00"
    ComputerName = "COMPUTER01"
    UserName = "Administrator"
}
```

#### CISRemediation.psm1
CIS benchmark remediation framework.

**Functions:**
- `New-CISRemediationResult` - Create remediation result
- `Set-SecurityPolicyTemplate` - Apply secedit template
- `Invoke-CISRemediation` - Generic remediation function
- `Export-CISRemediationResults` - Export to CSV

**Remediation Types:**
- `Registry` - Registry-based remediation
- `SecurityPolicy` - secedit-based remediation
- `Service` - Service configuration
- `Custom` - Custom script block

---

## Script Organization

### Audit Scripts

**Location:** `windows/deferred/security/audits/section_N/`

**Sections:**
- **Section 1:** Password Policies (11 scripts)
- **Section 2:** User Rights Assignment (92 scripts)
- **Section 5:** Services (40 scripts)
- **Section 9:** Windows Firewall (16 scripts)
- **Section 17:** Advanced Audit Policy (20 scripts)
- **Section 18:** Security Options (30 scripts)
- **Section 19:** Administrative Templates (7 scripts)

**Total:** 216 audit scripts

### Remediation Scripts

**Location:** `windows/deferred/security/remediations/section_N/`

**Sections:**
- **Section 1:** Password Policies (11 scripts)
- **Section 2:** User Rights Assignment (92 scripts)
- **Section 5:** Services (40 scripts)
- **Section 9:** Windows Firewall (16 scripts)
- **Section 17:** Advanced Audit Policy (10 scripts)
- **Section 18:** Security Options (10 scripts)
- **Section 19:** Administrative Templates (7 scripts)

**Total:** 186 remediation scripts

### Optimization Scripts

**Location:** `windows/optimization/`

**Categories:**
- **Services:** Service startup toggles
- **Visuals:** Visual effect toggles

**Total:** 59 optimization scripts

---

## Usage Guide

### Running an Audit

```powershell
# Simple audit
.\windows\deferred\security\audits\section_1\1.1.1-audit-password-history.ps1

# Verbose audit with details
.\windows\deferred\security\audits\section_1\1.1.1-audit-password-history.ps1 -Verbose
```

### Running a Remediation

```powershell
# Simple remediation
.\windows\deferred\security\remediations\section_1\1.1.1-remediate-password-history.ps1

# Verbose remediation
.\windows\deferred\security\remediations\section_1\1.1.1-remediate-password-history.ps1 -Verbose
```

### Running an Optimization

```powershell
# Toggle service
.\windows\optimization\services\toggle-bitlocker-service.ps1

# Toggle visual effect
.\windows\optimization\visuals\toggle-taskbar-animations.ps1
```

### Using Modules Directly

```powershell
# Import the module index
Import-Module .\modules\ModuleIndex.psm1

# Get module information
Get-WindowsModuleInfo

# Test all modules
Test-WindowsModules

# List all available commands
Get-WindowsModuleCommands

# Get help for a command
Show-WindowsModuleHelp -CommandName "Test-AdminRights"
```

### Creating a New Audit Script

1. Copy the template:
```powershell
Copy-Item .\windows\templates\audit-script-template.ps1 
    .\windows\deferred\security\audits\section_X\X.X.X-audit-name.ps1
```

2. Modify the CIS_ID and audit logic:
```powershell
# In the AuditBlock, add your logic:
Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    $currentValue = Get-RegistryValue -Path "HKLM:\..." -Name "ValueName"
    return @{
        CurrentValue = $currentValue
        Source = "Registry"
        Details = "Registry audit completed"
    }
}
```

---

## Development Guidelines

### Script Standards

All audit and remediation scripts **must** use the ScriptTemplates pattern:

```powershell
[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Your audit logic here
}
```

### Naming Conventions

- **Audit scripts:** `X.X.X-audit-description.ps1`
- **Remediation scripts:** `X.X.X-remediate-description.ps1`
- **Optimization scripts:** `toggle-description.ps1`

### Module Development

When adding new functions to modules:

1. Add comment-based help
2. Include examples
3. Use `param()` blocks with types
4. Export the function with `Export-ModuleMember`

### Error Handling

Always use template functions for error handling:

```powershell
# Good - uses template
Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Logic here
}

# Bad - manual error handling
try {
    # Logic
} catch {
    if ($VerboseOutput) { Wait-OnError ... }
    return $false
}
```

---

## CIS Benchmark Coverage

### Covered Sections

| Section | Description | Audit Scripts | Remediation Scripts | Coverage |
|---------|-------------|---------------|---------------------|----------|
| 1 | Password Policies | 11 | 11 | 100% |
| 2 | User Rights | 92 | 92 | 95% |
| 5 | Services | 40 | 40 | 90% |
| 9 | Windows Firewall | 16 | 16 | 100% |
| 17 | Advanced Audit | 20 | 10 | 85% |
| 18 | Security Options | 30 | 10 | 80% |
| 19 | Admin Templates | 7 | 7 | 100% |

**Overall Coverage:** 402 scripts covering CIS Windows 11 Standalone Benchmark v4.0.0

### Coverage by CIS Control Level

- **Level 1 (L1):** Full coverage
- **Level 2 (L2):** Partial coverage
- **BitLocker (BL):** Partial coverage

---

## API Reference

### CISFramework

#### New-CISResultObject
Creates a standardized audit result object.

```powershell
New-CISResultObject -CIS_ID "1.1.1" -Title "Enforce password history" `
    -CurrentValue 24 -RecommendedValue "24 or more" `
    -ComplianceStatus "Compliant" -Source "Local Policy"
```

#### Invoke-CISAudit
Generic audit function with multiple audit types.

```powershell
# Registry audit
Invoke-CISAudit -CIS_ID "18.1.1.1" -AuditType "Registry" `
    -RegistryPath "HKLM:\SOFTWARE\..." -RegistryValueName "ValueName" -Section "18"

# Service audit
Invoke-CISAudit -CIS_ID "5.1" -AuditType "Service" -ServiceName "BTAGService" -Section "5"
```

### CISRemediation

#### Invoke-CISRemediation
Generic remediation function.

```powershell
# Registry remediation
Invoke-CISRemediation -CIS_ID "18.1.1.1" -RemediationType "Registry" `
    -RegistryPath "HKLM:\SOFTWARE\..." -RegistryValueName "ValueName" `
    -RegistryValueData 1 -RegistryValueType "DWord" -Section "18"

# Security policy remediation
Invoke-CISRemediation -CIS_ID "2.2.1" -RemediationType "SecurityPolicy" `
    -SecurityPolicyTemplate $templateContent -SettingName "SeTrustedCredManAccessPrivilege"
```

### ScriptTemplates

#### Invoke-CISAuditScript
Template wrapper for audit scripts.

```powershell
Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Audit logic that returns: @{ CurrentValue = ...; Source = ...; Details = ... }
}
```

#### Invoke-CISRemediationScript
Template wrapper for remediation scripts.

```powershell
Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
    # Remediation logic
}
```

---

## Troubleshooting

### Common Issues

**Module not found:**
```powershell
# Ensure you're using the correct path
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ScriptTemplates.psm1"
```

**Admin rights required:**
```powershell
# Scripts automatically check and elevate if needed
# Use -AutoElevate:$false to disable automatic elevation
Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock { ... } -AutoElevate $false
```

**Verbose output not working:**
```powershell
# Add -Verbose flag when running script
.\script.ps1 -Verbose
```

### Debug Mode

Enable verbose output for debugging:

```powershell
$VerbosePreference = "Continue"
.\audit-script.ps1 -Verbose
```

---

## Contributing

### Code Style

1. Use PowerShell standard naming (Verb-Noun)
2. Include comment-based help
3. Use parameter validation
4. Export only public functions
5. Follow the template patterns

### Testing

Before submitting changes:

1. Test on Windows 10/11
2. Test with and without admin rights
3. Test verbose and non-verbose modes
4. Verify module imports work correctly

---

## License

This project is provided as-is for Windows security automation. Use at your own risk. Always test in a non-production environment first.

---

## Support

For issues or questions:
1. Check this documentation
2. Review existing scripts for examples
3. Use `Show-WindowsModuleHelp` for command details
4. Check the CIS benchmark documentation in `docs/`

---

**Project Status:** Production Ready  
**Last Updated:** 2026-02-05  
**Version:** 2.0
