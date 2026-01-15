# CIS Remediation Script for 2.3.7.2: Interactive logon: Don't display last signed-in
# Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'

<#
.SYNOPSIS
    CIS Remediation Script for 2.3.7.2 - Interactive logon: Don't display last signed-in

.DESCRIPTION
    This script remediates the compliance status of CIS control 2.3.7.2 which ensures
    that the last signed-in user name is not displayed on the Windows logon screen.

.PARAMETER Force
    If specified, will apply remediation without prompting for confirmation.

.EXAMPLE
    .\2.3.7.2-remediate-interactive-logon-dont-display-last-signed-in.ps1

.EXAMPLE
    .\2.3.7.2-remediate-interactive-logon-dont-display-last-signed-in.ps1 -Force

.NOTES
    CIS ID: 2.3.7.2
    Profile: L1
    Registry Path: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System:DontDisplayLastUserName
    Required Value: 1 (Enabled)
    Group Policy Path: Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\Interactive logon: Don't display last signed-in
#>

param(
    [switch]$Force
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Import required modules
Import-Module $PSScriptRoot\..\..\modules\CISRemediation.psm1 -ErrorAction Stop

# CIS Control Information
$CisId = "2.3.7.2"
$CisTitle = "Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'"
$CisProfile = "L1"

# Registry configuration for remediation
$RegistryRemediation = @(
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Name = "DontDisplayLastUserName"
        Type = "DWORD"
        Value = 1
        Description = "Don't display last signed-in user name"
        BackupRequired = $true
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        Name = "DontDisplayLastUserName"
        Type = "DWORD"
        Value = 1
        Description = "Group Policy setting for don't display last signed-in"
        BackupRequired = $true
    }
)

# Group Policy configuration
$GroupPolicyPath = "Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\Interactive logon: Don't display last signed-in"
$RequiredGpoValue = "Enabled"

# Display script header
Write-CISScriptHeader -CisId $CisId -Title $CisTitle -Profile $CisProfile -Action "Remediation"

# Check if running as administrator
if (-not (Test-IsAdministrator)) {
    Write-Error "This script must be run as Administrator. Please run PowerShell as Administrator and try again."
    exit 1
}

# Display remediation summary
Write-Host "Remediation Summary:" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow
Write-Host "This script will configure the following settings:" -ForegroundColor Yellow
Write-Host ""

foreach ($config in $RegistryRemediation) {
    Write-Host "Registry: $($config.Path)\$($config.Name)" -ForegroundColor Cyan
    Write-Host "  Set to: $($config.Value) ($($config.Type))" -ForegroundColor White
    Write-Host "  Purpose: $($config.Description)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Group Policy: $GroupPolicyPath" -ForegroundColor Cyan
Write-Host "  Set to: $RequiredGpoValue" -ForegroundColor White
Write-Host ""

# Confirm remediation unless -Force parameter is used
if (-not $Force) {
    $confirmation = Read-Host "Do you want to proceed with remediation? (Y/N)"
    if ($confirmation -notmatch "^[Yy]") {
        Write-Host "Remediation cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

# Initialize remediation tracking
$RemediationResults = @()
$OverallSuccess = $true

# Remediate registry settings
Write-Host "Remediating Registry Settings..." -ForegroundColor Cyan

foreach ($config in $RegistryRemediation) {
    try {
        $result = Set-RegistryValue @config
        $RemediationResults += $result
        
        if ($result.Success) {
            Write-Host "  SUCCESS: $($config.Description)" -ForegroundColor Green
        } else {
            Write-Host "  FAILED: $($config.Description)" -ForegroundColor Red
            Write-Host "    Error: $($result.ErrorMessage)" -ForegroundColor Red
            $OverallSuccess = $false
        }
    }
    catch {
        Write-Host "  ERROR: $($config.Description)" -ForegroundColor Red
        Write-Host "    Exception: $($_.Exception.Message)" -ForegroundColor Red
        $OverallSuccess = $false
        $RemediationResults += @{
            Description = $config.Description
            Success = $false
            ErrorMessage = $_.Exception.Message
        }
    }
}

# Remediate Group Policy setting
Write-Host "Remediating Group Policy Setting..." -ForegroundColor Cyan

try {
    $gpoResult = Set-GroupPolicySetting -PolicyPath $GroupPolicyPath -Value $RequiredGpoValue
    $RemediationResults += $gpoResult
    
    if ($gpoResult.Success) {
        Write-Host "  SUCCESS: Group Policy setting configured" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Group Policy setting configuration" -ForegroundColor Red
        Write-Host "    Error: $($gpoResult.ErrorMessage)" -ForegroundColor Red
        $OverallSuccess = $false
    }
}
catch {
    Write-Host "  ERROR: Group Policy setting configuration" -ForegroundColor Red
    Write-Host "    Exception: $($_.Exception.Message)" -ForegroundColor Red
    $OverallSuccess = $false
    $RemediationResults += @{
        Description = "Group Policy Setting"
        Success = $false
        ErrorMessage = $_.Exception.Message
    }
}

# Display remediation summary
Write-Host ""
Write-Host "Remediation Summary:" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow

foreach ($result in $RemediationResults) {
    $status = if ($result.Success) { "SUCCESS" } else { "FAILED" }
    $color = if ($result.Success) { "Green" } else { "Red" }
    
    Write-Host "$($result.Description): $status" -ForegroundColor $color
}

# Final remediation status
Write-Host ""
if ($OverallSuccess) {
    Write-Host "REMEDIATION STATUS: COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "All settings have been configured according to CIS benchmark requirements." -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: Some changes may require a system restart or Group Policy update to take effect." -ForegroundColor Yellow
    Write-Host "      Run 'gpupdate /force' to refresh Group Policy settings immediately." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "REMEDIATION STATUS: PARTIALLY COMPLETED" -ForegroundColor Red
    Write-Host "Some settings could not be configured. Please review the errors above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual Remediation Required:" -ForegroundColor Yellow
    Write-Host "- Check registry permissions and ensure running as Administrator" -ForegroundColor Yellow
    Write-Host "- Verify Group Policy permissions and connectivity" -ForegroundColor Yellow
    exit 1
}

# Log remediation execution
Write-CISRemediationLog -CisId $CisId -Success $OverallSuccess -Results $RemediationResults