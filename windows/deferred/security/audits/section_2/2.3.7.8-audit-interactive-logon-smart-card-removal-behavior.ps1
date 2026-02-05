# Audit: 2.3.7.8
# CIS Benchmark: 2.3.7.8 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.7.8 - Interactive Logon: Smart Card Removal Behavior ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $valueName = "ScRemoveOption"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "No action"
                $currentStatus = "No action"
                $details = "Registry value not set (defaults to 'No action')"
                $isCompliant = $false
            } else {
                # Map numeric values to their meanings
                switch ($currentValue) {
                    0 { $currentStatus = "No action" }
                    1 { $currentStatus = "Lock Workstation" }
                    2 { $currentStatus = "Force Logoff" }
                    3 { $currentStatus = "Disconnect if a Remote Desktop Services session" }
                    default { $currentStatus = "Unknown ($currentValue)" }
                }
                
                $details = "Registry value: $currentValue ($currentStatus)"
                
                # Check compliance: values 1, 2, or 3 are compliant (Lock Workstation or higher)
                $isCompliant = ($currentValue -eq 1 -or $currentValue -eq 2 -or $currentValue -eq 3)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Lock Workstation or higher (1, 2, or 3)" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.7.8" -Title "Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher" -CurrentValue $currentStatus -RecommendedValue "Lock Workstation or higher (1, 2, or 3)" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Lock Workstation or higher (1, 2, or 3)" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist
            $currentStatus = "No action"
            $details = "Registry key not found (defaults to 'No action')"
            $isCompliant = $false
            
            Write-Host "Compliance: Non-Compliant" -ForegroundColor Red
            
            $result = New-CISResultObject -CIS_ID "2.3.7.8" -Title "Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher" -CurrentValue $currentStatus -RecommendedValue "Lock Workstation or higher (1, 2, or 3)" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
}
