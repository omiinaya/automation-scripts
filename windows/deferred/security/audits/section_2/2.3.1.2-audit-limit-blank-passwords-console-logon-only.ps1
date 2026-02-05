# Audit: 2.3.1.2
# CIS Benchmark: 2.3.1.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.1.2 - Limit Blank Passwords to Console Logon Only ===" -ForegroundColor Cyan
        Write-Host "Checking Security Options setting..." -ForegroundColor White
        
        # Registry path for Security Options setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "LimitBlankPasswordUse"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            # Get current value
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            # Convert numeric value to readable status
            $currentStatus = if ($currentValue -eq "Not Set") { "Not Configured" } 
                            elseif ($currentValue -eq 1) { "Enabled" } 
                            elseif ($currentValue -eq 0) { "Disabled" } 
                            else { "Unknown ($currentValue)" }
            
            Write-Host "Current setting status: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Enabled" -ForegroundColor White
            
            # Check compliance
            $isCompliant = ($currentValue -eq 1)
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.1.2" -Title "Ensure 'Accounts: Limit local account use of blank passwords to console logon only' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled" -ComplianceStatus $complianceStatus -Source "Security Options" -Details "Registry path: $registryPath" -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Security Options registry path not found" -ForegroundColor Yellow
            Write-Host "Recommended: Enabled" -ForegroundColor White
            Write-Host "Compliance: Non-Compliant" -ForegroundColor Red
            
            $result = New-CISResultObject -CIS_ID "2.3.1.2" -Title "Ensure 'Accounts: Limit local account use of blank passwords to console logon only' is set to 'Enabled'" -CurrentValue "Not Configured" -RecommendedValue "Enabled" -ComplianceStatus "Non-Compliant" -Source "Security Options" -Details "Registry path not found: $registryPath" -Profile "L1"
            
            return $result
        }
}
