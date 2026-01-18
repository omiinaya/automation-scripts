# CIS Audit Script for 2.3.7.2: Interactive logon: Don't display last signed-in
# Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'

<#
.SYNOPSIS
    CIS Audit Script for 2.3.7.2 - Interactive logon: Don't display last signed-in

.DESCRIPTION
    This script audits the compliance status of CIS control 2.3.7.2 which ensures
    that the last signed-in user name is not displayed on the Windows logon screen.

.PARAMETER None
    This script does not accept any parameters.

.EXAMPLE
    .\2.3.7.2-audit-interactive-logon-dont-display-last-signed-in.ps1

.NOTES
    CIS ID: 2.3.7.2
    Profile: L1
    Registry Path: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System:DontDisplayLastUserName
    Expected Value: 1 (Enabled)
    Group Policy Path: Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\Interactive logon: Don't display last signed-in
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Import required modules
Import-Module $PSScriptRoot\..\..\modules\CISFramework.psm1 -ErrorAction Stop

# CIS Control Information
$CisId = "2.3.7.2"
$CisTitle = "Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled'"
$CisProfile = "L1"

# Registry configuration for this control
$RegistryPaths = @(
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Name = "DontDisplayLastUserName"
        Type = "DWORD"
        ExpectedValue = 1
        Description = "Don't display last signed-in user name"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        Name = "DontDisplayLastUserName"
        Type = "DWORD"
        ExpectedValue = 1
        Description = "Group Policy setting for don't display last signed-in"
    }
)

# Group Policy configuration
$GroupPolicyPath = "Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\Interactive logon: Don't display last signed-in"
$ExpectedGpoValue = "Enabled"

# Initialize compliance tracking
$ComplianceResults = @()
$OverallCompliant = $true

# Display script header
Write-CISScriptHeader -CisId $CisId -Title $CisTitle -Profile $CisProfile

# Check registry settings
Write-Host "Checking Registry Settings..." -ForegroundColor Cyan

foreach ($RegistryConfig in $RegistryPaths) {
    $result = Test-RegistryValue @RegistryConfig
    $ComplianceResults += $result
    
    if (-not $result.Compliant) {
        $OverallCompliant = $false
    }
}

# Check Group Policy setting (if available)
Write-Host "Checking Group Policy Setting..." -ForegroundColor Cyan
$gpoResult = Test-GroupPolicySetting -PolicyPath $GroupPolicyPath -ExpectedValue $ExpectedGpoValue
$ComplianceResults += $gpoResult

if (-not $gpoResult.Compliant) {
    $OverallCompliant = $false
}

# Display compliance summary
Write-Host ""
Write-Host "Compliance Summary:" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow

foreach ($result in $ComplianceResults) {
    $status = if ($result.Compliant) { "COMPLIANT" } else { "NON-COMPLIANT" }
    $color = if ($result.Compliant) { "Green" } else { "Red" }
    
    Write-Host "$($result.Description): $status" -ForegroundColor $color
    if (-not $result.Compliant -and $result.ActualValue) {
        Write-Host "  Expected: $($result.ExpectedValue)" -ForegroundColor Yellow
        Write-Host "  Actual: $($result.ActualValue)" -ForegroundColor Red
    }
}

# Final compliance determination
Write-Host ""
if ($OverallCompliant) {
    Write-Host "OVERALL STATUS: COMPLIANT" -ForegroundColor Green
    Write-Host "The system is configured according to CIS benchmark requirements." -ForegroundColor Green
    exit 0
} else {
    Write-Host "OVERALL STATUS: NON-COMPLIANT" -ForegroundColor Red
    Write-Host "The system does not meet CIS benchmark requirements." -ForegroundColor Red
    Write-Host ""
    Write-Host "Remediation Required:" -ForegroundColor Yellow
    Write-Host "- Configure the registry value DontDisplayLastUserName to 1" -ForegroundColor Yellow
    Write-Host "- Enable the Group Policy setting: $GroupPolicyPath" -ForegroundColor Yellow
    exit 1
}

# Log script execution
Write-CISExecutionLog -CisId $CisId -Compliant $OverallCompliant -Results $ComplianceResults