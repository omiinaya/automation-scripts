<#
.SYNOPSIS
    CIS Remediation Script for 2.3.7.4 - Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'
.DESCRIPTION
    This script remediates the setting that determines the machine inactivity limit before automatic lockout.
    This setting specifies the amount of time a machine can be inactive before requiring re-authentication.
.NOTES
    File Name      : 2.3.7.4-remediate-interactive-logon-machine-inactivity-limit.ps1
    CIS ID         : 2.3.7.4
    CIS Title      : Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'
    CIS Profile     : L1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later, Administrator privileges
#>

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISRemediation.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\..\modules\RegistryUtils.psm1" -Force -WarningAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\..\modules\WindowsUtils.psm1" -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Write-Host "Administrator privileges required for machine inactivity limit remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to set machine inactivity limit
function Set-MachineInactivityLimit {
    <#
    .SYNOPSIS
        Sets the machine inactivity limit
    .DESCRIPTION
        Configures the registry value for machine inactivity limit to 900 or fewer seconds, but not 0
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.7.4 - Interactive Logon: Machine Inactivity Limit ===" -ForegroundColor Cyan
        Write-Host "Setting machine inactivity limit..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "InactivityTimeoutSec"
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default value is 0 (no inactivity limit)
                $previousStatus = "0 (default)"
            } else {
                $previousStatus = $currentValue.ToString()
            }
            
            Write-Host "Current inactivity limit: $previousStatus seconds" -ForegroundColor White
            
            # Set registry value to 900 (recommended value - 15 minutes)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 900 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = $newValue.ToString()
            
            if ($newStatus -eq "900") {
                Write-Host "Machine inactivity limit successfully set to 900 seconds (15 minutes)" -ForegroundColor Green
                Write-Host "Machine will require re-authentication after 15 minutes of inactivity" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Machine inactivity limit successfully set to 900 seconds"
                }
            } else {
                Write-Host "Failed to set machine inactivity limit" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to set machine inactivity limit"
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to 900 (recommended value - 15 minutes)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 900 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = $newValue.ToString()
            
            if ($newStatus -eq "900") {
                Write-Host "Machine inactivity limit successfully configured" -ForegroundColor Green
                Write-Host "Machine will require re-authentication after 15 minutes of inactivity" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Machine inactivity limit successfully configured"
                }
            } else {
                Write-Host "Failed to configure machine inactivity limit" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure machine inactivity limit"
                }
            }
        }
    }
    catch {
        Write-Error "Failed to set machine inactivity limit: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to set machine inactivity limit: $_"
        }
    }
}

# Function to configure Group Policy for machine inactivity limit
function Configure-MachineInactivityLimitGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy for machine inactivity limit
    .DESCRIPTION
        Sets registry value for machine inactivity limit via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        $valueName = "InactivityTimeoutSec"
        
        # Ensure registry path exists
        if (-not (Test-RegistryKey -KeyPath $registryPath)) {
            New-RegistryKey -KeyPath $registryPath
        }
        
        # Set registry value to 900 (recommended value - 15 minutes)
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 900 -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        if ($policyValue -eq 900) {
            Write-Host "Group Policy setting configured successfully" -ForegroundColor Green
            Write-Host "Machine inactivity limit set to 900 seconds (15 minutes) via Group Policy" -ForegroundColor Green
            return [PSCustomObject]@{
                Success = $true
                Message = "Group Policy setting configured to 900 seconds"
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
function Invoke-MachineInactivityLimitRemediation {
    <#
    .SYNOPSIS
        Main function to execute machine inactivity limit remediation
    .DESCRIPTION
        Performs comprehensive remediation of the machine inactivity limit setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.7.4 - Interactive Logon: Machine Inactivity Limit ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'" -ForegroundColor White
        Write-Host "Rationale: This setting determines how long a machine can be inactive before requiring re-authentication." -ForegroundColor Gray
        Write-Host "Setting an appropriate inactivity limit helps prevent unauthorized access to unattended machines." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $inactivityResult = Set-MachineInactivityLimit
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-MachineInactivityLimitGroupPolicy
        
        # Determine overall success
        $overallSuccess = $inactivityResult.Success -and $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.7.4" -Title "Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'" -PreviousValue $inactivityResult.PreviousValue -NewValue $inactivityResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Machine inactivity limit remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
        # Output detailed information
        if ($VerboseOutput) {
            Write-Host ""
            Write-Host "=== Remediation Summary ===" -ForegroundColor Cyan
            Write-Host "Registry Setting: $($inactivityResult.Message)" -ForegroundColor $(if ($inactivityResult.Success) { "Green" } else { "Red" })
            Write-Host "Group Policy: $($groupPolicyResult.Message)" -ForegroundColor $(if ($groupPolicyResult.Success) { "Green" } else { "Red" })
            Write-Host "Overall Status: $($result.Status)" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
        }
        
        return $result
    }
    catch {
        Write-Error "Machine inactivity limit remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.7.4" -Title "Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-MachineInactivityLimitRemediation
        
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
Export-ModuleMember -Function Set-MachineInactivityLimit, Configure-MachineInactivityLimitGroupPolicy, Invoke-MachineInactivityLimitRemediation