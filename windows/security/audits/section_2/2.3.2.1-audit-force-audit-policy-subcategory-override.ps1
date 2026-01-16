<#
.SYNOPSIS
    CIS Audit Script for 2.3.2.1 - Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'
.DESCRIPTION
    This script audits the Security Options setting that forces audit policy subcategory settings to override audit policy category settings.
    This allows administrators to enable the more precise auditing capabilities present in Windows Vista and later versions.
.NOTES
    File Name      : 2.3.2.1-audit-force-audit-policy-subcategory-override.ps1
    CIS ID         : 2.3.2.1
    CIS Title      : Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit audit policy subcategory override setting
function Audit-ForceAuditPolicySubcategoryOverride {
    <#
    .SYNOPSIS
        Audits the audit policy subcategory override setting
    .DESCRIPTION
        Checks if the Security Options setting that forces audit policy subcategory settings 
        to override audit policy category settings is properly configured
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.2.1 - Force Audit Policy Subcategory Override ===" -ForegroundColor Cyan
        Write-Host "Checking Security Options setting..." -ForegroundColor White
        
        # Registry path for Security Options setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $valueName = "SCENoApplyLegacyAuditPolicy"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            # Get current value
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            # Convert numeric value to readable status
            $currentStatus = if ($currentValue -eq "Not Set") { "Not Configured" } 
                            elseif ($currentValue -eq 1) { "Enabled" } 
                            elseif ($currentValue -eq 0) { "Disabled" } 
                            else { "Unknown ($currentValue)" }
            
            Write-Host "Current setting status: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Enabled" -ForegroundColor White
            
            # Check compliance
            $isCompliant = ($currentValue -eq 1)
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.2.1" -Title "Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled" -ComplianceStatus $complianceStatus -Source "Security Options" -Details "Registry path: $registryPath" -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Security Options registry path not found" -ForegroundColor Yellow
            Write-Host "Recommended: Enabled" -ForegroundColor White
            Write-Host "Compliance: Non-Compliant" -ForegroundColor Red
            
            $result = New-CISResultObject -CIS_ID "2.3.2.1" -Title "Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'" -CurrentValue "Not Configured" -RecommendedValue "Enabled" -ComplianceStatus "Non-Compliant" -Source "Security Options" -Details "Registry path not found: $registryPath" -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit audit policy subcategory override setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.2.1" -Title "Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'" -CurrentValue "Error" -RecommendedValue "Enabled" -ComplianceStatus "Error" -Source "Security Options" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-AuditPolicySubcategoryGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for audit policy subcategory override
    .DESCRIPTION
        Verifies if Group Policy is configured to force audit policy subcategory settings to override audit policy category settings
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Audit"
        $valueName = "SCENoApplyLegacyAuditPolicy"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for audit policy subcategory override"
                $isCompliant = $false
            } else {
                $policyStatus = if ($policyValue -eq 1) { "Enabled" } else { "Disabled" }
                Write-Host "Group Policy setting: $policyStatus" -ForegroundColor White
                $details = "Group Policy setting: $policyStatus"
                $isCompliant = ($policyValue -eq 1)
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
function Invoke-AuditPolicySubcategoryAudit {
    <#
    .SYNOPSIS
        Main function to execute audit policy subcategory override audit
    .DESCRIPTION
        Performs comprehensive audit of the Security Options setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.2.1 - Force Audit Policy Subcategory Override ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'" -ForegroundColor White
        Write-Host "Rationale: This setting allows administrators to enable the more precise auditing capabilities present in Windows Vista and later versions." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-ForceAuditPolicySubcategoryOverride
        
        # Check Group Policy setting
        $groupPolicyResult = Test-AuditPolicySubcategoryGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to force audit policy subcategory override." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to force audit policy subcategory override." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Audit policy subcategory override audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.2.1" -Title "Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'" -CurrentValue "Error" -RecommendedValue "Enabled" -ComplianceStatus "Error" -Source "Security Options" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-AuditPolicySubcategoryAudit
        
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
Export-ModuleMember -Function Audit-ForceAuditPolicySubcategoryOverride, Test-AuditPolicySubcategoryGroupPolicy, Invoke-AuditPolicySubcategoryAudit