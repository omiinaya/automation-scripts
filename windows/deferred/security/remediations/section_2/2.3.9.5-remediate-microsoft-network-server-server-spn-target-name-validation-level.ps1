<#
.SYNOPSIS
    CIS Remediation Script for 2.3.9.5 - Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher
.DESCRIPTION
    This script remediates the setting that controls the level of validation a computer with shared folders or
    printers performs on the service principal name (SPN) that is provided by the client computer when
    it establishes a session using the server message block (SMB) protocol.
.NOTES
    File Name      : 2.3.9.5-remediate-microsoft-network-server-server-spn-target-name-validation-level.ps1
    CIS ID         : 2.3.9.5
    CIS Title      : Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher
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
    Write-Host "Administrator privileges required for Microsoft network server server SPN target name validation level remediation." -ForegroundColor Yellow
    Write-Host "Attempting to elevate privileges..." -ForegroundColor White
    
    # Relaunch script with elevated privileges
    $arguments = "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($VerboseOutput) {
        $arguments += " -Verbose"
    }
    
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

# Function to configure Microsoft network server server SPN target name validation level
function Configure-MicrosoftNetworkServerServerSPNTargetNameValidationLevel {
    <#
    .SYNOPSIS
        Configures the Microsoft network server server SPN target name validation level setting
    .DESCRIPTION
        Sets registry value to enable SPN target name validation level to 'Accept if provided by client' or higher
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.9.5 - Microsoft Network Server: Server SPN Target Name Validation Level ===" -ForegroundColor Cyan
        Write-Host "Configuring Microsoft network server server SPN target name validation level setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "SMBServerNameHardeningLevel"
        
        # CIS recommendation: Accept if provided by client (value = 1) or Required from client (value = 2)
        $recommendedValue = 1  # Default to Accept if provided by client
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is "Off" when not set according to JSON
                $previousStatus = "Off"
                $previousValue = 0
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                
                # Map values to descriptive names
                switch ($currentValueInt) {
                    0 { $previousStatus = "Off" }
                    1 { $previousStatus = "Accept if provided by client" }
                    2 { $previousStatus = "Required from client" }
                    default { $previousStatus = "Unknown ($currentValueInt)" }
                }
                $previousValue = $currentValueInt
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is already compliant (1 or 2)
            if ($previousValue -eq 1 -or $previousValue -eq 2) {
                Write-Host "Current setting is already compliant with CIS recommendation" -ForegroundColor Green
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
            
            # Map values to descriptive names
            switch ($newValueInt) {
                0 { $newStatus = "Off" }
                1 { $newStatus = "Accept if provided by client" }
                2 { $newStatus = "Required from client" }
                default { $newStatus = "Unknown ($newValueInt)" }
            }
            
            if ($newValueInt -eq 1 -or $newValueInt -eq 2) {
                Write-Host "Microsoft network server server SPN target name validation level successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SPN target name validation level set to $newStatus" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server server SPN target name validation level successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server server SPN target name validation level to compliant value" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server server SPN target name validation level to compliant value"
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
            
            # Map values to descriptive names
            switch ($newValueInt) {
                0 { $newStatus = "Off" }
                1 { $newStatus = "Accept if provided by client" }
                2 { $newStatus = "Required from client" }
                default { $newStatus = "Unknown ($newValueInt)" }
            }
            
            if ($newValueInt -eq 1 -or $newValueInt -eq 2) {
                Write-Host "Microsoft network server server SPN target name validation level successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SPN target name validation level set to $newStatus" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server server SPN target name validation level successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server server SPN target name validation level to compliant value" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server server SPN target name validation level to compliant value"
                    RemediationApplied = $true
                }
            }
        }
    }
    catch {
        Write-Error "Failed to configure Microsoft network server server SPN target name validation level: $_"
        return [PSCustomObject]@{
            PreviousValue = "Error"
            NewValue = "Error"
            Success = $false
            Message = "Failed to configure Microsoft network server server SPN target name validation level: $_"
            RemediationApplied = $false
        }
    }
}

# Function to configure Group Policy for Microsoft network server server SPN target name validation level
function Configure-MicrosoftNetworkServerServerSPNTargetNameValidationLevelGroupPolicy {
    <#
    .SYNOPSIS
        Configures Group Policy for Microsoft network server server SPN target name validation level
    .DESCRIPTION
        Sets registry value to enable SPN target name validation level via Group Policy
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "Configuring Group Policy setting..." -ForegroundColor White
        
        # Group Policy registry path
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanServer"
        $valueName = "SMBServerNameHardeningLevel"
        
        # CIS recommendation: Accept if provided by client (value = 1) or Required from client (value = 2)
        $recommendedValue = 1  # Default to Accept if provided by client
        
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
            
            # Map values to descriptive names
            switch ($currentPolicyValueInt) {
                0 { $previousPolicyStatus = "Off" }
                1 { $previousPolicyStatus = "Accept if provided by client" }
                2 { $previousPolicyStatus = "Required from client" }
                default { $previousPolicyStatus = "Unknown ($currentPolicyValueInt)" }
            }
        }
        
        # Set registry value to recommended value
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
        
        # Verify the setting
        $policyValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Configured"
        
        # Convert to integer for comparison
        $policyValueInt = [int]$policyValue
        
        if ($policyValueInt -eq 1 -or $policyValueInt -eq 2) {
            # Map values to descriptive names
            switch ($policyValueInt) {
                0 { $policyStatus = "Off" }
                1 { $policyStatus = "Accept if provided by client" }
                2 { $policyStatus = "Required from client" }
                default { $policyStatus = "Unknown ($policyValueInt)" }
            }
            
            Write-Host "Group Policy setting configured successfully to $policyStatus" -ForegroundColor Green
            Write-Host "SPN target name validation level set to $policyStatus via Group Policy" -ForegroundColor Green
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
function Invoke-MicrosoftNetworkServerServerSPNTargetNameValidationLevelRemediation {
    <#
    .SYNOPSIS
        Main function to execute Microsoft network server server SPN target name validation level remediation
    .DESCRIPTION
        Performs comprehensive remediation of the Microsoft network server server SPN target name validation level setting
    .OUTPUTS
        PSCustomObject
    #>
    
    try {
        Write-Host ""
        Write-Host "=== CIS Remediation 2.3.9.5 - Microsoft Network Server: Server SPN Target Name Validation Level ===" -ForegroundColor Cyan
        Write-Host "CIS Recommendation: Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher" -ForegroundColor White
        Write-Host "Rationale: The identity of a computer can be spoofed to gain unauthorized access to network resources." -ForegroundColor Gray
        Write-Host ""
        
        # Perform main remediation
        $configureResult = Configure-MicrosoftNetworkServerServerSPNTargetNameValidationLevel
        
        # Configure Group Policy setting
        $groupPolicyResult = Configure-MicrosoftNetworkServerServerSPNTargetNameValidationLevelGroupPolicy
        
        # Determine overall success
        $overallSuccess = $configureResult.Success -and $groupPolicyResult.Success
        
        # Determine if remediation was actually applied
        $remediationApplied = $configureResult.RemediationApplied -or $groupPolicyResult.Success
        
        # Create remediation result
        $result = New-CISRemediationResult -CIS_ID "2.3.9.5" -Title "Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher" -PreviousValue $configureResult.PreviousValue -NewValue $configureResult.NewValue -Status $(if ($overallSuccess) { "Remediated" } else { "PartiallyRemediated" }) -Message "Microsoft network server server SPN target name validation level remediation completed" -IsCompliant $overallSuccess -RequiresManualAction $false -Source "Registry"
        
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
        Write-Error "Microsoft network server server SPN target name validation level remediation failed: $_"
        return New-CISRemediationResult -CIS_ID "2.3.9.5" -Title "Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher" -PreviousValue "Error" -NewValue "Error" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
    }
}

# Execute remediation if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    try {
        $remediationResult = Invoke-MicrosoftNetworkServerServerSPNTargetNameValidationLevelRemediation
        
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
Export-ModuleMember -Function Configure-MicrosoftNetworkServerServerSPNTargetNameValidationLevel, Configure-MicrosoftNetworkServerServerSPNTargetNameValidationLevelGroupPolicy, Invoke-MicrosoftNetworkServerServerSPNTargetNameValidationLevelRemediation