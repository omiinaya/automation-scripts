# Audit: 2.3.1.1
# CIS Benchmark: 2.3.1.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.1.1 - Guest Account Status ===" -ForegroundColor Cyan
        Write-Host "Checking Guest account status..." -ForegroundColor White
        
        # Get Guest account status using PowerShell
        $guestAccount = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
        
        if ($guestAccount) {
            $currentStatus = if ($guestAccount.Enabled) { "Enabled" } else { "Disabled" }
            $details = "Guest account found with status: $currentStatus"
            
            Write-Host "Current Guest account status: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Disabled" -ForegroundColor White
            
            # Check compliance
            $isCompliant = ($currentStatus -eq "Disabled")
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.1.1" -Title "Ensure 'Accounts: Guest account status' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled" -ComplianceStatus $complianceStatus -Source "Local User Account" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Guest account not found (which means it's effectively disabled)
            Write-Host "Guest account not found (effectively disabled)" -ForegroundColor White
            Write-Host "Recommended: Disabled" -ForegroundColor White
            Write-Host "Compliance: Compliant" -ForegroundColor Green
            
            $result = New-CISResultObject -CIS_ID "2.3.1.1" -Title "Ensure 'Accounts: Guest account status' is set to 'Disabled'" -CurrentValue "Disabled" -RecommendedValue "Disabled" -ComplianceStatus "Compliant" -Source "Local User Account" -Details "Guest account not found (effectively disabled)" -Profile "L1"
            
            return $result
        }
}
