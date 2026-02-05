# Audit: 2.3.9.1
# CIS Benchmark: 2.3.9.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.9.1 - Microsoft Network Server: Amount of Idle Time Required Before Suspending Session ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "AutoDisconnect"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "15 minutes" according to JSON
                $currentStatus = "15 minutes"
                $details = "Registry value not set (defaults to '15 minutes' - sessions suspended after 15 minutes of inactivity)"
                $isCompliant = $true
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                $currentStatus = "$currentValueInt minute(s)"
                $details = "Registry value: $currentValueInt minute(s)"
                
                # Check compliance: value must be 15 or fewer (less than or equal to 15)
                $isCompliant = ($currentValueInt -le 15)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: 15 or fewer minute(s)" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.9.1" -Title "Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'" -CurrentValue $currentStatus -RecommendedValue "15 or fewer minute(s)" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: 15 or fewer minute(s)" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist is "15 minutes" according to JSON
            $currentStatus = "15 minutes"
            $details = "Registry key not found (defaults to '15 minutes' - sessions suspended after 15 minutes of inactivity)"
            $isCompliant = $true
            
            Write-Host "Compliance: Compliant" -ForegroundColor Green
            
            $result = New-CISResultObject -CIS_ID "2.3.9.1" -Title "Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'" -CurrentValue $currentStatus -RecommendedValue "15 or fewer minute(s)" -ComplianceStatus "Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
}
