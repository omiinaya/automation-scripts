# Windows Security Audit Scripts

This directory contains PowerShell scripts for auditing Windows security settings based on CIS benchmarks.

## Available Audit Scripts

### [`audit-password-history.ps1`](audit-password-history.ps1)

**CIS Benchmark**: 1.1.1 (L1) Ensure 'Enforce password history' is set to '24 or more password(s)'

**Description**: Audits the password history enforcement setting to ensure compliance with CIS benchmark recommendations.

**Features**:
- Detects whether the system is domain-joined or standalone
- Retrieves password policy settings using appropriate methods (`net accounts` for domain, `secedit` for standalone)
- Provides clear compliance status (Compliant/Non-Compliant)
- Displays detailed audit results in formatted tables
- Includes remediation guidance for non-compliant systems

**Usage**:
```powershell
# Run with PowerShell (admin rights required)
.\audit-password-history.ps1
```

**Expected Output**:
- Section header with audit title
- Domain/standalone detection status
- Current password history value
- Compliance status
- Detailed audit report table
- Additional information and remediation guidance

**Requirements**:
- Windows PowerShell 5.1 or later
- Administrative privileges
- Execution policy allowing script execution

**Compliance Criteria**:
- **Compliant**: Password history setting is 24 or more
- **Non-Compliant**: Password history setting is less than 24

## Script Architecture

All audit scripts follow a consistent pattern:

1. **Error Handling**: Custom `Wait-OnError` function for graceful error handling
2. **Module Import**: Uses the shared Windows modules from `..\..\modules\`
3. **Admin Check**: Verifies administrative privileges and requests elevation if needed
4. **Audit Logic**: Performs the specific security setting audit
5. **Reporting**: Provides formatted output with compliance status
6. **Remediation**: Offers guidance for fixing non-compliant settings

## Common Functions Used

- [`Test-AdminRights`](../../modules/WindowsUtils.psm1): Checks for administrative privileges
- [`Request-Elevation`](../../modules/WindowsUtils.psm1): Requests UAC elevation if needed
- [`Write-StatusMessage`](../../modules/WindowsUI.psm1): Displays formatted status messages
- [`Write-SectionHeader`](../../modules/WindowsUI.psm1): Creates section headers
- [`Show-Table`](../../modules/WindowsUI.psm1): Displays data in formatted tables

## Adding New Audit Scripts

When creating new audit scripts:

1. Follow the established pattern in existing scripts
2. Use the shared modules for common functionality
3. Include proper error handling
4. Provide clear compliance criteria
5. Add remediation guidance for non-compliant settings
6. Update this README with script documentation

## CIS Benchmark References

All scripts reference specific CIS benchmark controls:
- **Level 1 (L1)**: Basic security controls suitable for most environments
- **Level 2 (L2)**: Enhanced security controls for high-security environments

Script filenames include the CIS benchmark reference for easy identification.