<#
.SYNOPSIS
    Audits CIS control 19.7.5.1 - Do not preserve zone information in file attachments
.DESCRIPTION
    This script audits whether zone information is preserved in file attachments as recommended by CIS.
.NOTES
    CIS ID: 19.7.5.1
    Profile: L1
    File Name: 19.7.5.1-audit-do-not-preserve-zone-information-in-file-attachments.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# Get CIS recommendation
$cisId = "19.7.5.1"
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

# Audit zone information preservation setting
# This setting is stored in user registry hive: HKU\[USER SID]\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments
# The value name is: SaveZoneInformation
# Expected value: 2 (Disabled - zone information IS preserved)

try {
    # Get current user SID
    $currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    
    # Construct registry path
    $registryPath = "Registry::HKEY_USERS\$currentUserSid\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments"
    $valueName = "SaveZoneInformation"
    
    # Check if registry key exists
    if (Test-Path $registryPath) {
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        
        if ($currentValue -and $currentValue.$valueName -eq 2) {
            $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Disabled (2)" -RecommendedValue "Disabled" -ComplianceStatus "Compliant" -Source "Registry" -Details "Zone information is preserved in file attachments" -Profile $recommendation.profile
        } else {
            $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Enabled or Not Configured" -RecommendedValue "Disabled" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details "Zone information is not preserved in file attachments" -Profile $recommendation.profile
        }
    } else {
        $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Not Configured" -RecommendedValue "Disabled" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details "Registry key does not exist" -Profile $recommendation.profile
    }
} catch {
    $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Error" -RecommendedValue "Disabled" -ComplianceStatus "Error" -Source "Registry" -ErrorMessage "Audit failed: $_" -Profile $recommendation.profile
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