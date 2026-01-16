<#
.SYNOPSIS
    CIS Audit Script for 2.3.9.5 - Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher
.DESCRIPTION
    This script audits the setting that controls the level of validation a computer with shared folders or
    printers performs on the service principal name (SPN) that is provided by the client computer when
    it establishes a session using the server message block (SMB) protocol.
.NOTES
    File Name      : 2.3.9.5-audit-microsoft-network-server-server-spn-target-name-validation-level.ps1
    CIS ID         : 2.3.9.5
    CIS Title      : Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit Microsoft network server server SPN target name validation level
function Audit-MicrosoftNetworkServerServerSPNTargetNameValidationLevel {
    <#
    .SYNOPSIS
        Audits the Microsoft network server server SPN target name validation level setting
    .DESCRIPTION
        Checks if the SPN target name validation level is set to 'Accept if provided by client' or higher as recommended by CIS benchmarks
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.9.5 - Microsoft Network Server: Server SPN Target Name Validation Level ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "SMBServerNameHardeningLevel"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "Off" according to JSON
                $currentStatus = "Off"
                $details = "Registry value not set (defaults to 'Off' - SPN not required or validated)"
                $isCompliant = $false  # Default is Off, which is not compliant
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                
                # Map values to descriptive names
                switch ($currentValueInt) {
                    0 { $currentStatus = "Off" }
                    1 { $currentStatus = "Accept if provided by client" }
                    2 { $currentStatus = "Required from client" }
                    default { $currentStatus = "Unknown ($currentValueInt)" }
                }
                
                $details = "Registry value: $currentValueInt ($currentStatus)"
                
                # Check compliance: value must be 1 or 2 (Accept if provided by client or Required from client)
                $isCompliant = ($currentValueInt -eq 1 -or $currentValueInt -eq 2)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Accept if provided by client or higher" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.9.5" -Title "Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher" -CurrentValue $currentStatus -RecommendedValue "Accept if provided by client or higher" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Accept if provided by client or higher" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist is "Off" according to JSON
            $currentStatus = "Off"
            $details = "Registry key not found (defaults to 'Off' - SPN not required or validated)"
            $isCompliant = $false
            
            Write-Host "Compliance: Non-Compliant" -ForegroundColor Red
            
            $result = New-CISResultObject -CIS_ID "2.3.9.5" -Title "Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher" -CurrentValue $currentStatus -RecommendedValue "Accept if provided by client or higher" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit Microsoft network server server SPN target name validation level setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.9.5" -Title "Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher" -CurrentValue "Error" -RecommendedValue "Accept if provided by client or higher" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-MicrosoftNetworkServerServerSPNTargetNameValidationLevelGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for Microsoft network server server SPN target name validation level
    .DESCRIPTION
        Verifies if Group Policy is configured to set SPN target name validation level to 'Accept if provided by client' or higher
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanServer"
        $valueName = "SMBServerNameHardeningLevel"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for Microsoft network server server SPN target name validation level"
                $isCompliant = $false  # Default is Off, which is not compliant
            } else {
                # Convert to integer for comparison
                $policyValueInt = [int]$policyValue
                
                # Map values to descriptive names
                switch ($policyValueInt) {
                    0 { $policyStatus = "Off" }
                    1 { $policyStatus = "Accept if provided by client" }
                    2 { $policyStatus = "Required from client" }
                    default { $policyStatus = "Unknown ($policyValueInt)" }
                }
                
                Write-Host "Group Policy setting: $policyStatus" -ForegroundColor White
                $details = "Group Policy setting: $policyStatus"
                
                # Check compliance: value must be 1 or 2 (Accept if provided by client or Required from client)
                $isCompliant = ($policyValueInt -eq 1 -or $policyValueInt -eq 2)
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
                IsCompliant = $false  # Default is Off, which is not compliant
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
function Invoke-MicrosoftNetworkServerServerSPNTargetNameValidationLevelAudit {
    <#
    .SYNOPSIS
        Main function to execute Microsoft network server server SPN target name validation level audit
    .DESCRIPTION
        Performs comprehensive audit of the Microsoft network server server SPN target name validation level setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.9.5 - Microsoft Network Server: Server SPN Target Name Validation Level ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher" -ForegroundColor White
        Write-Host "Rationale: The identity of a computer can be spoofed to gain unauthorized access to network resources." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-MicrosoftNetworkServerServerSPNTargetNameValidationLevel
        
        # Check Group Policy setting
        $groupPolicyResult = Test-MicrosoftNetworkServerServerSPNTargetNameValidationLevelGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to validate SPN target names." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to validate SPN target names." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Microsoft network server server SPN target name validation level audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.9.5" -Title "Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher" -CurrentValue "Error" -RecommendedValue "Accept if provided by client or higher" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-MicrosoftNetworkServerServerSPNTargetNameValidationLevelAudit
        
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
Export-ModuleMember -Function Audit-MicrosoftNetworkServerServerSPNTargetNameValidationLevel, Test-MicrosoftNetworkServerServerSPNTargetNameValidationLevelGroupPolicy, Invoke-MicrosoftNetworkServerServerSPNTargetNameValidationLevelAudit