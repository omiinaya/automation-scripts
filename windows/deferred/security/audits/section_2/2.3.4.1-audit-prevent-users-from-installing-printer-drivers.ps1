# Audit: 2.3.4.1
# CIS Benchmark: 2.3.4.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.4.1 - Prevent Users From Installing Printer Drivers ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers"
        $valueName = "AddPrinterDrivers"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is Disabled (users can install drivers)
                $currentStatus = "Disabled"
                $details = "Registry value not set (defaults to Disabled - users can install drivers)"
                $isCompliant = $false
            } else {
                $currentStatus = if ($currentValue -eq 1) { "Enabled" } else { "Disabled" }
                $details = "Registry value: $currentValue ($currentStatus)"
                $isCompliant = ($currentValue -eq 1)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Enabled" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.4.1" -Title "Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'" -CurrentValue $currentStatus -RecommendedValue "Enabled" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L2"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Enabled" -ForegroundColor White
            Write-Host "Compliance: Non-Compliant (key not found, defaults to Disabled)" -ForegroundColor Red
            
            $result = New-CISResultObject -CIS_ID "2.3.4.1" -Title "Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled'" -CurrentValue "Disabled" -RecommendedValue "Enabled" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details "Registry key not found (defaults to Disabled - users can install drivers)" -Profile "L2"
            
            return $result
        }
}
