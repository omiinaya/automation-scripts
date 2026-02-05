# Remediation: 19.7.8.1
# CIS Benchmark: 19.7.8.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
# Get current user SID
    $currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    
    # Construct registry path
    $registryPath = "Registry::HKEY_USERS\$currentUserSid\Software\Policies\Microsoft\Windows\CloudContent"
    $valueName = "ConfigureWindowsSpotlight"
    $expectedValue = 2
    
    # Check current value
    $previousValue = "Not Configured"
    if (Test-Path $registryPath) {
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        if ($currentValue -and $currentValue.$valueName -eq $expectedValue) {
            $result = New-CISRemediationResult -CIS_ID $cisId -Title $recommendation.title -PreviousValue "Already Compliant" -NewValue $expectedValue -Status "Remediated" -Message "Setting is already compliant" -IsCompliant $true -RequiresManualAction $false -Source "Registry"
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
            $result = New-CISRemediationResult -CIS_ID $cisId -Title $recommendation.title -PreviousValue $previousValue -NewValue $expectedValue -Status "Remediated" -Message "Windows Spotlight on lock screen successfully disabled" -IsCompliant $true -RequiresManualAction $false -Source "Registry"
        } else {
            $result = New-CISRemediationResult -CIS_ID $cisId -Title $recommendation.title -PreviousValue $previousValue -NewValue "Unknown" -Status "Failed" -Message "Failed to set registry value" -IsCompliant $false -RequiresManualAction $true -Source "Registry"
        }
    }
} catch {
    $result = New-CISRemediationResult -CIS_ID $cisId -Title $recommendation.title -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
}
