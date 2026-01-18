<#
.SYNOPSIS
    CIS Remediation Script for 2.3.4.1 - Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'
.DESCRIPTION
    This script remediates the setting that prevents users from installing printer drivers.
    When enabled, only administrators can install printer drivers, preventing users from
    potentially installing malicious software disguised as printer drivers.
.NOTES
    File Name      : 2.3.4.1-remediate-prevent-users-from-installing-printer-drivers.ps1
    CIS ID         : 2.3.4.1
    CIS Title      : Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'
    CIS Profile     : L2
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
    Write-Host "Administrator privileges required for prevent users from installing printer drivers remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to enable prevent users from installing printer drivers
function Enable-PreventUsersFromInstallingPrinterDrivers {
    <#
    .SYNOPSIS
        Enables the prevent users from installing printer drivers setting
    .DESCRIPTION
        Sets registry value to prevent users from installing printer drivers
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.4.1 - Prevent Users From Installing Printer Drivers ===" -ForegroundColor Cyan
        Write-Host "Enabling prevent users from installing printer drivers setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers"
        $valueName = "AddPrinterDrivers"
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                $previousStatus = "Disabled (default)"
            } else {
                $previousStatus = if ($currentValue -eq 1) { "Enabled" } else { "Disabled" }
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Set registry value to enable (1 = enabled)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 1 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 1) { "Enabled" } else { "Disabled" }
            
            if ($newStatus -eq "Enabled") {
                Write-Host "Prevent users from installing printer drivers setting successfully enabled" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Prevent users from installing printer drivers setting successfully enabled"
                }
            } else {
                Write-Host "Failed to enable prevent users from installing printer drivers setting" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to enable prevent users from installing printer drivers setting"
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to enable
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 1 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 1) { "Enabled" } else { "Disabled" }
            
            if ($newStatus -eq "Enabled") {
                Write-Host "Prevent users from installing printer drivers setting successfully configured" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Prevent users from installing printer drivers setting successfully configured"
                }
            } else {
                Write-Host "Failed to configure prevent users from installing printer drivers setting" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure prevent users from installing printer drivers setting"
                }
            }
        }
    }
    catch {
        Write-Error "Failed to enable prevent users from installing printer drivers setting: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to enable prevent users from installing printer drivers setting: $_"
        }
    }
}

# Function to configure Group Policy for prevent users from installing printer drivers
function Configure-PreventUsersFromInstallingPrinterDriversGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy to prevent users from installing printer drivers
    .DESCRIPTION
        Sets registry value to prevent users from installing printer drivers via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
        $valueName = "AddPrinterDrivers"
        
        # Ensure registry path exists
        if (-not (Test-RegistryKey -KeyPath $registryPath)) {
            New-RegistryKey -KeyPath $registryPath
        }
        
        # Set registry value to enable (1 = enabled)
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 1 -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        if ($policyValue -eq 1) {
            Write-Host "Group Policy setting configured successfully" -ForegroundColor Green
            return [PSCustomObject]@{
                Success = $true
                Message = "Group Policy setting configured to prevent users from installing printer drivers"
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
function Invoke-PreventUsersFromInstallingPrinterDriversRemediation {
    <#
    .SYNOPSIS
        Main function to execute prevent users from installing printer drivers remediation
    .DESCRIPTION
        Performs comprehensive remediation of the prevent users from installing printer drivers setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.4.1 - Prevent Users From Installing Printer Drivers ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'" -ForegroundColor White
        Write-Host "Rationale: Prevents users from potentially installing malicious software disguised as printer drivers." -ForegroundColor Gray
        Write-Host "Only administrators should be able to install printer drivers." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $preventResult = Enable-PreventUsersFromInstallingPrinterDrivers
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-PreventUsersFromInstallingPrinterDriversGroupPolicy
        
        # Determine overall success
        $overallSuccess = $preventResult.Success -and $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.4.1" -Title "Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'" -PreviousValue $preventResult.PreviousValue -NewValue $preventResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Prevent users from installing printer drivers remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
        # Output detailed information
        if ($VerboseOutput) {
            Write-Host ""
            Write-Host "=== Remediation Summary ===" -ForegroundColor Cyan
            Write-Host "Registry Setting: $($preventResult.Message)" -ForegroundColor $(if ($preventResult.Success) { "Green" } else { "Red" })
            Write-Host "Group Policy: $($groupPolicyResult.Message)" -ForegroundColor $(if ($groupPolicyResult.Success) { "Green" } else { "Red" })
            Write-Host "Overall Status: $($result.Status)" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
        }
        
        return $result
    }
    catch {
        Write-Error "Prevent users from installing printer drivers remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.4.1" -Title "Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-PreventUsersFromInstallingPrinterDriversRemediation
        
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
Export-ModuleMember -Function Enable-PreventUsersFromInstallingPrinterDrivers, Configure-PreventUsersFromInstallingPrinterDriversGroupPolicy, Invoke-PreventUsersFromInstallingPrinterDriversRemediation