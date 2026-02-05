# Audit: 2.3.7.3
# CIS Benchmark: 2.3.7.3 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.7.3 - Interactive Logon: Machine Account Lockout Threshold ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "MaxDevicePasswordFailedAttempts"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default value is 0 (machine will never lock out)
                $currentStatus = "0"
                $details = "Registry value not set (defaults to 0 - machine will never lock out)"
                $isCompliant = $false
            } else {
                $currentStatus = $currentValue.ToString()
                $details = "Registry value: $currentStatus"
                
                # Check compliance: value must be 10 or fewer, but not 0
                # Values from 1 to 3 will be interpreted as 4
                $effectiveValue = if ($currentValue -ge 1 -and $currentValue -le 3) { 4 } else { $currentValue }
                $isCompliant = ($effectiveValue -le 10 -and $effectiveValue -ne 0)
            }
            
            Write-Host "Current threshold: $currentStatus failed attempts" -ForegroundColor White
            Write-Host "Recommended: 10 or fewer invalid logon attempts, but not 0" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.7.3" -Title "Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'" -CurrentValue $currentStatus -RecommendedValue "10 or fewer invalid logon attempts, but not 0" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "BL"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: 10 or fewer invalid logon attempts, but not 0" -ForegroundColor White
            
            # Default value is 0 (machine will never lock out)
            $currentStatus = "0"
            $details = "Registry key not found (defaults to 0 - machine will never lock out)"
            $isCompliant = $false
            
            Write-Host "Compliance: $(if ($isCompliant) { 'Compliant' } else { 'Non-Compliant' })" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            $result = New-CISResultObject -CIS_ID "2.3.7.3" -Title "Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0'" -CurrentValue $currentStatus -RecommendedValue "10 or fewer invalid logon attempts, but not 0" -ComplianceStatus $(if ($isCompliant) { "Compliant" } else { "Non-Compliant" }) -Source "Registry" -Details $details -Profile "BL"
            
            return $result
        }
}
