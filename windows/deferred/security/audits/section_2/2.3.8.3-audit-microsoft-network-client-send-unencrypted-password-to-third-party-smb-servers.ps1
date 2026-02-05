# Audit: 2.3.8.3
# CIS Benchmark: 2.3.8.3 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.8.3 - Microsoft Network Client: Send Unencrypted Password to Third-Party SMB Servers ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
        $valueName = "EnablePlainTextPassword"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "Disabled" according to JSON
                $currentStatus = "Disabled"
                $details = "Registry value not set (defaults to 'Disabled' - plaintext passwords not sent to third-party SMB servers)"
                $isCompliant = $true
            } else {
                # Map numeric values to their meanings
                switch ($currentValue) {
                    0 { $currentStatus = "Disabled" }
                    1 { $currentStatus = "Enabled" }
                    default { $currentStatus = "Unknown ($currentValue)" }
                }
                
                $details = "Registry value: $currentValue ($currentStatus)"
                
                # Check compliance: value 0 is compliant (Disabled)
                $isCompliant = ($currentValue -eq 0)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Disabled (0)" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.8.3" -Title "Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled (0)" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Disabled (0)" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist is "Disabled" according to JSON
            $currentStatus = "Disabled"
            $details = "Registry key not found (defaults to 'Disabled' - plaintext passwords not sent to third-party SMB servers)"
            $isCompliant = $true
            
            Write-Host "Compliance: Compliant" -ForegroundColor Green
            
            $result = New-CISResultObject -CIS_ID "2.3.8.3" -Title "Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled (0)" -ComplianceStatus "Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
}
