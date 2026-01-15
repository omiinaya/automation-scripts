<#
.SYNOPSIS
    CIS Audit Script for 2.3.1.1 - Ensure 'Accounts: Guest account status' is set to 'Disabled'
.DESCRIPTION
    This script audits the Guest account status to ensure it is disabled as recommended by CIS benchmarks.
    The Guest account allows unauthenticated network users to gain access to the system and should be disabled.
.NOTES
    File Name      : 2.3.1.1-audit-guest-account-status.ps1
    CIS ID         : 2.3.1.1
    CIS Title      : Ensure 'Accounts: Guest account status' is set to 'Disabled'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit Guest account status
function Audit-GuestAccountStatus {
    <#
    .SYNOPSIS
        Audits the Guest account status
    .DESCRIPTION
        Checks if the Guest account is disabled as recommended by CIS benchmarks
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.1.1 - Guest Account Status ===" -ForegroundColor Cyan
        Write-Host "Checking Guest account status..." -ForegroundColor White
        
        # Get Guest account status using PowerShell
        $guestAccount = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
        
        if ($guestAccount) {
            $currentStatus = if ($guestAccount.Enabled) { "Enabled" } else { "Disabled" }
            $details = "Guest account found with status: $currentStatus"
            
            Write-Host "Current Guest account status: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Disabled" -ForegroundColor White
            
            # Check compliance
            $isCompliant = ($currentStatus -eq "Disabled")
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.1.1" -Title "Ensure 'Accounts: Guest account status' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled" -ComplianceStatus $complianceStatus -Source "Local User Account" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Guest account not found (which means it's effectively disabled)
            Write-Host "Guest account not found (effectively disabled)" -ForegroundColor White
            Write-Host "Recommended: Disabled" -ForegroundColor White
            Write-Host "Compliance: Compliant" -ForegroundColor Green
            
            $result = New-CISResultObject -CIS_ID "2.3.1.1" -Title "Ensure 'Accounts: Guest account status' is set to 'Disabled'" -CurrentValue "Disabled" -RecommendedValue "Disabled" -ComplianceStatus "Compliant" -Source "Local User Account" -Details "Guest account not found (effectively disabled)" -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit Guest account status: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.1.1" -Title "Ensure 'Accounts: Guest account status' is set to 'Disabled'" -CurrentValue "Error" -RecommendedValue "Disabled" -ComplianceStatus "Error" -Source "Local User Account" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting for Guest account status
function Test-GuestAccountGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for Guest account status
    .DESCRIPTION
        Verifies if Group Policy is configured to disable the Guest account
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path for Guest account status
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "EnableGuestAccount"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for Guest account status"
                $isCompliant = $false
            } else {
                $policyStatus = if ($policyValue -eq 0) { "Disabled" } else { "Enabled" }
                Write-Host "Group Policy setting: $policyStatus" -ForegroundColor White
                $details = "Group Policy setting: $policyStatus"
                $isCompliant = ($policyValue -eq 0)
            }
            
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            Write-Host "Group Policy Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            return [PSCustomObject]@{
                PolicyValue = $policyValue
                PolicyStatus = $policyStatus
                IsCompliant = $isCompliant
                Details = $details
            }
        } else {
            Write-Host "Group Policy registry path not found" -ForegroundColor Yellow
            return [PSCustomObject]@{
                PolicyValue = "Not Found"
                PolicyStatus = "Unknown"
                IsCompliant = $false
                Details = "Group Policy registry path not found"
            }
        }
    }
    catch {
        Write-Warning "Failed to check Group Policy setting: $_"
        return [PSCustomObject]@{
            PolicyValue = "Error"
            PolicyStatus = "Error"
            IsCompliant = $false
            Details = "Error checking Group Policy: $_"
        }
    }
}

# Main audit execution
function Invoke-GuestAccountAudit {
    <#
    .SYNOPSIS
        Main function to execute Guest account audit
    .DESCRIPTION
        Performs comprehensive audit of Guest account status
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.1.1 - Guest Account Status ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Accounts: Guest account status' is set to 'Disabled'" -ForegroundColor White
        Write-Host "Rationale: The Guest account allows unauthenticated network users to gain access to the system." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-GuestAccountStatus
        
        # Check Group Policy setting
        $groupPolicyResult = Test-GuestAccountGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to disable Guest account." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to disable Guest account." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Guest account audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.1.1" -Title "Ensure 'Accounts: Guest account status' is set to 'Disabled'" -CurrentValue "Error" -RecommendedValue "Disabled" -ComplianceStatus "Error" -Source "Local User Account" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-GuestAccountAudit
        
        # Output summary
        Write-Host ""
        Write-Host "=== Audit Summary ===" -ForegroundColor Cyan
        Write-Host "CIS ID: $($auditResult.CIS_ID)" -ForegroundColor White
        Write-Host "Setting: $($auditResult.Title)" -ForegroundColor White
        Write-Host "Current Value: $($auditResult.CurrentValue)" -ForegroundColor White
        Write-Host "Recommended Value: $($auditResult.RecommendedValue)" -ForegroundColor White
        Write-Host "Compliance Status: $($auditResult.ComplianceStatus)" -ForegroundColor $(if ($auditResult.IsCompliant) { "Green" } else { "Red" })
        Write-Host "Source: $($auditResult.Source)" -ForegroundColor White
        
        if ($auditResult.Details) {
            Write-Host "Details: $($auditResult.Details)" -ForegroundColor Gray
        }
        
        # Exit with appropriate code
        if ($auditResult.IsCompliant) {
            exit 0
        } else {
            exit 1
        }
    }
    catch {
        Write-Error "Script execution failed: $_"
        exit 2
    }
}

# Export functions
Export-ModuleMember -Function Audit-GuestAccountStatus, Test-GuestAccountGroupPolicy, Invoke-GuestAccountAudit