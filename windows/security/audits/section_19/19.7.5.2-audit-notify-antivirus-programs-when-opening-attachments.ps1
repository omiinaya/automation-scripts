<#
.SYNOPSIS
    Audits CIS control 19.7.5.2 - Notify antivirus programs when opening attachments
.DESCRIPTION
    This script audits whether antivirus programs are notified when opening attachments as recommended by CIS.
.NOTES
    CIS ID: 19.7.5.2
    Profile: L1
    File Name: 19.7.5.2-audit-notify-antivirus-programs-when-opening-attachments.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# Get CIS recommendation
$cisId = "19.7.5.2"
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

# Audit antivirus notification setting
# This setting is stored in user registry hive: HKU\[USER SID]\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments
# The value name is: ScanWithAntiVirus
# Expected value: 3 (Enabled)

try {
    # Get current user SID
    $currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    
    # Construct registry path
    $registryPath = "Registry::HKEY_USERS\$currentUserSid\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments"
    $valueName = "ScanWithAntiVirus"
    
    # Check if registry key exists
    if (Test-Path $registryPath) {
        $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        
        if ($currentValue -and $currentValue.$valueName -eq 3) {
            $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Enabled (3)" -RecommendedValue "Enabled" -ComplianceStatus "Compliant" -Source "Registry" -Details "Antivirus programs are notified when opening attachments" -Profile $recommendation.profile
        } else {
            $result = New-CISResultObject -CIS_ID $cisId -Title $recommendation.title -CurrentValue "Disabled or Not Configured" -RecommendedValue "Enabled" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details "Antivirus programs are not notified when opening attachments" -Profile $recommendation.profile
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