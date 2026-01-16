<#
.SYNOPSIS
    Remediates CIS control 19.7.5.2 - Notify antivirus programs when opening attachments
.DESCRIPTION
    This script remediates the antivirus notification setting to comply with CIS recommendations.
.NOTES
    CIS ID: 19.7.5.2
    Profile: L1
    File Name: 19.7.5.2-remediate-notify-antivirus-programs-when-opening-attachments.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force -WarningAction SilentlyContinue

# Get CIS recommendation
$cisId = "19.7.5.2"
$recommendation = Get-CISRecommendation -CIS_ID $cisId -Section "19"

if (-not $recommendation) {
    Write-Error "CIS recommendation '$cisId' not found"
    exit 1
}

Write-Host ""
Write-SectionHeader -Title "CIS Remediation: $cisId"
Write-Host "Setting: $($recommendation.title)" -ForegroundColor White
Write-Host "Profile: $($recommendation.profile)" -ForegroundColor White
Write-Host ""

# Remediate antivirus notification setting
# This setting is stored in user registry hive: HKU\[USER SID]\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments
# The value name is: ScanWithAntiVirus
# Expected value: 3 (Enabled)

try {
    # Get current user SID
    $currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    
    # Construct registry path
    $registryPath = "Registry::HKEY_USERS\$currentUserSid\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments"
    $valueName = "ScanWithAntiVirus"
    $expectedValue = 3
    
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
            $result = New-CISRemediationResult -CIS_ID $cisId -Title $recommendation.title -PreviousValue $previousValue -NewValue $expectedValue -Status "Remediated" -Message "Antivirus notification successfully enabled" -IsCompliant $true -RequiresManualAction $false -Source "Registry"
        } else {
            $result = New-CISRemediationResult -CIS_ID $cisId -Title $recommendation.title -PreviousValue $previousValue -NewValue "Unknown" -Status "Failed" -Message "Failed to set registry value" -IsCompliant $false -RequiresManualAction $true -Source "Registry"
        }
    }
} catch {
    $result = New-CISRemediationResult -CIS_ID $cisId -Title $recommendation.title -PreviousValue "Unknown" -NewValue "Unknown" -Status "Error" -Message "Remediation failed: $_" -IsCompliant $false -RequiresManualAction $true -ErrorMessage $_
}

# Output results
Write-Host "Previous Value: $($result.PreviousValue)" -ForegroundColor White
Write-Host "New Value: $($result.NewValue)" -ForegroundColor White
Write-Host "Status: $($result.Status)" -ForegroundColor $(if ($result.IsCompliant) { "Green" } else { "Red" })
Write-Host "Message: $($result.Message)" -ForegroundColor White
Write-Host "Source: $($result.Source)" -ForegroundColor White

# Return the result object
return $result