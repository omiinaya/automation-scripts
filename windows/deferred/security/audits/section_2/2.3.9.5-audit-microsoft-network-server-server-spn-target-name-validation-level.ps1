# Audit: 2.3.9.5
# CIS Benchmark: 2.3.9.5 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.9.5 - Microsoft Network Server: Server SPN Target Name Validation Level ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "SMBServerNameHardeningLevel"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set is "Off" according to JSON
                $currentStatus = "Off"
                $details = "Registry value not set (defaults to 'Off' - SPN not required or validated)"
                $isCompliant = $false  # Default is Off, which is not compliant
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                
                # Map values to descriptive names
                switch ($currentValueInt) {
                    0 { $currentStatus = "Off" }
                    1 { $currentStatus = "Accept if provided by client" }
                    2 { $currentStatus = "Required from client" }
                    default { $currentStatus = "Unknown ($currentValueInt)" }
                }
                
                $details = "Registry value: $currentValueInt ($currentStatus)"
                
                # Check compliance: value must be 1 or 2 (Accept if provided by client or Required from client)
                $isCompliant = ($currentValueInt -eq 1 -or $currentValueInt -eq 2)
            }
            
            Write-Host "Current setting: $currentStatus" -ForegroundColor White
            Write-Host "Recommended: Accept if provided by client or higher" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.9.5" -Title "Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher" -CurrentValue $currentStatus -RecommendedValue "Accept if provided by client or higher" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Accept if provided by client or higher" -ForegroundColor White
            
            # Default behavior when registry key doesn't exist is "Off" according to JSON
            $currentStatus = "Off"
            $details = "Registry key not found (defaults to 'Off' - SPN not required or validated)"
            $isCompliant = $false
            
            Write-Host "Compliance: Non-Compliant" -ForegroundColor Red
            
            $result = New-CISResultObject -CIS_ID "2.3.9.5" -Title "Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher" -CurrentValue $currentStatus -RecommendedValue "Accept if provided by client or higher" -ComplianceStatus "Non-Compliant" -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
}
