<#
.SYNOPSIS
    CIS Remediation Script for 2.3.7.3 - Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'
.DESCRIPTION
    This script remediates the setting that determines the number of failed logon attempts that causes the machine to be locked out.
    The machine lockout policy is enforced only on machines that have BitLocker enabled for protecting OS volumes.
.NOTES
    File Name      : 2.3.7.3-remediate-interactive-logon-machine-account-lockout-threshold.ps1
    CIS ID         : 2.3.7.3
    CIS Title      : Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'
    CIS Profile     : BL
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
    Write-Host "Administrator privileges required for machine account lockout threshold remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to set machine account lockout threshold
function Set-MachineAccountLockoutThreshold {
    <#
    .SYNOPSIS
        Sets the machine account lockout threshold
    .DESCRIPTION
        Configures the registry value for machine account lockout threshold to 10 or fewer invalid logon attempts, but not 0
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.7.3 - Interactive Logon: Machine Account Lockout Threshold ===" -ForegroundColor Cyan
        Write-Host "Setting machine account lockout threshold..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "MaxDevicePasswordFailedAttempts"
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default value is 0 (machine will never lock out)
                $previousStatus = "0 (default)"
            } else {
                $previousStatus = $currentValue.ToString()
            }
            
            Write-Host "Current threshold: $previousStatus failed attempts" -ForegroundColor White
            
            # Set registry value to 10 (recommended value)
            # Note: Values from 1 to 3 will be interpreted as 4, so we set 10 directly
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 10 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = $newValue.ToString()
            
            if ($newStatus -eq "10") {
                Write-Host "Machine account lockout threshold successfully set to 10 failed attempts" -ForegroundColor Green
                Write-Host "Machine will lock out after 10 failed logon attempts" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Machine account lockout threshold successfully set to 10 failed attempts"
                }
            } else {
                Write-Host "Failed to set machine account lockout threshold" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to set machine account lockout threshold"
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to 10 (recommended value)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 10 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = $newValue.ToString()
            
            if ($newStatus -eq "10") {
                Write-Host "Machine account lockout threshold successfully configured" -ForegroundColor Green
                Write-Host "Machine will lock out after 10 failed logon attempts" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Machine account lockout threshold successfully configured"
                }
            } else {
                Write-Host "Failed to configure machine account lockout threshold" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure machine account lockout threshold"
                }
            }
        }
    }
    catch {
        Write-Error "Failed to set machine account lockout threshold: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to set machine account lockout threshold: $_"
        }
    }
}

# Function to configure Group Policy for machine account lockout threshold
function Configure-MachineAccountLockoutThresholdGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy for machine account lockout threshold
    .DESCRIPTION
        Sets registry value for machine account lockout threshold via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        $valueName = "MaxDevicePasswordFailedAttempts"
        
        # Ensure registry path exists
        if (-not (Test-RegistryKey -KeyPath $registryPath)) {
            New-RegistryKey -KeyPath $registryPath
        }
        
        # Set registry value to 10 (recommended value)
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 10 -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        if ($policyValue -eq 10) {
            Write-Host "Group Policy setting configured successfully" -ForegroundColor Green
            Write-Host "Machine account lockout threshold set to 10 failed attempts via Group Policy" -ForegroundColor Green
            return [PSCustomObject]@{
                Success = $true
                Message = "Group Policy setting configured to 10 failed attempts"
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

# Main remediation function
function Invoke-MachineAccountLockoutThresholdRemediation {
    <#
    .SYNOPSIS
        Main function to execute machine account lockout threshold remediation
    .DESCRIPTION
        Performs comprehensive remediation of the machine account lockout threshold setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.7.3 - Interactive Logon: Machine Account Lockout Threshold ===" -ForegroundColor Cyan
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
        
        # Perform main remediation
        $thresholdResult = Set-MachineAccountLockoutThreshold
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-MachineAccountLockoutThresholdGroupPolicy
        
        # Determine overall success
        $overallSuccess = $thresholdResult.Success -and $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.7.3" -Title "Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'" -PreviousValue $thresholdResult.PreviousValue -NewValue $thresholdResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Machine account lockout threshold remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
        # Output detailed information
        if ($VerboseOutput) {
            Write-Host ""
            Write-Host "=== Remediation Summary ===" -ForegroundColor Cyan
            Write-Host "Registry Setting: $($thresholdResult.Message)" -ForegroundColor $(if ($thresholdResult.Success) { "Green" } else { "Red" })
            Write-Host "Group Policy: $($groupPolicyResult.Message)" -ForegroundColor $(if ($groupPolicyResult.Success) { "Green" } else { "Red" })
            Write-Host "BitLocker Status: $($bitLockerResult.Status)" -ForegroundColor $(if ($bitLockerResult.IsEnabled) { "Green" } else { "Yellow" })
            Write-Host "Overall Status: $($result.Status)" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
        }
        
        return $result
    }
    catch {
        Write-Error "Machine account lockout threshold remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.7.3" -Title "Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-MachineAccountLockoutThresholdRemediation
        
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
Export-ModuleMember -Function Set-MachineAccountLockoutThreshold, Configure-MachineAccountLockoutThresholdGroupPolicy, Test-BitLockerEnabled, Invoke-MachineAccountLockoutThresholdRemediation