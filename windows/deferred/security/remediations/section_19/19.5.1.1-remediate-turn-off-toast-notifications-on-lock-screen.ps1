# Remediation: Turn off toast notifications on lock screen
# CIS Benchmark: 19.5.1.1 (L1) Ensure 'Turn off toast notifications on lock screen' is set to 'Enabled'

[CmdletBinding()]
param()

# Import ScriptTemplates module
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Remediation-specific logic: Configure toast notifications on lock screen
$remediationBlock = {
    # Get CIS recommendation
    $cisId = "19.5.1.1"
    $recommendation = Get-CISRecommendation -CIS_ID $cisId -Section "19"
    
    if (-not $recommendation) {
        throw "CIS recommendation '$cisId' not found"
    }
    
    # Get current user SID and construct registry path
    $currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $registryPath = "Registry::HKEY_USERS\$currentUserSid\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
    $valueName = "NoToastApplicationNotificationOnLockScreen"
    $expectedValue = 1
    
    # Check current value
    $previousValue = "Not Configured"
    if (Test-Path $registryPath) {
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        if ($currentValue -and $currentValue.$valueName -eq $expectedValue) {
            return New-CISRemediationResult -CIS_ID $cisId -Title $recommendation.title -PreviousValue "Already Compliant" -NewValue $expectedValue -Status "Remediated" -Message "Setting is already compliant" -IsCompliant $true -RequiresManualAction $false -Source "Registry"
        } else {
            $previousValue = $currentValue.$valueName
        }
    }
    
    # If not compliant, remediate
    if ($previousValue -ne "Already Compliant") {
        # Create registry key if it doesn't exist
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }
        
        # Set the registry value
        Set-ItemProperty -Path $registryPath -Name $valueName -Value $expectedValue -Type DWord -Force
        
        # Verify the change
        $newValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        
        if ($newValue.$valueName -eq $expectedValue) {
            return New-CISRemediationResult -CIS_ID $cisId -Title $recommendation.title -PreviousValue $previousValue -NewValue $expectedValue -Status "Remediated" -Message "Toast notifications on lock screen successfully disabled" -IsCompliant $true -RequiresManualAction $false -Source "Registry"
        } else {
            return New-CISRemediationResult -CIS_ID $cisId -Title $recommendation.title -PreviousValue $previousValue -NewValue "Unknown" -Status "Failed" -Message "Failed to set registry value" -IsCompliant $false -RequiresManualAction $true -Source "Registry"
        }
    }
}

# Execute remediation using template function
Invoke-CISRemediationScript -ScriptRoot $PSScriptRoot -RemediationBlock $remediationBlock
