<#
.SYNOPSIS
    CIS Remediation Script for 2.3.7.8 - Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher
.DESCRIPTION
    This script remediates the setting that determines what happens when the smart card for a logged-on user is removed from the smart card reader.
    When configured to 'Lock Workstation' or higher, the workstation automatically locks when the smart card is removed,
    ensuring that only the user with the smart card can access resources using those credentials.
.NOTES
    File Name      : 2.3.7.8-remediate-interactive-logon-smart-card-removal-behavior.ps1
    CIS ID         : 2.3.7.8
    CIS Title      : Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher
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
    Write-Host "Administrator privileges required for smart card removal behavior remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to configure smart card removal behavior
function Configure-SmartCardRemovalBehavior {
    <#
    .SYNOPSIS
        Configures the smart card removal behavior setting
    .DESCRIPTION
        Sets registry value for smart card removal behavior to 'Lock Workstation' or higher
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.7.8 - Interactive Logon: Smart Card Removal Behavior ===" -ForegroundColor Cyan
        Write-Host "Configuring smart card removal behavior setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $valueName = "ScRemoveOption"
        
        # CIS recommendation: Lock Workstation or higher (1, 2, or 3)
        # Using value 1 (Lock Workstation) as the recommended default
        $recommendedValue = 1
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is "No action" when not set
                $previousStatus = "No action"
                $previousValue = 0
            } else {
                # Map numeric values to their meanings
                switch ($currentValue) {
                    0 { $previousStatus = "No action" }
                    1 { $previousStatus = "Lock Workstation" }
                    2 { $previousStatus = "Force Logoff" }
                    3 { $previousStatus = "Disconnect if a Remote Desktop Services session" }
                    default { $previousStatus = "Unknown ($currentValue)" }
                }
                $previousValue = $currentValue
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is within CIS recommendation (1, 2, or 3)
            if ($previousValue -eq 1 -or $previousValue -eq 2 -or $previousValue -eq 3) {
                Write-Host "Current setting is already within CIS recommendation (Lock Workstation or higher)" -ForegroundColor Green
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
            
            # Map new value to its meaning
            switch ($newValue) {
                0 { $newStatus = "No action" }
                1 { $newStatus = "Lock Workstation" }
                2 { $newStatus = "Force Logoff" }
                3 { $newStatus = "Disconnect if a Remote Desktop Services session" }
                default { $newStatus = "Unknown ($newValue)" }
            }
            
            if ($newValue -eq 1 -or $newValue -eq 2 -or $newValue -eq 3) {
                Write-Host "Smart card removal behavior successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Workstation will $newStatus when smart card is removed" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Smart card removal behavior successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure smart card removal behavior within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure smart card removal behavior within CIS recommendation"
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
            
            # Map new value to its meaning
            switch ($newValue) {
                0 { $newStatus = "No action" }
                1 { $newStatus = "Lock Workstation" }
                2 { $newStatus = "Force Logoff" }
                3 { $newStatus = "Disconnect if a Remote Desktop Services session" }
                default { $newStatus = "Unknown ($newValue)" }
            }
            
            if ($newValue -eq 1 -or $newValue -eq 2 -or $newValue -eq 3) {
                Write-Host "Smart card removal behavior successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Workstation will $newStatus when smart card is removed" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Smart card removal behavior successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure smart card removal behavior within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure smart card removal behavior within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        }
    }
    catch {
        Write-Error "Failed to configure smart card removal behavior: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to configure smart card removal behavior: $_"
            RemediationApplied = $false
        }
    }
}

# Function to configure Group Policy for smart card removal behavior
function Configure-SmartCardRemovalBehaviorGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy for smart card removal behavior
    .DESCRIPTION
        Sets registry value for smart card removal behavior via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        $valueName = "ScRemoveOption"
        
        # CIS recommendation: Lock Workstation or higher (1, 2, or 3)
        # Using value 1 (Lock Workstation) as the recommended default
        $recommendedValue = 1
        
        # Ensure registry path exists
        if (-not (Test-RegistryKey -KeyPath $registryPath)) {
            New-RegistryKey -KeyPath $registryPath
        }
        
        # Check current Group Policy value
        $currentPolicyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        if ($currentPolicyValue -eq "Not Configured") {
            $previousPolicyStatus = "Not Configured"
        } else {
            # Map numeric values to their meanings
            switch ($currentPolicyValue) {
                0 { $previousPolicyStatus = "No action" }
                1 { $previousPolicyStatus = "Lock Workstation" }
                2 { $previousPolicyStatus = "Force Logoff" }
                3 { $previousPolicyStatus = "Disconnect if a Remote Desktop Services session" }
                default { $previousPolicyStatus = "Unknown ($currentPolicyValue)" }
            }
        }
        
        # Set registry value to recommended value
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        if ($policyValue -eq 1 -or $policyValue -eq 2 -or $policyValue -eq 3) {
            # Map policy value to its meaning
            switch ($policyValue) {
                1 { $policyStatus = "Lock Workstation" }
                2 { $policyStatus = "Force Logoff" }
                3 { $policyStatus = "Disconnect if a Remote Desktop Services session" }
                default { $policyStatus = "Unknown ($policyValue)" }
            }
            
            Write-Host "Group Policy setting configured successfully to $policyStatus" -ForegroundColor Green
            Write-Host "Workstation will $policyStatus when smart card is removed via Group Policy" -ForegroundColor Green
            return [PSCustomObject]@{
                Success = $true
                Message = "Group Policy setting configured to $policyStatus"
                PreviousValue = $previousPolicyStatus
                NewValue = $policyStatus
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
function Invoke-SmartCardRemovalBehaviorRemediation {
    <#
    .SYNOPSIS
        Main function to execute smart card removal behavior remediation
    .DESCRIPTION
        Performs comprehensive remediation of the smart card removal behavior setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.7.8 - Interactive Logon: Smart Card Removal Behavior ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher" -ForegroundColor White
        Write-Host "Rationale: Users sometimes forget to lock their workstations when they are away from them," -ForegroundColor Gray
        Write-Host "allowing the possibility for malicious users to access their computers. If smart cards are" -ForegroundColor Gray
        Write-Host "used for authentication, the computer should automatically lock itself when the card is" -ForegroundColor Gray
        Write-Host "removed to ensure that only the user with the smart card is accessing resources using those credentials." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $configureResult = Configure-SmartCardRemovalBehavior
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-SmartCardRemovalBehaviorGroupPolicy
        
        # Determine overall success
        $overallSuccess = $configureResult.Success -and $groupPolicyResult.Success
        
        # Determine if remediation was actually applied
        $remediationApplied = $configureResult.RemediationApplied -or $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.7.8" -Title "Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher" -PreviousValue $configureResult.PreviousValue -NewValue $configureResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Smart card removal behavior remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
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
        Write-Error "Smart card removal behavior remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.7.8" -Title "Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-SmartCardRemovalBehaviorRemediation
        
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
Export-ModuleMember -Function Configure-SmartCardRemovalBehavior, Configure-SmartCardRemovalBehaviorGroupPolicy, Invoke-SmartCardRemovalBehaviorRemediation