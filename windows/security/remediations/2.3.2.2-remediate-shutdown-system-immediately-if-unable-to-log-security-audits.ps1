<#
.SYNOPSIS
    CIS Remediation Script for 2.3.2.2 - Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'
.DESCRIPTION
    This script remediates the system shutdown behavior when unable to log security audits.
    When enabled, the system will shut down immediately if it cannot log security events,
    which could lead to unplanned system failures and potential data corruption.
.NOTES
    File Name      : 2.3.2.2-remediate-shutdown-system-immediately-if-unable-to-log-security-audits.ps1
    CIS ID         : 2.3.2.2
    CIS Title      : Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later, Administrator privileges
#>

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\WindowsUtils.psm1" -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Write-Host "Administrator privileges required for shutdown system immediately remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to disable shutdown system immediately if unable to log security audits
function Disable-ShutdownSystemImmediatelyIfUnableToLogSecurityAudits {
    <#
    .SYNOPSIS
        Disables the shutdown system immediately if unable to log security audits setting
    .DESCRIPTION
        Sets registry value to disable the shutdown system immediately setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.2.2 - Shutdown System Immediately If Unable To Log Security Audits ===" -ForegroundColor Cyan
        Write-Host "Disabling shutdown system immediately if unable to log security audits..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $valueName = "CrashOnAuditFail"
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                $previousStatus = "Disabled (default)"
            } else {
                $previousStatus = if ($currentValue -eq 0) { "Disabled" } else { "Enabled" }
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Set registry value to disable (0 = disabled)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 0) { "Disabled" } else { "Enabled" }
            
            if ($newStatus -eq "Disabled") {
                Write-Host "Shutdown system immediately setting successfully disabled" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Shutdown system immediately setting successfully disabled"
                }
            } else {
                Write-Host "Failed to disable shutdown system immediately setting" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to disable shutdown system immediately setting"
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to disable
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 0) { "Disabled" } else { "Enabled" }
            
            if ($newStatus -eq "Disabled") {
                Write-Host "Shutdown system immediately setting successfully configured" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Shutdown system immediately setting successfully configured"
                }
            } else {
                Write-Host "Failed to configure shutdown system immediately setting" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure shutdown system immediately setting"
                }
            }
        }
    }
    catch {
        Write-Error "Failed to disable shutdown system immediately setting: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to disable shutdown system immediately setting: $_"
        }
    }
}

# Function to configure Group Policy for shutdown system immediately setting
function Configure-ShutdownSystemImmediatelyGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy to disable shutdown system immediately if unable to log security audits
    .DESCRIPTION
        Sets registry value to disable the setting via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog"
        $valueName = "CrashOnAuditFail"
        
        # Ensure registry path exists
        if (-not (Test-RegistryKey -KeyPath $registryPath)) {
            New-RegistryKey -KeyPath $registryPath
        }
        
        # Set registry value to disable (0 = disabled)
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        if ($policyValue -eq 0) {
            Write-Host "Group Policy setting configured successfully" -ForegroundColor Green
            return [PSCustomObject]@{
                Success = $true
                Message = "Group Policy setting configured to disable shutdown system immediately if unable to log security audits"
            }
        } else {
            Write-Host "Failed to configure Group Policy setting" -ForegroundColor Red
            return [PSCustomObject]@{
                Success = $false
                Message = "Failed to configure Group Policy setting"
            }
        }
    }
    catch {
        Write-Warning "Failed to configure Group Policy setting: $_"
        return [PSCustomObject]@{
            Success = $false
            Message = "Failed to configure Group Policy setting: $_"
        }
    }
}

# Main remediation function
function Invoke-ShutdownSystemImmediatelyRemediation {
    <#
    .SYNOPSIS
        Main function to execute shutdown system immediately if unable to log security audits remediation
    .DESCRIPTION
        Performs comprehensive remediation of the shutdown system immediately setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.2.2 - Shutdown System Immediately If Unable To Log Security Audits ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'" -ForegroundColor White
        Write-Host "Rationale: If enabled, the system will shut down immediately when unable to log security events," -ForegroundColor Gray
        Write-Host "which could lead to unplanned system failures and potential data corruption." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $shutdownResult = Disable-ShutdownSystemImmediatelyIfUnableToLogSecurityAudits
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-ShutdownSystemImmediatelyGroupPolicy
        
        # Determine overall success
        $overallSuccess = $shutdownResult.Success -and $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.2.2" -Title "Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'" -PreviousValue $shutdownResult.PreviousValue -NewValue $shutdownResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Shutdown system immediately remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
        # Output detailed information
        if ($VerboseOutput) {
            Write-Host ""
            Write-Host "=== Remediation Summary ===" -ForegroundColor Cyan
            Write-Host "Registry Setting: $($shutdownResult.Message)" -ForegroundColor $(if ($shutdownResult.Success) { "Green" } else { "Red" })
            Write-Host "Group Policy: $($groupPolicyResult.Message)" -ForegroundColor $(if ($groupPolicyResult.Success) { "Green" } else { "Red" })
            Write-Host "Overall Status: $($result.Status)" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
        }
        
        return $result
    }
    catch {
        Write-Error "Shutdown system immediately remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.2.2" -Title "Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-ShutdownSystemImmediatelyRemediation
        
        # Output summary
        Write-Host ""
        Write-Host "=== Remediation Summary ===" -ForegroundColor Cyan
        Write-Host "CIS ID: $($remediationResult.CIS_ID)" -ForegroundColor White
        Write-Host "Setting: $($remediationResult.Title)" -ForegroundColor White
        Write-Host "Previous Value: $($remediationResult.PreviousValue)" -ForegroundColor White
        Write-Host "New Value: $($remediationResult.NewValue)" -ForegroundColor White
        Write-Host "Status: $($remediationResult.Status)" -ForegroundColor $(if ($remediationResult.IsCompliant) { "Green" } else { "Red" })
        Write-Host "Message: $($remediationResult.Message)" -ForegroundColor White
        Write-Host "Source: $($remediationResult.Source)" -ForegroundColor White
        
        # Exit with appropriate code
        if ($remediationResult.IsCompliant) {
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
Export-ModuleMember -Function Disable-ShutdownSystemImmediatelyIfUnableToLogSecurityAudits, Configure-ShutdownSystemImmediatelyGroupPolicy, Invoke-ShutdownSystemImmediatelyRemediation