# Audit: 2.3.9.2
# CIS Benchmark: 2.3.9.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.9.2 - Microsoft Network Server: Digitally Sign Communications (Always) ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "RequireSecuritySignature"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "Disabled" according to JSON
                $currentStatus = "Disabled"
                $details = "Registry value not set (defaults to 'Disabled' - SMB packet signing is negotiated between client and server)"
                $isCompliant = $false
            } else {
                # Map numeric values to their meanings
                switch ($currentValue) {
                    0 { $currentStatus = "Disabled" }
                    1 { $currentStatus = "Enabled" }
                    default { $currentStatus = "Unknown ($currentValue)" }
                }
                
                $details = "Registry value: $currentValue ($currentStatus)"
                
                # Check compliance: value 1 is compliant (Enabled)
                $isCompliant = ($currentValue -eq 1)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Enabled (1)" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.9.2" -Title "Ensure 'Microsoft network server: Digitally sign communications (always)' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled (1)" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Enabled (1)" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist is "Disabled" according to JSON
            $currentStatus = "Disabled"
            $details = "Registry key not found (defaults to 'Disabled' - SMB packet signing is negotiated between client and server)"
            $isCompliant = $false
            
            Write-Host "Compliance: Non-Compliant" -ForegroundColor Red
            
            $result = New-CISResultObject -CIS_ID "2.3.9.2" -Title "Ensure 'Microsoft network server: Digitally sign communications (always)' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled (1)" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
}
