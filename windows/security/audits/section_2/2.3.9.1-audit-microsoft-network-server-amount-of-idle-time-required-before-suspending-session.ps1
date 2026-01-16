<#
.SYNOPSIS
    CIS Audit Script for 2.3.9.1 - Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'
.DESCRIPTION
    This script audits the setting that controls the amount of continuous idle time that must pass
    in an SMB session before the session is suspended because of inactivity.
    The recommended value is 15 or fewer minutes to prevent resource exhaustion from numerous null sessions.
.NOTES
    File Name      : 2.3.9.1-audit-microsoft-network-server-amount-of-idle-time-required-before-suspending-session.ps1
    CIS ID         : 2.3.9.1
    CIS Title      : Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue

# Function to audit Microsoft network server amount of idle time required before suspending session
function Audit-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSession {
    <#
    .SYNOPSIS
        Audits the Microsoft network server amount of idle time required before suspending session setting
    .DESCRIPTION
        Checks if the idle time before suspending SMB sessions is set to 15 or fewer minutes as recommended by CIS benchmarks
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit: 2.3.9.1 - Microsoft Network Server: Amount of Idle Time Required Before Suspending Session ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "AutoDisconnect"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "15 minutes" according to JSON
                $currentStatus = "15 minutes"
                $details = "Registry value not set (defaults to '15 minutes' - sessions suspended after 15 minutes of inactivity)"
                $isCompliant = $true
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                $currentStatus = "$currentValueInt minute(s)"
                $details = "Registry value: $currentValueInt minute(s)"
                
                # Check compliance: value must be 15 or fewer (less than or equal to 15)
                $isCompliant = ($currentValueInt -le 15)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: 15 or fewer minute(s)" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.9.1" -Title "Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'" -CurrentValue $currentStatus -RecommendedValue "15 or fewer minute(s)" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: 15 or fewer minute(s)" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist is "15 minutes" according to JSON
            $currentStatus = "15 minutes"
            $details = "Registry key not found (defaults to '15 minutes' - sessions suspended after 15 minutes of inactivity)"
            $isCompliant = $true
            
            Write-Host "Compliance: Compliant" -ForegroundColor Green
            
            $result = New-CISResultObject -CIS_ID "2.3.9.1" -Title "Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'" -CurrentValue $currentStatus -RecommendedValue "15 or fewer minute(s)" -ComplianceStatus "Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
    }
    catch {
        Write-Error "Failed to audit Microsoft network server amount of idle time required before suspending session setting: $_"
        
        # Return error result
        return New-CISResultObject -CIS_ID "2.3.9.1" -Title "Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'" -CurrentValue "Error" -RecommendedValue "15 or fewer minute(s)" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Function to check Group Policy setting
function Test-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionGroupPolicy {
    <#
    .SYNOPSIS
        Checks Group Policy setting for Microsoft network server amount of idle time required before suspending session
    .DESCRIPTION
        Verifies if Group Policy is configured to set idle time before suspending SMB sessions to 15 or fewer minutes
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanServer"
        $valueName = "AutoDisconnect"
        
        Write-Host "Checking Group Policy setting..." -ForegroundColor White
        
        if (Test-RegistryKey -KeyPath $registryPath) {
            $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
            
            if ($policyValue -eq "Not Configured") {
                Write-Host "Group Policy setting: Not configured" -ForegroundColor Yellow
                $details = "Group Policy not configured for Microsoft network server amount of idle time required before suspending session"
                $isCompliant = $true  # Default is 15 minutes, so not configured is compliant
            } else {
                # Convert to integer for comparison
                $policyValueInt = [int]$policyValue
                $policyStatus = "$policyValueInt minute(s)"
                
                Write-Host "Group Policy setting: $policyStatus" -ForegroundColor White
                $details = "Group Policy setting: $policyStatus"
                
                # Check compliance: value must be 15 or fewer (less than or equal to 15)
                $isCompliant = ($policyValueInt -le 15)
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
                IsCompliant = $true  # Default is 15 minutes, so not found is compliant
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
function Invoke-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionAudit {
    <#
    .SYNOPSIS
        Main function to execute Microsoft network server amount of idle time required before suspending session audit
    .DESCRIPTION
        Performs comprehensive audit of the Microsoft network server amount of idle time required before suspending session setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Audit 2.3.9.1 - Microsoft Network Server: Amount of Idle Time Required Before Suspending Session ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'" -ForegroundColor White
        Write-Host "Rationale: Each SMB session consumes server resources, and numerous null sessions will slow" -ForegroundColor Gray
        Write-Host "the server or possibly cause it to fail. An attacker could repeatedly establish SMB" -ForegroundColor Gray
        Write-Host "sessions until the server's SMB services become slow or unresponsive." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main audit
        $mainResult = Audit-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSession
        
        # Check Group Policy setting
        $groupPolicyResult = Test-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionGroupPolicy
        
        # Combine results
        if ($groupPolicyResult.IsCompliant) {
            Write-Host ""
            Write-Host "Group Policy is properly configured to suspend SMB sessions after 15 or fewer minutes of inactivity." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Group Policy is not configured to suspend SMB sessions after 15 or fewer minutes of inactivity." -ForegroundColor Yellow
        }
        
        return $mainResult
    }
    catch {
        Write-Error "Microsoft network server amount of idle time required before suspending session audit failed: $_"
        return New-CISResultObject -CIS_ID "2.3.9.1" -Title "Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'" -CurrentValue "Error" -RecommendedValue "15 or fewer minute(s)" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile "L1"
    }
}

# Execute audit if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $auditResult = Invoke-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionAudit
        
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
Export-ModuleMember -Function Audit-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSession, Test-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionGroupPolicy, Invoke-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionAudit