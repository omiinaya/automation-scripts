<#
.SYNOPSIS
    Audits CIS control 19.6.6.1.1 - Turn off Help Experience Improvement Program
.DESCRIPTION
    This script audits whether the Help Experience Improvement Program is disabled as recommended by CIS.
.NOTES
    CIS ID: 19.6.6.1.1
    Profile: L2
    File Name: 19.6.6.1.1-audit-turn-off-help-experience-improvement-program.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# Get CIS recommendation
$cisId = "19.6.6.1.1"
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

# Audit Help Experience Improvement Program setting
# This setting is stored in user registry hive: HKU\[USER SID]\Software\Policies\Microsoft\Assistance\Client\1.0
# The value name is: NoImplicitFeedback
# Expected value: 1 (Enabled)

try {
    # Get current user SID
    $currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    
    # Construct registry path
    $registryPath = "Registry::HKEY_USERS\$currentUserSid\Software\Policies\Microsoft\Assistance\Client\1.0"
    $valueName = "NoImplicitFeedback"
    
    # Check if registry key exists
    if (Test-Path $registryPath) {
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        
        if ($currentValue -and $currentValue.$valueName -eq 1) {
            $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Enabled (1)" -RecommendedValue "Enabled" -ComplianceStatus "Compliant" -Source "Registry" -Details "Help Experience Improvement Program is disabled" -Profile $recommendation.profile
        } else {
            $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Disabled or Not Configured" -RecommendedValue "Enabled" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details "Help Experience Improvement Program is enabled" -Profile $recommendation.profile
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