# Audit: 2.3.7.4
# CIS Benchmark: 2.3.7.4 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.7.4 - Interactive Logon: Machine Inactivity Limit ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "InactivityTimeoutSec"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default value is 0 (no inactivity limit)
                $currentStatus = "0"
                $details = "Registry value not set (defaults to 0 - no inactivity limit)"
                $isCompliant = $false
            } else {
                $currentStatus = $currentValue.ToString()
                $details = "Registry value: $currentStatus seconds"
                
                # Check compliance: value must be 900 or fewer seconds, but not 0
                $isCompliant = ($currentValue -le 900 -and $currentValue -ne 0)
            }
            
            Write-Host "Current inactivity limit: $currentStatus seconds" -ForegroundColor White
            Write-Host "Recommended: 900 or fewer seconds, but not 0" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.7.4" -Title "Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'" -CurrentValue $currentStatus -RecommendedValue "900 or fewer seconds, but not 0" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: 900 or fewer seconds, but not 0" -ForegroundColor White
            
            # Default value is 0 (no inactivity limit)
            $currentStatus = "0"
            $details = "Registry key not found (defaults to 0 - no inactivity limit)"
            $isCompliant = $false
            
            Write-Host "Compliance: $(if ($isCompliant) { 'Compliant' } else { 'Non-Compliant' })" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            $result = New-CISResultObject -CIS_ID "2.3.7.4" -Title "Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0'" -CurrentValue $currentStatus -RecommendedValue "900 or fewer seconds, but not 0" -ComplianceStatus $(if ($isCompliant) { "Compliant" } else { "Non-Compliant" }) -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
}
