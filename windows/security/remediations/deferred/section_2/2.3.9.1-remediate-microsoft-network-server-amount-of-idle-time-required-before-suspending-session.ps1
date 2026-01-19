<#
.SYNOPSIS
    CIS Remediation Script for 2.3.9.1 - Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'
.DESCRIPTION
    This script remediates the setting that controls the amount of continuous idle time that must pass
    in an SMB session before the session is suspended because of inactivity.
    The recommended value is 15 or fewer minutes to prevent resource exhaustion from numerous null sessions.
.NOTES
    File Name      : 2.3.9.1-remediate-microsoft-network-server-amount-of-idle-time-required-before-suspending-session.ps1
    CIS ID         : 2.3.9.1
    CIS Title      : Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'
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
    Write-Host "Administrator privileges required for Microsoft network server amount of idle time required before suspending session remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to configure Microsoft network server amount of idle time required before suspending session
function Configure-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSession {
    <#
    .SYNOPSIS
        Configures the Microsoft network server amount of idle time required before suspending session setting
    .DESCRIPTION
        Sets registry value to suspend SMB sessions after 15 or fewer minutes of inactivity
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.9.1 - Microsoft Network Server: Amount of Idle Time Required Before Suspending Session ===" -ForegroundColor Cyan
        Write-Host "Configuring Microsoft network server amount of idle time required before suspending session setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "AutoDisconnect"
        
        # CIS recommendation: 15 or fewer minutes (15 or less)
        $recommendedValue = 15
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is "15 minutes" when not set according to JSON
                $previousStatus = "15 minutes"
                $previousValue = 15
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                $previousStatus = "$currentValueInt minute(s)"
                $previousValue = $currentValueInt
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is within CIS recommendation (15 or fewer)
            if ($previousValue -le 15) {
                Write-Host "Current setting is already within CIS recommendation (15 or fewer minutes)" -ForegroundColor Green
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
            $newStatus = "$newValueInt minute(s)"
            
            if ($newValueInt -le 15) {
                Write-Host "Microsoft network server amount of idle time required before suspending session successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SMB sessions will be suspended after $newValueInt minutes of inactivity" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server amount of idle time required before suspending session successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server amount of idle time required before suspending session within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server amount of idle time required before suspending session within CIS recommendation"
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
            $newStatus = "$newValueInt minute(s)"
            
            if ($newValueInt -le 15) {
                Write-Host "Microsoft network server amount of idle time required before suspending session successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SMB sessions will be suspended after $newValueInt minutes of inactivity" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server amount of idle time required before suspending session successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server amount of idle time required before suspending session within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server amount of idle time required before suspending session within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        }
    }
    catch {
        Write-Error "Failed to configure Microsoft network server amount of idle time required before suspending session: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to configure Microsoft network server amount of idle time required before suspending session: $_"
            RemediationApplied = $false
        }
    }
}

# Function to configure Group Policy for Microsoft network server amount of idle time required before suspending session
function Configure-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy for Microsoft network server amount of idle time required before suspending session
    .DESCRIPTION
        Sets registry value to suspend SMB sessions after 15 or fewer minutes of inactivity via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanServer"
        $valueName = "AutoDisconnect"
        
        # CIS recommendation: 15 or fewer minutes (15 or less)
        $recommendedValue = 15
        
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
            $previousPolicyStatus = "$currentPolicyValueInt minute(s)"
        }
        
        # Set registry value to recommended value
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        # Convert to integer for comparison
        $policyValueInt = [int]$policyValue
        
        if ($policyValueInt -le 15) {
            $policyStatus = "$policyValueInt minute(s)"
            
            Write-Host "Group Policy setting configured successfully to $policyStatus" -ForegroundColor Green
            Write-Host "SMB sessions will be suspended after $policyValueInt minutes of inactivity via Group Policy" -ForegroundColor Green
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
function Invoke-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionRemediation {
    <#
    .SYNOPSIS
        Main function to execute Microsoft network server amount of idle time required before suspending session remediation
    .DESCRIPTION
        Performs comprehensive remediation of the Microsoft network server amount of idle time required before suspending session setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.9.1 - Microsoft Network Server: Amount of Idle Time Required Before Suspending Session ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'" -ForegroundColor White
        Write-Host "Rationale: Each SMB session consumes server resources, and numerous null sessions will slow" -ForegroundColor Gray
        Write-Host "the server or possibly cause it to fail. An attacker could repeatedly establish SMB" -ForegroundColor Gray
        Write-Host "sessions until the server's SMB services become slow or unresponsive." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $configureResult = Configure-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSession
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionGroupPolicy
        
        # Determine overall success
        $overallSuccess = $configureResult.Success -and $groupPolicyResult.Success
        
        # Determine if remediation was actually applied
        $remediationApplied = $configureResult.RemediationApplied -or $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.9.1" -Title "Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'" -PreviousValue $configureResult.PreviousValue -NewValue $configureResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Microsoft network server amount of idle time required before suspending session remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
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
        Write-Error "Microsoft network server amount of idle time required before suspending session remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.9.1" -Title "Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionRemediation
        
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
Export-ModuleMember -Function Configure-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSession, Configure-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionGroupPolicy, Invoke-MicrosoftNetworkServerAmountOfIdleTimeRequiredBeforeSuspendingSessionRemediation