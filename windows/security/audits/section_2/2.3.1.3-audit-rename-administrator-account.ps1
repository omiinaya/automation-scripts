# CIS Audit Script for 2.3.1.3: Accounts: Rename administrator account
# Configure 'Accounts: Rename administrator account'

<#
.SYNOPSIS
    CIS Audit Script for 2.3.1.3 - Accounts: Rename administrator account

.DESCRIPTION
    This script audits the compliance status of CIS control 2.3.1.3 which ensures
    that the built-in Administrator account is renamed to something other than
    the default "Administrator" name.

.PARAMETER None
    This script does not accept any parameters.

.EXAMPLE
    .\2.3.1.3-audit-rename-administrator-account.ps1

.NOTES
    CIS ID: 2.3.1.3
    Profile: L1
    Group Policy Path: Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\Accounts: Rename administrator account
    Expected Value: Any value other than "Administrator"
    Default Value: Administrator
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Import required modules
Import-Module $PSScriptRoot\..\..\modules\CISFramework.psm1 -ErrorAction Stop

# CIS Control Information
$CisId = "2.3.1.3"
$CisTitle = "Configure 'Accounts: Rename administrator account'"
$CisProfile = "L1"

# Group Policy configuration
$GroupPolicyPath = "Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\Accounts: Rename administrator account"
$ExpectedGpoValue = "Any value other than Administrator"

# Initialize compliance tracking
$ComplianceResults = @()
$OverallCompliant = $true

# Display script header
Write-CISScriptHeader -CisId $CisId -Title $CisTitle -Profile $CisProfile

# Check security policy setting using secedit
Write-Host "Checking Security Policy Setting..." -ForegroundColor Cyan

try {
    # Export current security policy
    $tempFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $tempFile /quiet
    
    # Read the exported policy
    $policyContent = Get-Content $tempFile
    
    # Look for the NewAdministratorName setting
    $adminNameLine = $policyContent | Where-Object { $_ -like "NewAdministratorName*" }
    
    if ($adminNameLine) {
        $adminNameValue = ($adminNameLine -split "=")[1].Trim()
        $source = "Local Policy"
        
        # Check if the value is not "Administrator"
        if ($adminNameValue -ne "Administrator" -and -not [string]::IsNullOrWhiteSpace($adminNameValue)) {
            $currentValue = $adminNameValue
            $isCompliant = $true
        } else {
            $currentValue = "Administrator"
            $isCompliant = $false
        }
    } else {
        $currentValue = "Administrator"
        $source = "Local Default"
        $isCompliant = $false
    }
    
    # Clean up temp file
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    
    $result = @{
        Description = "Administrator account name"
        CurrentValue = $currentValue
        ExpectedValue = "Any value other than Administrator"
        Source = $source
        Compliant = $isCompliant
    }
    
    $ComplianceResults += $result
    
    if (-not $isCompliant) {
        $OverallCompliant = $false
    }
    
} catch {
    Write-Host "ERROR: Failed to check security policy setting" -ForegroundColor Red
    Write-Host "Exception: $($_.Exception.Message)" -ForegroundColor Red
    
    $result = @{
        Description = "Administrator account name"
        CurrentValue = "Unknown (Error)"
        ExpectedValue = "Any value other than Administrator"
        Source = "Error"
        Compliant = $false
    }
    
    $ComplianceResults += $result
    $OverallCompliant = $false
}

# Check Group Policy setting (if available)
Write-Host "Checking Group Policy Setting..." -ForegroundColor Cyan

try {
    $gpoResult = Test-GroupPolicySetting -PolicyPath $GroupPolicyPath -ExpectedValue $ExpectedGpoValue
    $ComplianceResults += $gpoResult
    
    if (-not $gpoResult.Compliant) {
        $OverallCompliant = $false
    }
} catch {
    Write-Host "WARNING: Could not check Group Policy setting" -ForegroundColor Yellow
    Write-Host "Exception: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Display compliance summary
Write-Host ""
Write-Host "Compliance Summary:" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow

foreach ($result in $ComplianceResults) {
    $status = if ($result.Compliant) { "COMPLIANT" } else { "NON-COMPLIANT" }
    $color = if ($result.Compliant) { "Green" } else { "Red" }
    
    Write-Host "$($result.Description): $status" -ForegroundColor $color
    Write-Host "  Current Value: $($result.CurrentValue)" -ForegroundColor White
    Write-Host "  Expected Value: $($result.ExpectedValue)" -ForegroundColor White
    Write-Host "  Source: $($result.Source)" -ForegroundColor Gray
}

# Final compliance determination
Write-Host ""
if ($OverallCompliant) {
    Write-Host "OVERALL STATUS: COMPLIANT" -ForegroundColor Green
    Write-Host "The Administrator account has been renamed according to CIS benchmark requirements." -ForegroundColor Green
    exit 0
} else {
    Write-Host "OVERALL STATUS: NON-COMPLIANT" -ForegroundColor Red
    Write-Host "The Administrator account has not been renamed from the default name." -ForegroundColor Red
    Write-Host ""
    Write-Host "Remediation Required:" -ForegroundColor Yellow
    Write-Host "- Rename the Administrator account to something other than 'Administrator'" -ForegroundColor Yellow
    Write-Host "- Configure the Group Policy setting: $GroupPolicyPath" -ForegroundColor Yellow
    exit 1
}

# Log script execution
Write-CISExecutionLog -CisId $CisId -Compliant $OverallCompliant -Results $ComplianceResults