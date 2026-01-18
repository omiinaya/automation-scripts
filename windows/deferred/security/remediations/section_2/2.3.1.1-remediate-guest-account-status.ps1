<#
.SYNOPSIS
    CIS Remediation Script for 2.3.1.1 - Ensure 'Accounts: Guest account status' is set to 'Disabled'
.DESCRIPTION
    This script remediates the Guest account status by disabling it as recommended by CIS benchmarks.
    The Guest account allows unauthenticated network users to gain access to the system and should be disabled.
.NOTES
    File Name      : 2.3.1.1-remediate-guest-account-status.ps1
    CIS ID         : 2.3.1.1
    CIS Title      : Ensure 'Accounts: Guest account status' is set to 'Disabled'
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
    Write-Host "Administrator privileges required for Guest account remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to disable Guest account using PowerShell
function Disable-GuestAccount {
    <#
    .SYNOPSIS
        Disables the Guest account using PowerShell cmdlets
    .DESCRIPTION
        Uses Disable-LocalUser to disable the Guest account
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.1.1 - Guest Account Status ===" -ForegroundColor Cyan
        Write-Host "Disabling Guest account..." -ForegroundColor White
        
        # Check if Guest account exists
        $guestAccount = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
        
        if ($guestAccount) {
            # Get current status
            $previousStatus = if ($guestAccount.Enabled) { "Enabled" } else { "Disabled" }
            Write-Host "Current Guest account status: $previousStatus" -ForegroundColor White
            
            if ($guestAccount.Enabled) {
                # Disable the Guest account
                Disable-LocalUser -Name "Guest"
                
                # Verify the change
                Start-Sleep -Seconds 2
                $updatedAccount = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
                $newStatus = if ($updatedAccount.Enabled) { "Enabled" } else { "Disabled" }
                
                if ($newStatus -eq "Disabled") {
                    Write-Host "Guest account successfully disabled" -ForegroundColor Green
                    return [PSCustomObject]@{
                        PreviousValue = $previousStatus
                        NewValue = $newStatus
                        Success = $true
                        Message = "Guest account successfully disabled"
                    }
                } else {
                    Write-Host "Failed to disable Guest account" -ForegroundColor Red
                    return [PSCustomObject]@{
                        PreviousValue = $previousStatus
                        NewValue = $newStatus
                        Success = $false
                        Message = "Failed to disable Guest account"
                    }
                }
            } else {
                Write-Host "Guest account is already disabled" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $previousStatus
                    Success = $true
                    Message = "Guest account is already disabled"
                }
            }
        } else {
            Write-Host "Guest account not found (already disabled)" -ForegroundColor Green
            return [PSCustomObject]@{
                PreviousValue = "Not Found"
                NewValue = "Disabled"
                Success = $true
                Message = "Guest account not found (already disabled)"
            }
        }
    }
    catch {
        Write-Error "Failed to disable Guest account: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to disable Guest account: $_"
        }
    }
}

# Function to configure Group Policy for Guest account
function Configure-GuestAccountGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy to disable Guest account
    .DESCRIPTION
        Sets registry value to disable Guest account via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path for Guest account status
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "EnableGuestAccount"
        
        # Ensure registry path exists
        if (-not (Test-RegistryKey -KeyPath $registryPath)) {
            New-RegistryKey -KeyPath $registryPath
        }
        
        # Set registry value to disable Guest account (0 = disabled)
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        if ($policyValue -eq 0) {
            Write-Host "Group Policy setting configured successfully" -ForegroundColor Green
            return [PSCustomObject]@{
                Success = $true
                Message = "Group Policy setting configured to disable Guest account"
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
function Invoke-GuestAccountRemediation {
    <#
    .SYNOPSIS
        Main function to execute Guest account remediation
    .DESCRIPTION
        Performs comprehensive remediation of Guest account status
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.1.1 - Guest Account Status ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Accounts: Guest account status' is set to 'Disabled'" -ForegroundColor White
        Write-Host "Rationale: The Guest account allows unauthenticated network users to gain access to the system." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $guestResult = Disable-GuestAccount
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-GuestAccountGroupPolicy
        
        # Determine overall success
        $overallSuccess = $guestResult.Success -and $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.1.1" -Title "Ensure 'Accounts: Guest account status' is set to 'Disabled'" -PreviousValue $guestResult.PreviousValue -NewValue $guestResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Guest account remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Local User Account"
        
        # Output detailed information
        if ($VerboseOutput) {
            Write-Host ""
            Write-Host "=== Remediation Summary ===" -ForegroundColor Cyan
            Write-Host "Guest Account: $($guestResult.Message)" -ForegroundColor $(if ($guestResult.Success) { "Green" } else { "Red" })
            Write-Host "Group Policy: $($groupPolicyResult.Message)" -ForegroundColor $(if ($groupPolicyResult.Success) { "Green" } else { "Red" })
            Write-Host "Overall Status: $($result.Status)" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
        }
        
        return $result
    }
    catch {
        Write-Error "Guest account remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.1.1" -Title "Ensure 'Accounts: Guest account status' is set to 'Disabled'" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-GuestAccountRemediation
        
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
Export-ModuleMember -Function Disable-GuestAccount, Configure-GuestAccountGroupPolicy, Invoke-GuestAccountRemediation