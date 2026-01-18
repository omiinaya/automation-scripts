<#
.SYNOPSIS
    CIS Audit Script for 2.3.8.2 - Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'
.DESCRIPTION
    This script audits the setting that determines whether the SMB client will attempt to negotiate SMB packet signing.
    When enabled, the SMB client will negotiate packet signing with servers that support it, providing mutual authentication
    and preventing session hijacking attacks and man-in-the-middle attacks.
.NOTES
    File Name      : 2.3.8.2-audit-microsoft-network-client-digitally-sign-communications-if-server-agrees.ps1
    CIS ID         : 2.3.8.2
    CIS Title      : Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit Microsoft network client digitally sign communications (if server agrees)
function Audit-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgrees {
    <#
    .SYNOPSIS
        Audits the Microsoft network client digitally sign communications (if server agrees) setting
    .DESCRIPTION
        Checks if SMB packet signing is negotiated when server agrees as recommended by CIS benchmarks
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.8.2 - Microsoft Network Client: Digitally Sign Communications (If Server Agrees) ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
        $valueName = "EnableSecuritySignature"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "Enabled" according to JSON
                $currentStatus = "Enabled"
                $details = "Registry value not set (defaults to 'Enabled' - SMB packet signing is negotiated when server agrees)"
                $isCompliant = $true
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
            $result = New-CISResultObject -CIS_ID "2.3.8.2" -Title "Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled (1)" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Enabled (1)" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist is "Enabled" according to JSON
            $currentStatus = "Enabled"
            $details = "Registry key not found (defaults to 'Enabled' - SMB packet signing is negotiated when server agrees)"
            $isCompliant = $true
            
            Write-Host "Compliance: Compliant" -ForegroundColor Green
            
            $result = New-CISResultObject -CIS_ID "2.3.8.2" -Title "Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled (1)" -ComplianceStatus "Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit Microsoft network client digitally sign communications (if server agrees) setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.8.2" -Title "Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'" -CurrentValue "Error" -RecommendedValue "Enabled (1)" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for Microsoft network client digitally sign communications (if server agrees)
    .DESCRIPTION
        Verifies if Group Policy is configured to negotiate SMB packet signing when server agrees
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
        $valueName = "EnableSecuritySignature"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for Microsoft network client digitally sign communications (if server agrees)"
                $isCompliant = $true  # Default is Enabled, so not configured is compliant
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
                IsCompliant = $true  # Default is Enabled, so not found is compliant
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
function Invoke-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesAudit {
    <#
    .SYNOPSIS
        Main function to execute Microsoft network client digitally sign communications (if server agrees) audit
    .DESCRIPTION
        Performs comprehensive audit of the Microsoft network client digitally sign communications (if server agrees) setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.8.2 - Microsoft Network Client: Digitally Sign Communications (If Server Agrees) ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'" -ForegroundColor White
        Write-Host "Rationale: Session hijacking uses tools that allow attackers who have access to the same network" -ForegroundColor Gray
        Write-Host "as the client or server to interrupt, end, or steal a session in progress. Attackers can" -ForegroundColor Gray
        Write-Host "potentially intercept and modify unsigned SMB packets and then modify the traffic and" -ForegroundColor Gray
        Write-Host "forward it so that the server might perform undesirable actions. Alternatively, the" -ForegroundColor Gray
        Write-Host "attacker could pose as the server or client after legitimate authentication and gain" -ForegroundColor Gray
        Write-Host "unauthorized access to data." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgrees
        
        # Check Group Policy setting
        $groupPolicyResult = Test-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to negotiate SMB packet signing when server agrees." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to negotiate SMB packet signing when server agrees." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Microsoft network client digitally sign communications (if server agrees) audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.8.2" -Title "Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'" -CurrentValue "Error" -RecommendedValue "Enabled (1)" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesAudit
        
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
Export-ModuleMember -Function Audit-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgrees, Test-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesGroupPolicy, Invoke-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesAudit