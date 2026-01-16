<#
.SYNOPSIS
    CIS Audit Script for 2.3.2.2 - Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'
.DESCRIPTION
    This script audits the system shutdown behavior when unable to log security audits.
    When enabled, the system will shut down immediately if it cannot log security events,
    which could lead to unplanned system failures and potential data corruption.
.NOTES
    File Name      : 2.3.2.2-audit-shutdown-system-immediately-if-unable-to-log-security-audits.ps1
    CIS ID         : 2.3.2.2
    CIS Title      : Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit shutdown system immediately if unable to log security audits
function Audit-ShutdownSystemImmediatelyIfUnableToLogSecurityAudits {
    <#
    .SYNOPSIS
        Audits the shutdown system immediately if unable to log security audits setting
    .DESCRIPTION
        Checks if the system is configured to shut down immediately when unable to log security audits
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.2.2 - Shutdown System Immediately If Unable To Log Security Audits ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $valueName = "CrashOnAuditFail"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is Disabled (0)
                $currentStatus = "Disabled"
                $details = "Registry value not set (defaults to Disabled)"
                $isCompliant = $true
            } else {
                $currentStatus = if ($currentValue -eq 0) { "Disabled" } else { "Enabled" }
                $details = "Registry value: $currentValue ($currentStatus)"
                $isCompliant = ($currentValue -eq 0)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Disabled" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.2.2" -Title "Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Disabled" -ForegroundColor White
            Write-Host "Compliance: Compliant (key not found, defaults to Disabled)" -ForegroundColor Green
            
            $result = New-CISResultObject -CIS_ID "2.3.2.2" -Title "Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'" -CurrentValue "Disabled" -RecommendedValue "Disabled" -ComplianceStatus "Compliant" -Source "Registry" -Details "Registry key not found (defaults to Disabled)" -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit shutdown system immediately if unable to log security audits setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.2.2" -Title "Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'" -CurrentValue "Error" -RecommendedValue "Disabled" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-ShutdownSystemImmediatelyGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for shutdown system immediately if unable to log security audits
    .DESCRIPTION
        Verifies if Group Policy is configured to disable the shutdown system immediately setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog"
        $valueName = "CrashOnAuditFail"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for shutdown system immediately if unable to log security audits"
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
function Invoke-ShutdownSystemImmediatelyAudit {
    <#
    .SYNOPSIS
        Main function to execute shutdown system immediately if unable to log security audits audit
    .DESCRIPTION
        Performs comprehensive audit of the shutdown system immediately setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.2.2 - Shutdown System Immediately If Unable To Log Security Audits ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'" -ForegroundColor White
        Write-Host "Rationale: If enabled, the system will shut down immediately when unable to log security events," -ForegroundColor Gray
        Write-Host "which could lead to unplanned system failures and potential data corruption." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-ShutdownSystemImmediatelyIfUnableToLogSecurityAudits
        
        # Check Group Policy setting
        $groupPolicyResult = Test-ShutdownSystemImmediatelyGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to disable shutdown system immediately if unable to log security audits." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to disable shutdown system immediately if unable to log security audits." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Shutdown system immediately audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.2.2" -Title "Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'" -CurrentValue "Error" -RecommendedValue "Disabled" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-ShutdownSystemImmediatelyAudit
        
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
Export-ModuleMember -Function Audit-ShutdownSystemImmediatelyIfUnableToLogSecurityAudits, Test-ShutdownSystemImmediatelyGroupPolicy, Invoke-ShutdownSystemImmediatelyAudit