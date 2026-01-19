<#
.SYNOPSIS
    CIS Remediation Script for 2.3.7.7 - Ensure 'Interactive logon: Prompt user to change password before expiration' is set to '5 to 14 days'
.DESCRIPTION
    This script remediates the setting that determines how many days before password expiration users are warned.
    When configured between 5 and 14 days, users receive adequate warning to change their passwords before they expire,
    reducing the risk of account lockouts and ensuring password changes occur before expiration.
.NOTES
    File Name      : 2.3.7.7-remediate-interactive-logon-prompt-user-to-change-password-before-expiration.ps1
    CIS ID         : 2.3.7.7
    CIS Title      : Ensure 'Interactive logon: Prompt user to change password before expiration' is set to '5 to 14 days'
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
    Write-Host "Administrator privileges required for interactive logon password expiration warning remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to configure password expiration warning
function Configure-PasswordExpiryWarning {
    <#
    .SYNOPSIS
        Configures the password expiration warning setting
    .DESCRIPTION
        Sets registry value to warn users before password expiration
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.7.7 - Interactive Logon: Prompt User to Change Password Before Expiration ===" -ForegroundColor Cyan
        Write-Host "Configuring password expiration warning setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $valueName = "PasswordExpiryWarning"
        
        # CIS recommendation: 5 to 14 days
        $recommendedValue = 14  # Using maximum recommended value for best user experience
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is 5 days when not set
                $previousStatus = "5 days (default)"
                $previousValue = 5
            } else {
                $previousStatus = "$currentValue days"
                $previousValue = $currentValue
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is within CIS recommendation (5-14 days)
            if ($previousValue -ge 5 -and $previousValue -le 14) {
                Write-Host "Current setting is already within CIS recommendation (5-14 days)" -ForegroundColor Green
                Write-Host "No remediation needed" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $previousStatus
                    Success = $true
                    Message = "Setting already compliant with CIS recommendation"
                    RemediationApplied = $false
                }
            }
            
            # Set registry value to recommended value
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq "Not Set") { "5 days (default)" } else { "$newValue days" }
            
            if ($newValue -ge 5 -and $newValue -le 14) {
                Write-Host "Password expiration warning successfully configured to $newValue days" -ForegroundColor Green
                Write-Host "Users will be warned $newValue days before password expiration" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Password expiration warning successfully configured to $newValue days"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure password expiration warning within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure password expiration warning within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to recommended value
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq "Not Set") { "5 days (default)" } else { "$newValue days" }
            
            if ($newValue -ge 5 -and $newValue -le 14) {
                Write-Host "Password expiration warning successfully configured to $newValue days" -ForegroundColor Green
                Write-Host "Users will be warned $newValue days before password expiration" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Password expiration warning successfully configured to $newValue days"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure password expiration warning within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure password expiration warning within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        }
    }
    catch {
        Write-Error "Failed to configure password expiration warning: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to configure password expiration warning: $_"
            RemediationApplied = $false
        }
    }
}

# Function to configure Group Policy for password expiration warning
function Configure-PasswordExpiryWarningGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy for password expiration warning
    .DESCRIPTION
        Sets registry value to warn users before password expiration via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        $valueName = "PasswordExpiryWarning"
        
        # CIS recommendation: 5 to 14 days
        $recommendedValue = 14  # Using maximum recommended value for best user experience
        
        # Ensure registry path exists
        if (-not (Test-RegistryKey -KeyPath $registryPath)) {
            New-RegistryKey -KeyPath $registryPath
        }
        
        # Check current Group Policy value
        $currentPolicyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        if ($currentPolicyValue -eq "Not Configured") {
            $previousPolicyStatus = "Not Configured"
        } else {
            $previousPolicyStatus = "$currentPolicyValue days"
        }
        
        # Set registry value to recommended value
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        if ($policyValue -ge 5 -and $policyValue -le 14) {
            Write-Host "Group Policy setting configured successfully to $policyValue days" -ForegroundColor Green
            Write-Host "Users will be warned $policyValue days before password expiration via Group Policy" -ForegroundColor Green
            return [PSCustomObject]@{
                Success = $true
                Message = "Group Policy setting configured to warn users $policyValue days before password expiration"
                PreviousValue = $previousPolicyStatus
                NewValue = "$policyValue days"
            }
        } else {
            Write-Host "Failed to configure Group Policy setting" -ForegroundColor Red
            return [PSCustomObject]@{
                Success = $false
                Message = "Failed to configure Group Policy setting"
                PreviousValue = $previousPolicyStatus
                NewValue = "Error"
            }
        }
    }
    catch {
        Write-Warning "Failed to configure Group Policy setting: $_"
        return [PSCustomObject]@{
            Success = $false
            Message = "Failed to configure Group Policy setting: $_"
            PreviousValue = "Error"
            NewValue = "Error"
        }
    }
}

# Main remediation function
function Invoke-PasswordExpiryWarningRemediation {
    <#
    .SYNOPSIS
        Main function to execute password expiration warning remediation
    .DESCRIPTION
        Performs comprehensive remediation of the password expiration warning setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.7.7 - Interactive Logon: Prompt User to Change Password Before Expiration ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Interactive logon: Prompt user to change password before expiration' is set to '5 to 14 days'" -ForegroundColor White
        Write-Host "Rationale: Warning users before password expiration gives them adequate time to change passwords," -ForegroundColor Gray
        Write-Host "reducing the risk of account lockouts and ensuring password changes occur before expiration." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $configureResult = Configure-PasswordExpiryWarning
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-PasswordExpiryWarningGroupPolicy
        
        # Determine overall success
        $overallSuccess = $configureResult.Success -and $groupPolicyResult.Success
        
        # Determine if remediation was actually applied
        $remediationApplied = $configureResult.RemediationApplied -or $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.7.7" -Title "Ensure 'Interactive logon: Prompt user to change password before expiration' is set to '5 to 14 days'" -PreviousValue $configureResult.PreviousValue -NewValue $configureResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Password expiration warning remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
        # Output detailed information
        if ($VerboseOutput) {
            Write-Host ""
            Write-Host "=== Remediation Summary ===" -ForegroundColor Cyan
            Write-Host "Registry Setting: $($configureResult.Message)" -ForegroundColor $(if ($configureResult.Success) { "Green" } else { "Red" })
            Write-Host "Group Policy: $($groupPolicyResult.Message)" -ForegroundColor $(if ($groupPolicyResult.Success) { "Green" } else { "Red" })
            Write-Host "Overall Status: $($result.Status)" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
            Write-Host "Remediation Applied: $remediationApplied" -ForegroundColor White
        }
        
        return $result
    }
    catch {
        Write-Error "Password expiration warning remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.7.7" -Title "Ensure 'Interactive logon: Prompt user to change password before expiration' is set to '5 to 14 days'" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-PasswordExpiryWarningRemediation
        
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
Export-ModuleMember -Function Configure-PasswordExpiryWarning, Configure-PasswordExpiryWarningGroupPolicy, Invoke-PasswordExpiryWarningRemediation