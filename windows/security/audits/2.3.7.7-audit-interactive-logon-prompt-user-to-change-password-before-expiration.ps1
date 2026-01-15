<#
.SYNOPSIS
    CIS Audit Script for 2.3.7.7 - Ensure 'Interactive logon: Prompt user to change password before expiration' is set to 'between 5 and 14 days'
.DESCRIPTION
    This script audits the setting that determines how far in advance users are warned that their password will expire.
    The recommended configuration is to warn users between 5 and 14 days before password expiration to prevent
    inadvertent lockouts and ensure users have sufficient time to change their passwords.
.NOTES
    File Name      : 2.3.7.7-audit-interactive-logon-prompt-user-to-change-password-before-expiration.ps1
    CIS ID         : 2.3.7.7
    CIS Title      : Ensure 'Interactive logon: Prompt user to change password before expiration' is set to 'between 5 and 14 days'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit interactive logon password expiration warning
function Audit-InteractiveLogonPasswordExpiryWarning {
    <#
    .SYNOPSIS
        Audits the interactive logon password expiration warning setting
    .DESCRIPTION
        Checks how many days in advance users are warned about password expiration as recommended by CIS benchmarks
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.7.7 - Interactive Logon: Prompt User to Change Password Before Expiration ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $valueName = "PasswordExpiryWarning"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default value is 5 days when not set
                $currentDays = 5
                $details = "Registry value not set (defaults to 5 days)"
                $isCompliant = $true  # 5 days is within the 5-14 day range
            } else {
                $currentDays = [int]$currentValue
                $details = "Registry value: $currentDays days"
                
                # Check if value is between 5 and 14 (inclusive)
                $isCompliant = ($currentDays -ge 5 -and $currentDays -le 14)
            }
            
            Write-Host "Current setting: $currentDays days" -ForegroundColor White
            Write-Host "Recommended: Between 5 and 14 days" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.7.7" -Title "Ensure 'Interactive logon: Prompt user to change password before expiration' is set to 'between 5 and 14 days'" -CurrentValue "$currentDays days" -RecommendedValue "Between 5 and 14 days" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Between 5 and 14 days" -ForegroundColor White
            
            # Default value is 5 days when key doesn't exist
            $currentDays = 5
            $details = "Registry key not found (defaults to 5 days)"
            $isCompliant = $true  # 5 days is within the 5-14 day range
            
            Write-Host "Compliance: $(if ($isCompliant) { 'Compliant' } else { 'Non-Compliant' })" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            $result = New-CISResultObject -CIS_ID "2.3.7.7" -Title "Ensure 'Interactive logon: Prompt user to change password before expiration' is set to 'between 5 and 14 days'" -CurrentValue "$currentDays days" -RecommendedValue "Between 5 and 14 days" -ComplianceStatus $(if ($isCompliant) { "Compliant" } else { "Non-Compliant" }) -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit interactive logon password expiration warning setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.7.7" -Title "Ensure 'Interactive logon: Prompt user to change password before expiration' is set to 'between 5 and 14 days'" -CurrentValue "Error" -RecommendedValue "Between 5 and 14 days" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-InteractiveLogonPasswordExpiryWarningGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for interactive logon password expiration warning
    .DESCRIPTION
        Verifies if Group Policy is configured to warn users about password expiration between 5 and 14 days in advance
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $valueName = "PasswordExpiryWarning"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for interactive logon password expiration warning"
                $isCompliant = $false
            } else {
                $policyDays = [int]$policyValue
                Write-Host "Group Policy setting: $policyDays days" -ForegroundColor White
                $details = "Group Policy setting: $policyDays days"
                
                # Check if value is between 5 and 14 (inclusive)
                $isCompliant = ($policyDays -ge 5 -and $policyDays -le 14)
            }
            
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            Write-Host "Group Policy Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            return [PSCustomObject]@{
                PolicyValue = $policyValue
                PolicyDays = if ($policyValue -eq "Not Configured") { "Not Configured" } else { [int]$policyValue }
                IsCompliant = $isCompliant
                Details = $details
            }
        } else {
            Write-Host "Group Policy registry path not found" -ForegroundColor Yellow
            return [PSCustomObject]@{
                PolicyValue = "Not Found"
                PolicyDays = "Unknown"
                IsCompliant = $false
                Details = "Group Policy registry path not found"
            }
        }
    }
    catch {
        Write-Warning "Failed to check Group Policy setting: $_"
        return [PSCustomObject]@{
            PolicyValue = "Error"
            PolicyDays = "Error"
            IsCompliant = $false
            Details = "Error checking Group Policy: $_"
        }
    }
}

# Main audit execution
function Invoke-InteractiveLogonPasswordExpiryWarningAudit {
    <#
    .SYNOPSIS
        Main function to execute interactive logon password expiration warning audit
    .DESCRIPTION
        Performs comprehensive audit of the interactive logon password expiration warning setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.7.7 - Interactive Logon: Prompt User to Change Password Before Expiration ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Interactive logon: Prompt user to change password before expiration' is set to 'between 5 and 14 days'" -ForegroundColor White
        Write-Host "Rationale: Users need to be warned that their passwords are going to expire, or they may inadvertently" -ForegroundColor Gray
        Write-Host "be locked out of the computer when their passwords expire. This condition could lead to confusion" -ForegroundColor Gray
        Write-Host "for users who access the network locally, or make it impossible for users to access your" -ForegroundColor Gray
        Write-Host "organization's network through dial-up or virtual private network (VPN) connections." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-InteractiveLogonPasswordExpiryWarning
        
        # Check Group Policy setting
        $groupPolicyResult = Test-InteractiveLogonPasswordExpiryWarningGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to warn users about password expiration between 5 and 14 days in advance." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to warn users about password expiration between 5 and 14 days in advance." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Interactive logon password expiration warning audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.7.7" -Title "Ensure 'Interactive logon: Prompt user to change password before expiration' is set to 'between 5 and 14 days'" -CurrentValue "Error" -RecommendedValue "Between 5 and 14 days" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-InteractiveLogonPasswordExpiryWarningAudit
        
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
Export-ModuleMember -Function Audit-InteractiveLogonPasswordExpiryWarning, Test-InteractiveLogonPasswordExpiryWarningGroupPolicy, Invoke-InteractiveLogonPasswordExpiryWarningAudit