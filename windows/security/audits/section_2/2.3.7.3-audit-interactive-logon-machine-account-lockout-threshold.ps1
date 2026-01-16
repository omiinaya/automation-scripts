<#
.SYNOPSIS
    CIS Audit Script for 2.3.7.3 - Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'
.DESCRIPTION
    This script audits the setting that determines the number of failed logon attempts that causes the machine to be locked out.
    The machine lockout policy is enforced only on machines that have BitLocker enabled for protecting OS volumes.
.NOTES
    File Name      : 2.3.7.3-audit-interactive-logon-machine-account-lockout-threshold.ps1
    CIS ID         : 2.3.7.3
    CIS Title      : Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'
    CIS Profile     : BL
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit machine account lockout threshold
function Audit-InteractiveLogonMachineAccountLockoutThreshold {
    <#
    .SYNOPSIS
        Audits the machine account lockout threshold setting
    .DESCRIPTION
        Checks if the machine account lockout threshold is set to 10 or fewer invalid logon attempts, but not 0
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.7.3 - Interactive Logon: Machine Account Lockout Threshold ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "MaxDevicePasswordFailedAttempts"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default value is 0 (machine will never lock out)
                $currentStatus = "0"
                $details = "Registry value not set (defaults to 0 - machine will never lock out)"
                $isCompliant = $false
            } else {
                $currentStatus = $currentValue.ToString()
                $details = "Registry value: $currentStatus"
                
                # Check compliance: value must be 10 or fewer, but not 0
                # Values from 1 to 3 will be interpreted as 4
                $effectiveValue = if ($currentValue -ge 1 -and $currentValue -le 3) { 4 } else { $currentValue }
                $isCompliant = ($effectiveValue -le 10 -and $effectiveValue -ne 0)
            }
            
            Write-Host "Current threshold: $currentStatus failed attempts" -ForegroundColor White
            Write-Host "Recommended: 10 or fewer invalid logon attempts, but not 0" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.7.3" -Title "Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'" -CurrentValue $currentStatus -RecommendedValue "10 or fewer invalid logon attempts, but not 0" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "BL"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: 10 or fewer invalid logon attempts, but not 0" -ForegroundColor White
            
            # Default value is 0 (machine will never lock out)
            $currentStatus = "0"
            $details = "Registry key not found (defaults to 0 - machine will never lock out)"
            $isCompliant = $false
            
            Write-Host "Compliance: $(if ($isCompliant) { 'Compliant' } else { 'Non-Compliant' })" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            $result = New-CISResultObject -CIS_ID "2.3.7.3" -Title "Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'" -CurrentValue $currentStatus -RecommendedValue "10 or fewer invalid logon attempts, but not 0" -ComplianceStatus $(if ($isCompliant) { "Compliant" } else { "Non-Compliant" }) -Source "Registry" -Details $details -Profile "BL"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit machine account lockout threshold setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.7.3" -Title "Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'" -CurrentValue "Error" -RecommendedValue "10 or fewer invalid logon attempts, but not 0" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "BL"
    }
}

