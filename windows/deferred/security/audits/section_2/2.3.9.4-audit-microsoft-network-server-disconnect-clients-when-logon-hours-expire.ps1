# Audit: 2.3.9.4
# CIS Benchmark: 2.3.9.4 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.9.4 - Microsoft Network Server: Disconnect Clients When Logon Hours Expire ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "enableforcedlogoff"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "Enabled" according to JSON
                $currentStatus = "Enabled"
                $details = "Registry value not set (defaults to 'Enabled' - clients disconnected when logon hours expire)"
                $isCompliant = $true
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                $currentStatus = if ($currentValueInt -eq 1) { "Enabled" } else { "Disabled" }
                $details = "Registry value: $currentValueInt ($currentStatus)"
                
                # Check compliance: value must be 1 (Enabled)
                $isCompliant = ($currentValueInt -eq 1)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Enabled" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.9.4" -Title "Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Enabled" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist is "Enabled" according to JSON
            $currentStatus = "Enabled"
            $details = "Registry key not found (defaults to 'Enabled' - clients disconnected when logon hours expire)"
            $isCompliant = $true
            
            Write-Host "Compliance: Compliant" -ForegroundColor Green
            
            $result = New-CISResultObject -CIS_ID "2.3.9.4" -Title "Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled" -ComplianceStatus "Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
}
