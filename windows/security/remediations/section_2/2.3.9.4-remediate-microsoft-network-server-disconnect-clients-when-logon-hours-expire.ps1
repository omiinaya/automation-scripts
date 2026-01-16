<#
.SYNOPSIS
    CIS Remediation Script for 2.3.9.4 - Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'
.DESCRIPTION
    This script remediates the setting that determines whether to disconnect users who are connected to the
    local computer outside their user account's valid logon hours. This setting affects the Server Message
    Block (SMB) component. If enabled, users will be disconnected when their logon hours expire.
.NOTES
    File Name      : 2.3.9.4-remediate-microsoft-network-server-disconnect-clients-when-logon-hours-expire.ps1
    CIS ID         : 2.3.9.4
    CIS Title      : Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'
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
    Write-Host "Administrator privileges required for Microsoft network server disconnect clients when logon hours expire remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to configure Microsoft network server disconnect clients when logon hours expire
function Configure-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpire {
    <#
    .SYNOPSIS
        Configures the Microsoft network server disconnect clients when logon hours expire setting
    .DESCRIPTION
        Sets registry value to enable disconnecting clients when logon hours expire
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.9.4 - Microsoft Network Server: Disconnect Clients When Logon Hours Expire ===" -ForegroundColor Cyan
        Write-Host "Configuring Microsoft network server disconnect clients when logon hours expire setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "enableforcedlogoff"
        
        # CIS recommendation: Enabled (value = 1)
        $recommendedValue = 1
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is "Enabled" when not set according to JSON
                $previousStatus = "Enabled"
                $previousValue = 1
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                $previousStatus = if ($currentValueInt -eq 1) { "Enabled" } else { "Disabled" }
                $previousValue = $currentValueInt
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is already compliant (Enabled = 1)
            if ($previousValue -eq 1) {
                Write-Host "Current setting is already compliant with CIS recommendation (Enabled)" -ForegroundColor Green
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
            
            # Convert to integer for comparison
            $newValueInt = [int]$newValue
            $newStatus = if ($newValueInt -eq 1) { "Enabled" } else { "Disabled" }
            
            if ($newValueInt -eq 1) {
                Write-Host "Microsoft network server disconnect clients when logon hours expire successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Clients will be disconnected when their logon hours expire" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server disconnect clients when logon hours expire successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server disconnect clients when logon hours expire to Enabled" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server disconnect clients when logon hours expire to Enabled"
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
            
            # Convert to integer for comparison
            $newValueInt = [int]$newValue
            $newStatus = if ($newValueInt -eq 1) { "Enabled" } else { "Disabled" }
            
            if ($newValueInt -eq 1) {
                Write-Host "Microsoft network server disconnect clients when logon hours expire successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Clients will be disconnected when their logon hours expire" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server disconnect clients when logon hours expire successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server disconnect clients when logon hours expire to Enabled" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server disconnect clients when logon hours expire to Enabled"
                    RemediationApplied = $true
                }
            }
        }
    }
    catch {
        Write-Error "Failed to configure Microsoft network server disconnect clients when logon hours expire: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to configure Microsoft network server disconnect clients when logon hours expire: $_"
            RemediationApplied = $false
        }
    }
}

# Function to configure Group Policy for Microsoft network server disconnect clients when logon hours expire
function Configure-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy for Microsoft network server disconnect clients when logon hours expire
    .DESCRIPTION
        Sets registry value to enable disconnecting clients when logon hours expire via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanServer"
        $valueName = "enableforcedlogoff"
        
        # CIS recommendation: Enabled (value = 1)
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
            # Convert to integer for comparison
            $currentPolicyValueInt = [int]$currentPolicyValue
            $previousPolicyStatus = if ($currentPolicyValueInt -eq 1) { "Enabled" } else { "Disabled" }
        }
        
        # Set registry value to recommended value
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        # Convert to integer for comparison
        $policyValueInt = [int]$policyValue
        
        if ($policyValueInt -eq 1) {
            $policyStatus = "Enabled"
            
            Write-Host "Group Policy setting configured successfully to $policyStatus" -ForegroundColor Green
            Write-Host "Clients will be disconnected when their logon hours expire via Group Policy" -ForegroundColor Green
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
function Invoke-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireRemediation {
    <#
    .SYNOPSIS
        Main function to execute Microsoft network server disconnect clients when logon hours expire remediation
    .DESCRIPTION
        Performs comprehensive remediation of the Microsoft network server disconnect clients when logon hours expire setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.9.4 - Microsoft Network Server: Disconnect Clients When Logon Hours Expire ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'" -ForegroundColor White
        Write-Host "Rationale: If your organization configures logon hours for users, then it makes sense to enable this" -ForegroundColor Gray
        Write-Host "policy setting. Otherwise, users who should not have access to network resources" -ForegroundColor Gray
        Write-Host "outside of their logon hours may actually be able to continue to use those resources" -ForegroundColor Gray
        Write-Host "with sessions that were established during allowed hours." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $configureResult = Configure-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpire
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireGroupPolicy
        
        # Determine overall success
        $overallSuccess = $configureResult.Success -and $groupPolicyResult.Success
        
        # Determine if remediation was actually applied
        $remediationApplied = $configureResult.RemediationApplied -or $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.9.4" -Title "Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'" -PreviousValue $configureResult.PreviousValue -NewValue $configureResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Microsoft network server disconnect clients when logon hours expire remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
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
        Write-Error "Microsoft network server disconnect clients when logon hours expire remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.9.4" -Title "Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireRemediation
        
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
Export-ModuleMember -Function Configure-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpire, Configure-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireGroupPolicy, Invoke-MicrosoftNetworkServerDisconnectClientsWhenLogonHoursExpireRemediation