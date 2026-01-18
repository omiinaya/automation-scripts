<#
.SYNOPSIS
    CIS Audit Script for 2.3.7.4 - Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'
.DESCRIPTION
    This script audits the setting that determines the machine inactivity limit before automatic lockout.
    This setting specifies the amount of time a machine can be inactive before requiring re-authentication.
.NOTES
    File Name      : 2.3.7.4-audit-interactive-logon-machine-inactivity-limit.ps1
    CIS ID         : 2.3.7.4
    CIS Title      : Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit machine inactivity limit
function Audit-InteractiveLogonMachineInactivityLimit {
    <#
    .SYNOPSIS
        Audits the machine inactivity limit setting
    .DESCRIPTION
        Checks if the machine inactivity limit is set to 900 or fewer seconds, but not 0
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.7.4 - Interactive Logon: Machine Inactivity Limit ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "InactivityTimeoutSec"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default value is 0 (no inactivity limit)
                $currentStatus = "0"
                $details = "Registry value not set (defaults to 0 - no inactivity limit)"
                $isCompliant = $false
            } else {
                $currentStatus = $currentValue.ToString()
                $details = "Registry value: $currentStatus seconds"
                
                # Check compliance: value must be 900 or fewer seconds, but not 0
                $isCompliant = ($currentValue -le 900 -and $currentValue -ne 0)
            }
            
            Write-Host "Current inactivity limit: $currentStatus seconds" -ForegroundColor White
            Write-Host "Recommended: 900 or fewer seconds, but not 0" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.7.4" -Title "Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'" -CurrentValue $currentStatus -RecommendedValue "900 or fewer seconds, but not 0" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: 900 or fewer seconds, but not 0" -ForegroundColor White
            
            # Default value is 0 (no inactivity limit)
            $currentStatus = "0"
            $details = "Registry key not found (defaults to 0 - no inactivity limit)"
            $isCompliant = $false
            
            Write-Host "Compliance: $(if ($isCompliant) { 'Compliant' } else { 'Non-Compliant' })" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            $result = New-CISResultObject -CIS_ID "2.3.7.4" -Title "Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'" -CurrentValue $currentStatus -RecommendedValue "900 or fewer seconds, but not 0" -ComplianceStatus $(if ($isCompliant) { "Compliant" } else { "Non-Compliant" }) -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit machine inactivity limit setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.7.4" -Title "Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'" -CurrentValue "Error" -RecommendedValue "900 or fewer seconds, but not 0" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-InteractiveLogonMachineInactivityLimitGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for machine inactivity limit
    .DESCRIPTION
        Verifies if Group Policy is configured to set machine inactivity limit to 900 or fewer seconds, but not 0
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        $valueName = "InactivityTimeoutSec"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for machine inactivity limit"
                $isCompliant = $false
            } else {
                $policyStatus = $policyValue.ToString()
                Write-Host "Group Policy inactivity limit: $policyStatus seconds" -ForegroundColor White
                $details = "Group Policy setting: $policyStatus seconds"
                
                # Check compliance: value must be 900 or fewer seconds, but not 0
                $isCompliant = ($policyValue -le 900 -and $policyValue -ne 0)
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
function Invoke-InteractiveLogonMachineInactivityLimitAudit {
    <#
    .SYNOPSIS
        Main function to execute machine inactivity limit audit
    .DESCRIPTION
        Performs comprehensive audit of the machine inactivity limit setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.7.4 - Interactive Logon: Machine Inactivity Limit ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'" -ForegroundColor White
        Write-Host "Rationale: This setting determines how long a machine can be inactive before requiring re-authentication." -ForegroundColor Gray
        Write-Host "Setting an appropriate inactivity limit helps prevent unauthorized access to unattended machines." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-InteractiveLogonMachineInactivityLimit
        
        # Check Group Policy setting
        $groupPolicyResult = Test-InteractiveLogonMachineInactivityLimitGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured for machine inactivity limit." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured for machine inactivity limit." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Machine inactivity limit audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.7.4" -Title "Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'" -CurrentValue "Error" -RecommendedValue "900 or fewer seconds, but not 0" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-InteractiveLogonMachineInactivityLimitAudit
        
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
Export-ModuleMember -Function Audit-InteractiveLogonMachineInactivityLimit, Test-InteractiveLogonMachineInactivityLimitGroupPolicy, Invoke-InteractiveLogonMachineInactivityLimitAudit