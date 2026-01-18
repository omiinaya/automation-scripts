<#
.SYNOPSIS
    CIS Audit Script for 2.3.7.8 - Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher
.DESCRIPTION
    This script audits the setting that determines what happens when the smart card for a logged-on user is removed from the smart card reader.
    When configured to 'Lock Workstation' or higher, the workstation automatically locks when the smart card is removed,
    ensuring that only the user with the smart card can access resources using those credentials.
.NOTES
    File Name      : 2.3.7.8-audit-interactive-logon-smart-card-removal-behavior.ps1
    CIS ID         : 2.3.7.8
    CIS Title      : Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit smart card removal behavior
function Audit-SmartCardRemovalBehavior {
    <#
    .SYNOPSIS
        Audits the smart card removal behavior setting
    .DESCRIPTION
        Checks if smart card removal behavior is configured to 'Lock Workstation' or higher as recommended by CIS benchmarks
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.7.8 - Interactive Logon: Smart Card Removal Behavior ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $valueName = "ScRemoveOption"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "No action"
                $currentStatus = "No action"
                $details = "Registry value not set (defaults to 'No action')"
                $isCompliant = $false
            } else {
                # Map numeric values to their meanings
                switch ($currentValue) {
                    0 { $currentStatus = "No action" }
                    1 { $currentStatus = "Lock Workstation" }
                    2 { $currentStatus = "Force Logoff" }
                    3 { $currentStatus = "Disconnect if a Remote Desktop Services session" }
                    default { $currentStatus = "Unknown ($currentValue)" }
                }
                
                $details = "Registry value: $currentValue ($currentStatus)"
                
                # Check compliance: values 1, 2, or 3 are compliant (Lock Workstation or higher)
                $isCompliant = ($currentValue -eq 1 -or $currentValue -eq 2 -or $currentValue -eq 3)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Lock Workstation or higher (1, 2, or 3)" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.7.8" -Title "Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher" -CurrentValue $currentStatus -RecommendedValue "Lock Workstation or higher (1, 2, or 3)" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Lock Workstation or higher (1, 2, or 3)" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist
            $currentStatus = "No action"
            $details = "Registry key not found (defaults to 'No action')"
            $isCompliant = $false
            
            Write-Host "Compliance: Non-Compliant" -ForegroundColor Red
            
            $result = New-CISResultObject -CIS_ID "2.3.7.8" -Title "Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher" -CurrentValue $currentStatus -RecommendedValue "Lock Workstation or higher (1, 2, or 3)" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit smart card removal behavior setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.7.8" -Title "Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher" -CurrentValue "Error" -RecommendedValue "Lock Workstation or higher (1, 2, or 3)" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-SmartCardRemovalBehaviorGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for smart card removal behavior
    .DESCRIPTION
        Verifies if Group Policy is configured for smart card removal behavior
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        $valueName = "ScRemoveOption"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for smart card removal behavior"
                $isCompliant = $false
            } else {
                # Map numeric values to their meanings
                switch ($policyValue) {
                    0 { $policyStatus = "No action" }
                    1 { $policyStatus = "Lock Workstation" }
                    2 { $policyStatus = "Force Logoff" }
                    3 { $policyStatus = "Disconnect if a Remote Desktop Services session" }
                    default { $policyStatus = "Unknown ($policyValue)" }
                }
                
                Write-Host "Group Policy setting: $policyStatus" -ForegroundColor White
                $details = "Group Policy setting: $policyStatus"
                
                # Check compliance: values 1, 2, or 3 are compliant
                $isCompliant = ($policyValue -eq 1 -or $policyValue -eq 2 -or $policyValue -eq 3)
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
function Invoke-SmartCardRemovalBehaviorAudit {
    <#
    .SYNOPSIS
        Main function to execute smart card removal behavior audit
    .DESCRIPTION
        Performs comprehensive audit of the smart card removal behavior setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.7.8 - Interactive Logon: Smart Card Removal Behavior ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher" -ForegroundColor White
        Write-Host "Rationale: Users sometimes forget to lock their workstations when they are away from them," -ForegroundColor Gray
        Write-Host "allowing the possibility for malicious users to access their computers. If smart cards are" -ForegroundColor Gray
        Write-Host "used for authentication, the computer should automatically lock itself when the card is" -ForegroundColor Gray
        Write-Host "removed to ensure that only the user with the smart card is accessing resources using those credentials." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-SmartCardRemovalBehavior
        
        # Check Group Policy setting
        $groupPolicyResult = Test-SmartCardRemovalBehaviorGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured for smart card removal behavior." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured for smart card removal behavior." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Smart card removal behavior audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.7.8" -Title "Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher" -CurrentValue "Error" -RecommendedValue "Lock Workstation or higher (1, 2, or 3)" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-SmartCardRemovalBehaviorAudit
        
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
Export-ModuleMember -Function Audit-SmartCardRemovalBehavior, Test-SmartCardRemovalBehaviorGroupPolicy, Invoke-SmartCardRemovalBehaviorAudit