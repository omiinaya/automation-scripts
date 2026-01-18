<#
.SYNOPSIS
    CIS Audit Script for 2.3.8.3 - Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'
.DESCRIPTION
    This script audits the setting that determines whether the SMB redirector will send plaintext passwords
    during authentication to third-party SMB servers that do not support password encryption.
    When disabled, unencrypted passwords are not allowed across the network, preventing password interception.
.NOTES
    File Name      : 2.3.8.3-audit-microsoft-network-client-send-unencrypted-password-to-third-party-smb-servers.ps1
    CIS ID         : 2.3.8.3
    CIS Title      : Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit Microsoft network client send unencrypted password to third-party SMB servers
function Audit-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServers {
    <#
    .SYNOPSIS
        Audits the Microsoft network client send unencrypted password to third-party SMB servers setting
    .DESCRIPTION
        Checks if sending unencrypted passwords to third-party SMB servers is disabled as recommended by CIS benchmarks
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.8.3 - Microsoft Network Client: Send Unencrypted Password to Third-Party SMB Servers ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
        $valueName = "EnablePlainTextPassword"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "Disabled" according to JSON
                $currentStatus = "Disabled"
                $details = "Registry value not set (defaults to 'Disabled' - plaintext passwords not sent to third-party SMB servers)"
                $isCompliant = $true
            } else {
                # Map numeric values to their meanings
                switch ($currentValue) {
                    0 { $currentStatus = "Disabled" }
                    1 { $currentStatus = "Enabled" }
                    default { $currentStatus = "Unknown ($currentValue)" }
                }
                
                $details = "Registry value: $currentValue ($currentStatus)"
                
                # Check compliance: value 0 is compliant (Disabled)
                $isCompliant = ($currentValue -eq 0)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Disabled (0)" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.8.3" -Title "Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled (0)" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Disabled (0)" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist is "Disabled" according to JSON
            $currentStatus = "Disabled"
            $details = "Registry key not found (defaults to 'Disabled' - plaintext passwords not sent to third-party SMB servers)"
            $isCompliant = $true
            
            Write-Host "Compliance: Compliant" -ForegroundColor Green
            
            $result = New-CISResultObject -CIS_ID "2.3.8.3" -Title "Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled (0)" -ComplianceStatus "Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit Microsoft network client send unencrypted password to third-party SMB servers setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.8.3" -Title "Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'" -CurrentValue "Error" -RecommendedValue "Disabled (0)" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for Microsoft network client send unencrypted password to third-party SMB servers
    .DESCRIPTION
        Verifies if Group Policy is configured to disable sending unencrypted passwords to third-party SMB servers
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
        $valueName = "EnablePlainTextPassword"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for Microsoft network client send unencrypted password to third-party SMB servers"
                $isCompliant = $true  # Default is Disabled, so not configured is compliant
            } else {
                # Map numeric values to their meanings
                switch ($policyValue) {
                    0 { $policyStatus = "Disabled" }
                    1 { $policyStatus = "Enabled" }
                    default { $policyStatus = "Unknown ($policyValue)" }
                }
                
                Write-Host "Group Policy setting: $policyStatus" -ForegroundColor White
                $details = "Group Policy setting: $policyStatus"
                
                # Check compliance: value 0 is compliant
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
                IsCompliant = $true  # Default is Disabled, so not found is compliant
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
function Invoke-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersAudit {
    <#
    .SYNOPSIS
        Main function to execute Microsoft network client send unencrypted password to third-party SMB servers audit
    .DESCRIPTION
        Performs comprehensive audit of the Microsoft network client send unencrypted password to third-party SMB servers setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.8.3 - Microsoft Network Client: Send Unencrypted Password to Third-Party SMB Servers ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'" -ForegroundColor White
        Write-Host "Rationale: If you enable this policy setting, the server can transmit passwords in plaintext across" -ForegroundColor Gray
        Write-Host "the network to other computers that offer SMB services, which is a significant security" -ForegroundColor Gray
        Write-Host "risk. These other computers may not use any of the SMB security mechanisms that are" -ForegroundColor Gray
        Write-Host "included with Windows Server 2003." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServers
        
        # Check Group Policy setting
        $groupPolicyResult = Test-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to disable sending unencrypted passwords to third-party SMB servers." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to disable sending unencrypted passwords to third-party SMB servers." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Microsoft network client send unencrypted password to third-party SMB servers audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.8.3" -Title "Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'" -CurrentValue "Error" -RecommendedValue "Disabled (0)" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersAudit
        
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
Export-ModuleMember -Function Audit-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServers, Test-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersGroupPolicy, Invoke-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersAudit