# CIS Remediation Script for 2.3.1.4: Accounts: Rename guest account
# Configure 'Accounts: Rename guest account'

<#
.SYNOPSIS
    CIS Remediation Script for 2.3.1.4 - Accounts: Rename guest account

.DESCRIPTION
    This script remediates the compliance status of CIS control 2.3.1.4 which ensures
    that the built-in Guest account is renamed to something other than
    the default "Guest" name.

.PARAMETER NewName
    The new name to assign to the Guest account.

.PARAMETER Force
    If specified, will apply remediation without prompting for confirmation.

.EXAMPLE
    .\2.3.1.4-remediate-rename-guest-account.ps1 -NewName "Visitor01"

.EXAMPLE
    .\2.3.1.4-remediate-rename-guest-account.ps1 -NewName "Visitor01" -Force

.NOTES
    CIS ID: 2.3.1.4
    Profile: L1
    Group Policy Path: Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\Accounts: Rename guest account
    Required Value: Any value other than "Guest"
    Default Value: Guest
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$NewName,
    [switch]$Force
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Import required modules
Import-Module $PSScriptRoot\..\..\modules\CISRemediation.psm1 -ErrorAction Stop

# CIS Control Information
$CisId = "2.3.1.4"
$CisTitle = "Configure 'Accounts: Rename guest account'"
$CisProfile = "L1"

# Validate the new name
if ($NewName -eq "Guest") {
    Write-Error "The new name cannot be 'Guest'. Please choose a different name."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($NewName)) {
    Write-Error "The new name cannot be empty or whitespace."
    exit 1
}

# Group Policy configuration
$GroupPolicyPath = "Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\Accounts: Rename guest account"
$RequiredGpoValue = $NewName

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
Write-Host "Security Policy: Rename Guest account" -ForegroundColor Cyan
Write-Host "  Set to: $NewName" -ForegroundColor White
Write-Host "  Purpose: Rename the built-in Guest account for security" -ForegroundColor Gray
Write-Host ""
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

# Remediate security policy setting using secedit
Write-Host "Remediating Security Policy Setting..." -ForegroundColor Cyan

try {
    # Create security policy template
    $templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature=`"`$CHICAGO`$`"
Revision=1
[Registry Values]
MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\NewGuestName=$NewName
"@
    
    # Save template to temporary file
    $templateFile = [System.IO.Path]::GetTempFileName()
    $templateContent | Out-File -FilePath $templateFile -Encoding Unicode
    
    # Apply the security policy
    $databaseFile = [System.IO.Path]::GetTempFileName()
    secedit /configure /db $databaseFile /cfg $templateFile /quiet
    
    # Verify the change was applied
    $verifyFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $verifyFile /quiet
    
    $verifyContent = Get-Content $verifyFile
    $appliedValue = ($verifyContent | Where-Object { $_ -like "NewGuestName*" } | ForEach-Object { ($_ -split "=")[1].Trim() })
    
    if ($appliedValue -eq $NewName) {
        $result = @{
            Description = "Guest account name"
            Success = $true
            ErrorMessage = $null
        }
        Write-Host "  SUCCESS: Guest account renamed to '$NewName'" -ForegroundColor Green
    } else {
        $result = @{
            Description = "Guest account name"
            Success = $false
            ErrorMessage = "Failed to verify the name change was applied"
        }
        Write-Host "  FAILED: Could not verify Guest account rename" -ForegroundColor Red
        $OverallSuccess = $false
    }
    
    # Clean up temporary files
    Remove-Item $templateFile, $databaseFile, $verifyFile -ErrorAction SilentlyContinue
    
    $RemediationResults += $result
    
} catch {
    Write-Host "  ERROR: Failed to rename Guest account" -ForegroundColor Red
    Write-Host "    Exception: $($_.Exception.Message)" -ForegroundColor Red
    $OverallSuccess = $false
    $RemediationResults += @{
        Description = "Guest account name"
        Success = $false
        ErrorMessage = $_.Exception.Message
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
} catch {
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
    Write-Host "The Guest account has been renamed to '$NewName' according to CIS benchmark requirements." -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: Some changes may require a system restart or Group Policy update to take effect." -ForegroundColor Yellow
    Write-Host "      Run 'gpupdate /force' to refresh Group Policy settings immediately." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "REMEDIATION STATUS: PARTIALLY COMPLETED" -ForegroundColor Red
    Write-Host "Some settings could not be configured. Please review the errors above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual Remediation Required:" -ForegroundColor Yellow
    Write-Host "- Check security policy permissions and ensure running as Administrator" -ForegroundColor Yellow
    Write-Host "- Verify Group Policy permissions and connectivity" -ForegroundColor Yellow
    exit 1
}

# Log remediation execution
Write-CISRemediationLog -CisId $CisId -Success $OverallSuccess -Results $RemediationResults