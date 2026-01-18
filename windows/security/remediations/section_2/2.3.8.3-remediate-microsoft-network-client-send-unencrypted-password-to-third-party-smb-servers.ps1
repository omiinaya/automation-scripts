<#
.SYNOPSIS
    CIS Remediation Script for 2.3.8.3 - Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'
.DESCRIPTION
    This script remediates the setting that determines whether the SMB redirector will send plaintext passwords
    during authentication to third-party SMB servers that do not support password encryption.
    When disabled, unencrypted passwords are not allowed across the network, preventing password interception.
.NOTES
    File Name      : 2.3.8.3-remediate-microsoft-network-client-send-unencrypted-password-to-third-party-smb-servers.ps1
    CIS ID         : 2.3.8.3
    CIS Title      : Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'
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
    Write-Host "Administrator privileges required for Microsoft network client send unencrypted password to third-party SMB servers remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to configure Microsoft network client send unencrypted password to third-party SMB servers
function Configure-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServers {
    <#
    .SYNOPSIS
        Configures the Microsoft network client send unencrypted password to third-party SMB servers setting
    .DESCRIPTION
        Sets registry value to disable sending unencrypted passwords to third-party SMB servers
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.8.3 - Microsoft Network Client: Send Unencrypted Password to Third-Party SMB Servers ===" -ForegroundColor Cyan
        Write-Host "Configuring Microsoft network client send unencrypted password to third-party SMB servers setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
        $valueName = "EnablePlainTextPassword"
        
        # CIS recommendation: Disabled (0)
        $recommendedValue = 0
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is "Disabled" when not set according to JSON
                $previousStatus = "Disabled"
                $previousValue = 0
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
            
            # Check if current value is within CIS recommendation (0)
            if ($previousValue -eq 0) {
                Write-Host "Current setting is already within CIS recommendation (Disabled)" -ForegroundColor Green
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
            
            if ($newValue -eq 0) {
                Write-Host "Microsoft network client send unencrypted password to third-party SMB servers successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Plaintext passwords will not be sent to third-party SMB servers" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network client send unencrypted password to third-party SMB servers successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network client send unencrypted password to third-party SMB servers within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network client send unencrypted password to third-party SMB servers within CIS recommendation"
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
            
            if ($newValue -eq 0) {
                Write-Host "Microsoft network client send unencrypted password to third-party SMB servers successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Plaintext passwords will not be sent to third-party SMB servers" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network client send unencrypted password to third-party SMB servers successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network client send unencrypted password to third-party SMB servers within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network client send unencrypted password to third-party SMB servers within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        }
    }
    catch {
        Write-Error "Failed to configure Microsoft network client send unencrypted password to third-party SMB servers: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to configure Microsoft network client send unencrypted password to third-party SMB servers: $_"
            RemediationApplied = $false
        }
    }
}

# Function to configure Group Policy for Microsoft network client send unencrypted password to third-party SMB servers
function Configure-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy for Microsoft network client send unencrypted password to third-party SMB servers
    .DESCRIPTION
        Sets registry value to disable sending unencrypted passwords to third-party SMB servers via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
        $valueName = "EnablePlainTextPassword"
        
        # CIS recommendation: Disabled (0)
        $recommendedValue = 0
        
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
        
        if ($policyValue -eq 0) {
            $policyStatus = "Disabled"
            
            Write-Host "Group Policy setting configured successfully to $policyStatus" -ForegroundColor Green
            Write-Host "Plaintext passwords will not be sent to third-party SMB servers via Group Policy" -ForegroundColor Green
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
function Invoke-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersRemediation {
    <#
    .SYNOPSIS
        Main function to execute Microsoft network client send unencrypted password to third-party SMB servers remediation
    .DESCRIPTION
        Performs comprehensive remediation of the Microsoft network client send unencrypted password to third-party SMB servers setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.8.3 - Microsoft Network Client: Send Unencrypted Password to Third-Party SMB Servers ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'" -ForegroundColor White
        Write-Host "Rationale: If you enable this policy setting, the server can transmit passwords in plaintext across" -ForegroundColor Gray
        Write-Host "the network to other computers that offer SMB services, which is a significant security" -ForegroundColor Gray
        Write-Host "risk. These other computers may not use any of the SMB security mechanisms that are" -ForegroundColor Gray
        Write-Host "included with Windows Server 2003." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $configureResult = Configure-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServers
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersGroupPolicy
        
        # Determine overall success
        $overallSuccess = $configureResult.Success -and $groupPolicyResult.Success
        
        # Determine if remediation was actually applied
        $remediationApplied = $configureResult.RemediationApplied -or $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.8.3" -Title "Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'" -PreviousValue $configureResult.PreviousValue -NewValue $configureResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Microsoft network client send unencrypted password to third-party SMB servers remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
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
        Write-Error "Microsoft network client send unencrypted password to third-party SMB servers remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.8.3" -Title "Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersRemediation
        
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
Export-ModuleMember -Function Configure-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServers, Configure-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersGroupPolicy, Invoke-MicrosoftNetworkClientSendUnencryptedPasswordToThirdPartySMBServersRemediation