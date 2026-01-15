<#
.SYNOPSIS
    CIS Audit Script for 2.3.7.1 - Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'
.DESCRIPTION
    This script audits the setting that determines whether users must press CTRL+ALT+DEL before they log on.
    When disabled, users must press CTRL+ALT+DEL before logging on, which provides a trusted path for
    password communication and prevents Trojan horse attacks that mimic the Windows logon dialog box.
.NOTES
    File Name      : 2.3.7.1-audit-interactive-logon-do-not-require-ctrl-alt-del.ps1
    CIS ID         : 2.3.7.1
    CIS Title      : Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit interactive logon CTRL+ALT+DEL requirement
function Audit-InteractiveLogonDoNotRequireCtrlAltDel {
    <#
    .SYNOPSIS
        Audits the interactive logon CTRL+ALT+DEL requirement setting
    .DESCRIPTION
        Checks if CTRL+ALT+DEL is required before logon as recommended by CIS benchmarks
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.7.1 - Interactive Logon: Do Not Require CTRL+ALT+DEL ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "DisableCAD"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set depends on Windows version
                # Windows 7 or older: Disabled (CTRL+ALT+DEL required)
                # Windows 8.0 or newer: Enabled (CTRL+ALT+DEL not required)
                $osVersion = [System.Environment]::OSVersion.Version
                if ($osVersion.Major -eq 6 -and $osVersion.Minor -le 1) {
                    # Windows 7 or older
                    $currentStatus = "Disabled"
                    $details = "Registry value not set (defaults to Disabled - CTRL+ALT+DEL required on Windows 7 or older)"
                    $isCompliant = $true
                } else {
                    # Windows 8.0 or newer
                    $currentStatus = "Enabled"
                    $details = "Registry value not set (defaults to Enabled - CTRL+ALT+DEL not required on Windows 8.0 or newer)"
                    $isCompliant = $false
                }
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
            $result = New-CISResultObject -CIS_ID "2.3.7.1" -Title "Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Disabled" -ForegroundColor White
            
            # Determine default behavior based on Windows version
            $osVersion = [System.Environment]::OSVersion.Version
            if ($osVersion.Major -eq 6 -and $osVersion.Minor -le 1) {
                # Windows 7 or older
                $currentStatus = "Disabled"
                $details = "Registry key not found (defaults to Disabled - CTRL+ALT+DEL required on Windows 7 or older)"
                $isCompliant = $true
            } else {
                # Windows 8.0 or newer
                $currentStatus = "Enabled"
                $details = "Registry key not found (defaults to Enabled - CTRL+ALT+DEL not required on Windows 8.0 or newer)"
                $isCompliant = $false
            }
            
            Write-Host "Compliance: $(if ($isCompliant) { 'Compliant' } else { 'Non-Compliant' })" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            $result = New-CISResultObject -CIS_ID "2.3.7.1" -Title "Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled" -ComplianceStatus $(if ($isCompliant) { "Compliant" } else { "Non-Compliant" }) -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit interactive logon CTRL+ALT+DEL requirement setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.7.1" -Title "Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'" -CurrentValue "Error" -RecommendedValue "Disabled" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-InteractiveLogonDoNotRequireCtrlAltDelGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for interactive logon CTRL+ALT+DEL requirement
    .DESCRIPTION
        Verifies if Group Policy is configured to require CTRL+ALT+DEL before logon
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        $valueName = "DisableCAD"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for interactive logon CTRL+ALT+DEL requirement"
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
function Invoke-InteractiveLogonDoNotRequireCtrlAltDelAudit {
    <#
    .SYNOPSIS
        Main function to execute interactive logon CTRL+ALT+DEL requirement audit
    .DESCRIPTION
        Performs comprehensive audit of the interactive logon CTRL+ALT+DEL requirement setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.7.1 - Interactive Logon: Do Not Require CTRL+ALT+DEL ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'" -ForegroundColor White
        Write-Host "Rationale: Requiring CTRL+ALT+DEL before logon provides a trusted path for password communication" -ForegroundColor Gray
        Write-Host "and prevents Trojan horse attacks that mimic the Windows logon dialog box." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-InteractiveLogonDoNotRequireCtrlAltDel
        
        # Check Group Policy setting
        $groupPolicyResult = Test-InteractiveLogonDoNotRequireCtrlAltDelGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to require CTRL+ALT+DEL before logon." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to require CTRL+ALT+DEL before logon." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Interactive logon CTRL+ALT+DEL requirement audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.7.1" -Title "Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'" -CurrentValue "Error" -RecommendedValue "Disabled" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-InteractiveLogonDoNotRequireCtrlAltDelAudit
        
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
Export-ModuleMember -Function Audit-InteractiveLogonDoNotRequireCtrlAltDel, Test-InteractiveLogonDoNotRequireCtrlAltDelGroupPolicy, Invoke-InteractiveLogonDoNotRequireCtrlAltDelAudit