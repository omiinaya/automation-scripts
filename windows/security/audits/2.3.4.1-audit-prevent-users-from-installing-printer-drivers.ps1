<#
.SYNOPSIS
    CIS Audit Script for 2.3.4.1 - Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'
.DESCRIPTION
    This script audits the setting that prevents users from installing printer drivers.
    When enabled, only administrators can install printer drivers, preventing users from
    potentially installing malicious software disguised as printer drivers.
.NOTES
    File Name      : 2.3.4.1-audit-prevent-users-from-installing-printer-drivers.ps1
    CIS ID         : 2.3.4.1
    CIS Title      : Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'
    CIS Profile     : L2
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit prevent users from installing printer drivers
function Audit-PreventUsersFromInstallingPrinterDrivers {
    <#
    .SYNOPSIS
        Audits the prevent users from installing printer drivers setting
    .DESCRIPTION
        Checks if users are prevented from installing printer drivers as recommended by CIS benchmarks
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.4.1 - Prevent Users From Installing Printer Drivers ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers"
        $valueName = "AddPrinterDrivers"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is Disabled (users can install drivers)
                $currentStatus = "Disabled"
                $details = "Registry value not set (defaults to Disabled - users can install drivers)"
                $isCompliant = $false
            } else {
                $currentStatus = if ($currentValue -eq 1) { "Enabled" } else { "Disabled" }
                $details = "Registry value: $currentValue ($currentStatus)"
                $isCompliant = ($currentValue -eq 1)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Enabled" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.4.1" -Title "Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L2"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Enabled" -ForegroundColor White
            Write-Host "Compliance: Non-Compliant (key not found, defaults to Disabled)" -ForegroundColor Red
            
            $result = New-CISResultObject -CIS_ID "2.3.4.1" -Title "Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'" -CurrentValue "Disabled" -RecommendedValue "Enabled" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details "Registry key not found (defaults to Disabled - users can install drivers)" -Profile "L2"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit prevent users from installing printer drivers setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.4.1" -Title "Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'" -CurrentValue "Error" -RecommendedValue "Enabled" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L2"
    }
}

# Function to check Group Policy setting
function Test-PreventUsersFromInstallingPrinterDriversGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for prevent users from installing printer drivers
    .DESCRIPTION
        Verifies if Group Policy is configured to prevent users from installing printer drivers
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
        $valueName = "AddPrinterDrivers"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for prevent users from installing printer drivers"
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
function Invoke-PreventUsersFromInstallingPrinterDriversAudit {
    <#
    .SYNOPSIS
        Main function to execute prevent users from installing printer drivers audit
    .DESCRIPTION
        Performs comprehensive audit of the prevent users from installing printer drivers setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.4.1 - Prevent Users From Installing Printer Drivers ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'" -ForegroundColor White
        Write-Host "Rationale: Prevents users from potentially installing malicious software disguised as printer drivers." -ForegroundColor Gray
        Write-Host "Only administrators should be able to install printer drivers." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-PreventUsersFromInstallingPrinterDrivers
        
        # Check Group Policy setting
        $groupPolicyResult = Test-PreventUsersFromInstallingPrinterDriversGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to prevent users from installing printer drivers." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to prevent users from installing printer drivers." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Prevent users from installing printer drivers audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.4.1" -Title "Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'" -CurrentValue "Error" -RecommendedValue "Enabled" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L2"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-PreventUsersFromInstallingPrinterDriversAudit
        
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
Export-ModuleMember -Function Audit-PreventUsersFromInstallingPrinterDrivers, Test-PreventUsersFromInstallingPrinterDriversGroupPolicy, Invoke-PreventUsersFromInstallingPrinterDriversAudit