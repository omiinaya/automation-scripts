<#
.SYNOPSIS
    CIS Audit Script for 2.3.8.1 - Ensure 'Microsoft network client: Digitally sign communications (always)' is set to 'Enabled'
.DESCRIPTION
    This script audits the setting that determines whether packet signing is required by the SMB client component.
    When enabled, the SMB client will require packet signing for all communications, providing mutual authentication
    and preventing session hijacking attacks and man-in-the-middle attacks.
.NOTES
    File Name      : 2.3.8.1-audit-microsoft-network-client-digitally-sign-communications-always.ps1
    CIS ID         : 2.3.8.1
    CIS Title      : Ensure 'Microsoft network client: Digitally sign communications (always)' is set to 'Enabled'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit Microsoft network client digitally sign communications (always)
function Audit-MicrosoftNetworkClientDigitallySignCommunicationsAlways {
    <#
    .SYNOPSIS
        Audits the Microsoft network client digitally sign communications (always) setting
    .DESCRIPTION
        Checks if SMB packet signing is required for all communications as recommended by CIS benchmarks
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.8.1 - Microsoft Network Client: Digitally Sign Communications (Always) ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
        $valueName = "RequireSecuritySignature"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "Disabled"
                $currentStatus = "Disabled"
                $details = "Registry value not set (defaults to 'Disabled' - SMB packet signing is negotiated)"
                $isCompliant = $false
            } else {
                # Map numeric values to their meanings
                switch ($currentValue) {
                    0 { $currentStatus = "Disabled" }
                    1 { $currentStatus = "Enabled" }
                    default { $currentStatus = "Unknown ($currentValue)" }
                }
                
                $details = "Registry value: $currentValue ($currentStatus)"
                
                # Check compliance: value 1 is compliant (Enabled)
                $isCompliant = ($currentValue -eq 1)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Enabled (1)" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.8.1" -Title "Ensure 'Microsoft network client: Digitally sign communications (always)' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled (1)" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Enabled (1)" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist
            $currentStatus = "Disabled"
            $details = "Registry key not found (defaults to 'Disabled' - SMB packet signing is negotiated)"
            $isCompliant = $false
            
            Write-Host "Compliance: Non-Compliant" -ForegroundColor Red
            
            $result = New-CISResultObject -CIS_ID "2.3.8.1" -Title "Ensure 'Microsoft network client: Digitally sign communications (always)' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled (1)" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit Microsoft network client digitally sign communications (always) setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.8.1" -Title "Ensure 'Microsoft network client: Digitally sign communications (always)' is set to 'Enabled'" -CurrentValue "Error" -RecommendedValue "Enabled (1)" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-MicrosoftNetworkClientDigitallySignCommunicationsAlwaysGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for Microsoft network client digitally sign communications (always)
    .DESCRIPTION
        Verifies if Group Policy is configured to require SMB packet signing for all communications
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
        $valueName = "RequireSecuritySignature"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for Microsoft network client digitally sign communications (always)"
                $isCompliant = $false
            } else {
                # Map numeric values to their meanings
                switch ($policyValue) {
                    0 { $policyStatus = "Disabled" }
                    1 { $policyStatus = "Enabled" }
                    default { $policyStatus = "Unknown ($policyValue)" }
                }
                
                Write-Host "Group Policy setting: $policyStatus" -ForegroundColor White
                $details = "Group Policy setting: $policyStatus"
                
                # Check compliance: value 1 is compliant
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
function Invoke-MicrosoftNetworkClientDigitallySignCommunicationsAlwaysAudit {
    <#
    .SYNOPSIS
        Main function to execute Microsoft network client digitally sign communications (always) audit
    .DESCRIPTION
        Performs comprehensive audit of the Microsoft network client digitally sign communications (always) setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.8.1 - Microsoft Network Client: Digitally Sign Communications (Always) ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Microsoft network client: Digitally sign communications (always)' is set to 'Enabled'" -ForegroundColor White
        Write-Host "Rationale: Session hijacking uses tools that allow attackers who have access to the same network" -ForegroundColor Gray
        Write-Host "as the client or server to interrupt, end, or steal a session in progress. Attackers can" -ForegroundColor Gray
        Write-Host "potentially intercept and modify unsigned SMB packets and then modify the traffic and" -ForegroundColor Gray
        Write-Host "forward it so that the server might perform undesirable actions. Alternatively, the" -ForegroundColor Gray
        Write-Host "attacker could pose as the server or client after legitimate authentication and gain" -ForegroundColor Gray
        Write-Host "unauthorized access to data." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-MicrosoftNetworkClientDigitallySignCommunicationsAlways
        
        # Check Group Policy setting
        $groupPolicyResult = Test-MicrosoftNetworkClientDigitallySignCommunicationsAlwaysGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to require SMB packet signing for all communications." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to require SMB packet signing for all communications." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Microsoft network client digitally sign communications (always) audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.8.1" -Title "Ensure 'Microsoft network client: Digitally sign communications (always)' is set to 'Enabled'" -CurrentValue "Error" -RecommendedValue "Enabled (1)" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-MicrosoftNetworkClientDigitallySignCommunicationsAlwaysAudit
        
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
Export-ModuleMember -Function Audit-MicrosoftNetworkClientDigitallySignCommunicationsAlways, Test-MicrosoftNetworkClientDigitallySignCommunicationsAlwaysGroupPolicy, Invoke-MicrosoftNetworkClientDigitallySignCommunicationsAlwaysAudit