# Function to check Group Policy setting
function Test-InteractiveLogonMachineAccountLockoutThresholdGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for machine account lockout threshold
    .DESCRIPTION
        Verifies if Group Policy is configured to set machine account lockout threshold to 10 or fewer invalid logon attempts
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        $valueName = "MaxDevicePasswordFailedAttempts"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for machine account lockout threshold"
                $isCompliant = $false
            } else {
                $policyStatus = $policyValue.ToString()
                Write-Host "Group Policy threshold: $policyStatus failed attempts" -ForegroundColor White
                $details = "Group Policy setting: $policyStatus"
                
                # Check compliance: value must be 10 or fewer, but not 0
                # Values from 1 to 3 will be interpreted as 4
                $effectiveValue = if ($policyValue -ge 1 -and $policyValue -le 3) { 4 } else { $policyValue }
                $isCompliant = ($effectiveValue -le 10 -and $effectiveValue -ne 0)
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

# Function to check BitLocker status
function Test-BitLockerEnabled {
    <#
    .SYNOPSIS
        Checks if BitLocker is enabled on the OS volume
    .DESCRIPTION
        Verifies if BitLocker is enabled, as machine lockout policy is only enforced when BitLocker is enabled
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host "Checking BitLocker status..." -ForegroundColor White
        
        # Check if BitLocker module is available
        if (Get-Module -ListAvailable -Name BitLocker) {
            Import-Module BitLocker -WarningAction SilentlyContinue
            
            $bitLockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
            
            if ($bitLockerStatus) {
                $isProtected = ($bitLockerStatus.ProtectionStatus -eq "On")
                $statusText = if ($isProtected) { "Enabled" } else { "Disabled" }
                
                Write-Host "BitLocker status: $statusText" -ForegroundColor White
                
                return [PSCustomObject]@{
                    IsEnabled = $isProtected
                    Status = $statusText
                    Details = "BitLocker protection status: $statusText"
                }
            } else {
                Write-Host "BitLocker status: Not configured" -ForegroundColor Yellow
                return [PSCustomObject]@{
                    IsEnabled = $false
                    Status = "Not Configured"
                    Details = "BitLocker is not configured on the OS volume"
                }
            }
        } else {
            Write-Host "BitLocker module not available" -ForegroundColor Yellow
            return [PSCustomObject]@{
                IsEnabled = $false
                Status = "Unknown"
                Details = "BitLocker module not available"
            }
        }
    }
    catch {
        Write-Warning "Failed to check BitLocker status: $_"
        return [PSCustomObject]@{
            IsEnabled = $false
            Status = "Error"
            Details = "Error checking BitLocker: $_"
        }
    }
}

# Main audit execution
function Invoke-InteractiveLogonMachineAccountLockoutThresholdAudit {
    <#
    .SYNOPSIS
        Main function to execute machine account lockout threshold audit
    .DESCRIPTION
        Performs comprehensive audit of the machine account lockout threshold setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.7.3 - Interactive Logon: Machine Account Lockout Threshold ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'" -ForegroundColor White
        Write-Host "Rationale: If a machine is lost or stolen, or if an insider threat attempts a brute force password attack" -ForegroundColor Gray
        Write-Host "against the computer, it is important to ensure that BitLocker will lock the computer" -ForegroundColor Gray
        Write-Host "and therefore prevent a successful attack." -ForegroundColor Gray
        Write-Host ""
        
        # Check BitLocker status
        $bitLockerResult = Test-BitLockerEnabled
        
        if ($bitLockerResult.IsEnabled) {
            Write-Host "BitLocker is enabled - machine lockout policy will be enforced." -ForegroundColor Green
        } else {
            Write-Host "BitLocker is not enabled - machine lockout policy will not be enforced." -ForegroundColor Yellow
            Write-Host "Note: Machine lockout policy is only enforced on machines with BitLocker enabled." -ForegroundColor Yellow
        }
        
        # Perform main audit
        $mainResult = Audit-InteractiveLogonMachineAccountLockoutThreshold
        
        # Check Group Policy setting
        $groupPolicyResult = Test-InteractiveLogonMachineAccountLockoutThresholdGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured for machine account lockout threshold." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured for machine account lockout threshold." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Machine account lockout threshold audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.7.3" -Title "Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'" -CurrentValue "Error" -RecommendedValue "10 or fewer invalid logon attempts, but not 0" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "BL"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-InteractiveLogonMachineAccountLockoutThresholdAudit
        
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
Export-ModuleMember -Function Audit-InteractiveLogonMachineAccountLockoutThreshold, Test-InteractiveLogonMachineAccountLockoutThresholdGroupPolicy, Test-BitLockerEnabled, Invoke-InteractiveLogonMachineAccountLockoutThresholdAudit