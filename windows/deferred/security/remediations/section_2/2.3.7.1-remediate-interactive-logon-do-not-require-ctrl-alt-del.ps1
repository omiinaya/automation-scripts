<#
.SYNOPSIS
    CIS Remediation Script for 2.3.7.1 - Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'
.DESCRIPTION
    This script remediates the setting that determines whether users must press CTRL+ALT+DEL before they log on.
    When disabled, users must press CTRL+ALT+DEL before logging on, which provides a trusted path for
    password communication and prevents Trojan horse attacks that mimic the Windows logon dialog box.
.NOTES
    File Name      : 2.3.7.1-remediate-interactive-logon-do-not-require-ctrl-alt-del.ps1
    CIS ID         : 2.3.7.1
    CIS Title      : Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'
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
    Write-Host "Administrator privileges required for interactive logon CTRL+ALT+DEL requirement remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to disable interactive logon do not require CTRL+ALT+DEL
function Disable-InteractiveLogonDoNotRequireCtrlAltDel {
    <#
    .SYNOPSIS
        Disables the interactive logon do not require CTRL+ALT+DEL setting
    .DESCRIPTION
        Sets registry value to require CTRL+ALT+DEL before logon
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.7.1 - Interactive Logon: Do Not Require CTRL+ALT+DEL ===" -ForegroundColor Cyan
        Write-Host "Disabling interactive logon do not require CTRL+ALT+DEL setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "DisableCAD"
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Determine default behavior based on Windows version
                $osVersion = [System.Environment]::OSVersion.Version
                if ($osVersion.Major -eq 6 -and $osVersion.Minor -le 1) {
                    # Windows 7 or older - defaults to Disabled (CTRL+ALT+DEL required)
                    $previousStatus = "Disabled (default)"
                } else {
                    # Windows 8.0 or newer - defaults to Enabled (CTRL+ALT+DEL not required)
                    $previousStatus = "Enabled (default)"
                }
            } else {
                $previousStatus = if ($currentValue -eq 0) { "Disabled" } else { "Enabled" }
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Set registry value to disable (0 = disabled, meaning CTRL+ALT+DEL required)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 0) { "Disabled" } else { "Enabled" }
            
            if ($newStatus -eq "Disabled") {
                Write-Host "Interactive logon CTRL+ALT+DEL requirement successfully disabled" -ForegroundColor Green
                Write-Host "CTRL+ALT+DEL will now be required before logon" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Interactive logon CTRL+ALT+DEL requirement successfully disabled"
                }
            } else {
                Write-Host "Failed to disable interactive logon CTRL+ALT+DEL requirement" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to disable interactive logon CTRL+ALT+DEL requirement"
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to disable (0 = disabled, meaning CTRL+ALT+DEL required)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 0) { "Disabled" } else { "Enabled" }
            
            if ($newStatus -eq "Disabled") {
                Write-Host "Interactive logon CTRL+ALT+DEL requirement successfully configured" -ForegroundColor Green
                Write-Host "CTRL+ALT+DEL will now be required before logon" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Interactive logon CTRL+ALT+DEL requirement successfully configured"
                }
            } else {
                Write-Host "Failed to configure interactive logon CTRL+ALT+DEL requirement" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure interactive logon CTRL+ALT+DEL requirement"
                }
            }
        }
    }
    catch {
        Write-Error "Failed to disable interactive logon CTRL+ALT+DEL requirement: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to disable interactive logon CTRL+ALT+DEL requirement: $_"
        }
    }
}

# Function to configure Group Policy for interactive logon CTRL+ALT+DEL requirement
function Configure-InteractiveLogonDoNotRequireCtrlAltDelGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy to require CTRL+ALT+DEL before logon
    .DESCRIPTION
        Sets registry value to require CTRL+ALT+DEL before logon via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        $valueName = "DisableCAD"
        
        # Ensure registry path exists
        if (-not (Test-RegistryKey -KeyPath $registryPath)) {
            New-RegistryKey -KeyPath $registryPath
        }
        
        # Set registry value to disable (0 = disabled, meaning CTRL+ALT+DEL required)
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        if ($policyValue -eq 0) {
            Write-Host "Group Policy setting configured successfully" -ForegroundColor Green
            Write-Host "CTRL+ALT+DEL will be required before logon via Group Policy" -ForegroundColor Green
            return [PSCustomObject]@{
                Success = $true
                Message = "Group Policy setting configured to require CTRL+ALT+DEL before logon"
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
function Invoke-InteractiveLogonDoNotRequireCtrlAltDelRemediation {
    <#
    .SYNOPSIS
        Main function to execute interactive logon CTRL+ALT+DEL requirement remediation
    .DESCRIPTION
        Performs comprehensive remediation of the interactive logon CTRL+ALT+DEL requirement setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.7.1 - Interactive Logon: Do Not Require CTRL+ALT+DEL ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'" -ForegroundColor White
        Write-Host "Rationale: Requiring CTRL+ALT+DEL before logon provides a trusted path for password communication" -ForegroundColor Gray
        Write-Host "and prevents Trojan horse attacks that mimic the Windows logon dialog box." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $disableResult = Disable-InteractiveLogonDoNotRequireCtrlAltDel
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-InteractiveLogonDoNotRequireCtrlAltDelGroupPolicy
        
        # Determine overall success
        $overallSuccess = $disableResult.Success -and $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.7.1" -Title "Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'" -PreviousValue $disableResult.PreviousValue -NewValue $disableResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Interactive logon CTRL+ALT+DEL requirement remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
        # Output detailed information
        if ($VerboseOutput) {
            Write-Host ""
            Write-Host "=== Remediation Summary ===" -ForegroundColor Cyan
            Write-Host "Registry Setting: $($disableResult.Message)" -ForegroundColor $(if ($disableResult.Success) { "Green" } else { "Red" })
            Write-Host "Group Policy: $($groupPolicyResult.Message)" -ForegroundColor $(if ($groupPolicyResult.Success) { "Green" } else { "Red" })
            Write-Host "Overall Status: $($result.Status)" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
        }
        
        return $result
    }
    catch {
        Write-Error "Interactive logon CTRL+ALT+DEL requirement remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.7.1" -Title "Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-InteractiveLogonDoNotRequireCtrlAltDelRemediation
        
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
Export-ModuleMember -Function Disable-InteractiveLogonDoNotRequireCtrlAltDel, Configure-InteractiveLogonDoNotRequireCtrlAltDelGroupPolicy, Invoke-InteractiveLogonDoNotRequireCtrlAltDelRemediation