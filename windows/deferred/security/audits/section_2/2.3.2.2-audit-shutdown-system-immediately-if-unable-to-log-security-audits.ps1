# Audit: 2.3.2.2
# CIS Benchmark: 2.3.2.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.2.2 - Shutdown System Immediately If Unable To Log Security Audits ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $valueName = "CrashOnAuditFail"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is Disabled (0)
                $currentStatus = "Disabled"
                $details = "Registry value not set (defaults to Disabled)"
                $isCompliant = $true
            } else {
                $currentStatus = if ($currentValue -eq 0) { "Disabled" } else { "Enabled" }
                $details = "Registry value: $currentValue ($currentStatus)"
                $isCompliant = ($currentValue -eq 0)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Disabled" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.2.2" -Title "Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Disabled" -ForegroundColor White
            Write-Host "Compliance: Compliant (key not found, defaults to Disabled)" -ForegroundColor Green
            
            $result = New-CISResultObject -CIS_ID "2.3.2.2" -Title "Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled'" -CurrentValue "Disabled" -RecommendedValue "Disabled" -ComplianceStatus "Compliant" -Source "Registry" -Details "Registry key not found (defaults to Disabled)" -Profile "L1"
            
            return $result
        }
}
