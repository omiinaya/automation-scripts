<#
.SYNOPSIS
    Audits CIS control 19.5.1.1 - Turn off toast notifications on the lock screen
.DESCRIPTION
    This script audits whether toast notifications are disabled on the lock screen as recommended by CIS.
.NOTES
    CIS ID: 19.5.1.1
    Profile: L1
    File Name: 19.5.1.1-audit-turn-off-toast-notifications-on-lock-screen.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# Get CIS recommendation
$cisId = "19.5.1.1"
$recommendation = Get-CISRecommendation -CIS_ID $cisId -Section "19"

if (-not $recommendation) {
    Write-Error "CIS recommendation '$cisId' not found"
    exit 1
}

Write-Host ""
Write-SectionHeader -Title "CIS Audit: $cisId"
Write-Host "Setting: $($recommendation.title)" -ForegroundColor White
Write-Host "Profile: $($recommendation.profile)" -ForegroundColor White
Write-Host ""

# Audit toast notifications on lock screen setting
# This setting is stored in user registry hive: HKU\[USER SID]\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications
# The value name is: NoToastApplicationNotificationOnLockScreen
# Expected value: 1 (Enabled)

try {
    # Get current user SID
    $currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    
    # Construct registry path
    $registryPath = "Registry::HKEY_USERS\$currentUserSid\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
    $valueName = "NoToastApplicationNotificationOnLockScreen"
    
    # Check if registry key exists
    if (Test-Path $registryPath) {
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        
        if ($currentValue -and $currentValue.$valueName -eq 1) {
            $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Enabled (1)" -RecommendedValue "Enabled" -ComplianceStatus "Compliant" -Source "Registry" -Details "Toast notifications are disabled on lock screen" -Profile $recommendation.profile
        } else {
            $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Disabled or Not Configured" -RecommendedValue "Enabled" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details "Toast notifications are enabled on lock screen" -Profile $recommendation.profile
        }
    } else {
        $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Not Configured" -RecommendedValue "Enabled" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details "Registry key does not exist" -Profile $recommendation.profile
    }
} catch {
    $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Error" -RecommendedValue "Enabled" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile $recommendation.profile
}

# Output results
Write-Host "Current Value: $($result.CurrentValue)" -ForegroundColor White
Write-Host "Recommended: $($result.RecommendedValue)" -ForegroundColor White
Write-Host "Compliance: $($result.ComplianceStatus)" -ForegroundColor $(if ($result.IsCompliant) { "Green" } else { "Red" })
Write-Host "Source: $($result.Source)" -ForegroundColor White
if ($result.Details) {
    Write-Host "Details: $($result.Details)" -ForegroundColor Gray
}

# Return the result object
return $result