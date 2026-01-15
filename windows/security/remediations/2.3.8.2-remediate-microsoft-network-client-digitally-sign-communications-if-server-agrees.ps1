<#
.SYNOPSIS
    CIS Remediation Script for 2.3.8.2 - Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'
.DESCRIPTION
    This script remediates the setting that determines whether the SMB client will attempt to negotiate SMB packet signing.
    When enabled, the SMB client will negotiate packet signing with servers that support it, providing mutual authentication
    and preventing session hijacking attacks and man-in-the-middle attacks.
.NOTES
    File Name      : 2.3.8.2-remediate-microsoft-network-client-digitally-sign-communications-if-server-agrees.ps1
    CIS ID         : 2.3.8.2
    CIS Title      : Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'
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
    Write-Host "Administrator privileges required for Microsoft network client digitally sign communications (if server agrees) remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to configure Microsoft network client digitally sign communications (if server agrees)
function Configure-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgrees {
    <#
    .SYNOPSIS
        Configures the Microsoft network client digitally sign communications (if server agrees) setting
    .DESCRIPTION
        Sets registry value to negotiate SMB packet signing when server agrees
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.8.2 - Microsoft Network Client: Digitally Sign Communications (If Server Agrees) ===" -ForegroundColor Cyan
        Write-Host "Configuring Microsoft network client digitally sign communications (if server agrees) setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
        $valueName = "EnableSecuritySignature"
        
        # CIS recommendation: Enabled (1)
        $recommendedValue = 1
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is "Enabled" when not set according to JSON
                $previousStatus = "Enabled"
                $previousValue = 1
            } else {
                # Map numeric values to their meanings
                switch ($currentValue) {
                    0 { $previousStatus = "Disabled" }
                    1 { $previousStatus = "Enabled" }
                    default { $previousStatus = "Unknown ($currentValue)" }
                }
                $previousValue = $currentValue
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is within CIS recommendation (1)
            if ($previousValue -eq 1) {
                Write-Host "Current setting is already within CIS recommendation (Enabled)" -ForegroundColor Green
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
                0 { $newStatus = "Disabled" }
                1 { $newStatus = "Enabled" }
                default { $newStatus = "Unknown ($newValue)" }
            }
            
            if ($newValue -eq 1) {
                Write-Host "Microsoft network client digitally sign communications (if server agrees) successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SMB packet signing will now be negotiated when server agrees" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network client digitally sign communications (if server agrees) successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network client digitally sign communications (if server agrees) within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network client digitally sign communications (if server agrees) within CIS recommendation"
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
                0 { $newStatus = "Disabled" }
                1 { $newStatus = "Enabled" }
                default { $newStatus = "Unknown ($newValue)" }
            }
            
            if ($newValue -eq 1) {
                Write-Host "Microsoft network client digitally sign communications (if server agrees) successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SMB packet signing will now be negotiated when server agrees" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network client digitally sign communications (if server agrees) successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network client digitally sign communications (if server agrees) within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network client digitally sign communications (if server agrees) within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        }
    }
    catch {
        Write-Error "Failed to configure Microsoft network client digitally sign communications (if server agrees): $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to configure Microsoft network client digitally sign communications (if server agrees): $_"
            RemediationApplied = $false
        }
    }
}

# Function to configure Group Policy for Microsoft network client digitally sign communications (if server agrees)
function Configure-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy for Microsoft network client digitally sign communications (if server agrees)
    .DESCRIPTION
        Sets registry value to negotiate SMB packet signing when server agrees via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
        $valueName = "EnableSecuritySignature"
        
        # CIS recommendation: Enabled (1)
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
                0 { $previousPolicyStatus = "Disabled" }
                1 { $previousPolicyStatus = "Enabled" }
                default { $previousPolicyStatus = "Unknown ($currentPolicyValue)" }
            }
        }
        
        # Set registry value to recommended value
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        if ($policyValue -eq 1) {
            $policyStatus = "Enabled"
            
            Write-Host "Group Policy setting configured successfully to $policyStatus" -ForegroundColor Green
            Write-Host "SMB packet signing will be negotiated when server agrees via Group Policy" -ForegroundColor Green
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
function Invoke-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesRemediation {
    <#
    .SYNOPSIS
        Main function to execute Microsoft network client digitally sign communications (if server agrees) remediation
    .DESCRIPTION
        Performs comprehensive remediation of the Microsoft network client digitally sign communications (if server agrees) setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.8.2 - Microsoft Network Client: Digitally Sign Communications (If Server Agrees) ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'" -ForegroundColor White
        Write-Host "Rationale: Session hijacking uses tools that allow attackers who have access to the same network" -ForegroundColor Gray
        Write-Host "as the client or server to interrupt, end, or steal a session in progress. Attackers can" -ForegroundColor Gray
        Write-Host "potentially intercept and modify unsigned SMB packets and then modify the traffic and" -ForegroundColor Gray
        Write-Host "forward it so that the server might perform undesirable actions. Alternatively, the" -ForegroundColor Gray
        Write-Host "attacker could pose as the server or client after legitimate authentication and gain" -ForegroundColor Gray
        Write-Host "unauthorized access to data." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $configureResult = Configure-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgrees
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesGroupPolicy
        
        # Determine overall success
        $overallSuccess = $configureResult.Success -and $groupPolicyResult.Success
        
        # Determine if remediation was actually applied
        $remediationApplied = $configureResult.RemediationApplied -or $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.8.2" -Title "Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'" -PreviousValue $configureResult.PreviousValue -NewValue $configureResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Microsoft network client digitally sign communications (if server agrees) remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
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
        Write-Error "Microsoft network client digitally sign communications (if server agrees) remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.8.2" -Title "Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesRemediation
        
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
Export-ModuleMember -Function Configure-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgrees, Configure-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesGroupPolicy, Invoke-MicrosoftNetworkClientDigitallySignCommunicationsIfServerAgreesRemediation