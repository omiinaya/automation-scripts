<#
.SYNOPSIS
    CIS Audit Script for 2.3.9.4 - Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'
.DESCRIPTION
    This script audits the setting that determines whether to disconnect users who are connected to the
    local computer outside their user account's valid logon hours. This setting affects the Server Message
    Block (SMB) component. If enabled, users will be disconnected when their logon hours expire.
.NOTES
    File Name      : 2.3.9.4-audit-microsoft-network-server-disconnect-clients-when-logon-hours-expire.ps1
    CIS ID         : 2.3.9.4
    CIS Title      : Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit Microsoft network server disconnect clients when logon hours expire
function Audit-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpire {
    <#
    .SYNOPSIS
        Audits the Microsoft network server disconnect clients when logon hours expire setting
    .DESCRIPTION
        Checks if the setting to disconnect clients when logon hours expire is enabled as recommended by CIS benchmarks
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.9.4 - Microsoft Network Server: Disconnect Clients When Logon Hours Expire ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "enableforcedlogoff"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "Enabled" according to JSON
                $currentStatus = "Enabled"
                $details = "Registry value not set (defaults to 'Enabled' - clients disconnected when logon hours expire)"
                $isCompliant = $true
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                $currentStatus = if ($currentValueInt -eq 1) { "Enabled" } else { "Disabled" }
                $details = "Registry value: $currentValueInt ($currentStatus)"
                
                # Check compliance: value must be 1 (Enabled)
                $isCompliant = ($currentValueInt -eq 1)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Enabled" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.9.4" -Title "Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Enabled" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist is "Enabled" according to JSON
            $currentStatus = "Enabled"
            $details = "Registry key not found (defaults to 'Enabled' - clients disconnected when logon hours expire)"
            $isCompliant = $true
            
            Write-Host "Compliance: Compliant" -ForegroundColor Green
            
            $result = New-CISResultObject -CIS_ID "2.3.9.4" -Title "Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled" -ComplianceStatus "Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit Microsoft network server disconnect clients when logon hours expire setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.9.4" -Title "Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'" -CurrentValue "Error" -RecommendedValue "Enabled" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for Microsoft network server disconnect clients when logon hours expire
    .DESCRIPTION
        Verifies if Group Policy is configured to enable disconnecting clients when logon hours expire
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanServer"
        $valueName = "enableforcedlogoff"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for Microsoft network server disconnect clients when logon hours expire"
                $isCompliant = $true  # Default is Enabled, so not configured is compliant
            } else {
                # Convert to integer for comparison
                $policyValueInt = [int]$policyValue
                $policyStatus = if ($policyValueInt -eq 1) { "Enabled" } else { "Disabled" }
                
                Write-Host "Group Policy setting: $policyStatus" -ForegroundColor White
                $details = "Group Policy setting: $policyStatus"
                
                # Check compliance: value must be 1 (Enabled)
                $isCompliant = ($policyValueInt -eq 1)
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
function Invoke-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireAudit {
    <#
    .SYNOPSIS
        Main function to execute Microsoft network server disconnect clients when logon hours expire audit
    .DESCRIPTION
        Performs comprehensive audit of the Microsoft network server disconnect clients when logon hours expire setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.9.4 - Microsoft Network Server: Disconnect Clients When Logon Hours Expire ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'" -ForegroundColor White
        Write-Host "Rationale: If your organization configures logon hours for users, then it makes sense to enable this" -ForegroundColor Gray
        Write-Host "policy setting. Otherwise, users who should not have access to network resources" -ForegroundColor Gray
        Write-Host "outside of their logon hours may actually be able to continue to use those resources" -ForegroundColor Gray
        Write-Host "with sessions that were established during allowed hours." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpire
        
        # Check Group Policy setting
        $groupPolicyResult = Test-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to disconnect clients when logon hours expire." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to disconnect clients when logon hours expire." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Microsoft network server disconnect clients when logon hours expire audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.9.4" -Title "Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'" -CurrentValue "Error" -RecommendedValue "Enabled" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireAudit
        
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
Export-ModuleMember -Function Audit-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpire, Test-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireGroupPolicy, Invoke-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireAudit