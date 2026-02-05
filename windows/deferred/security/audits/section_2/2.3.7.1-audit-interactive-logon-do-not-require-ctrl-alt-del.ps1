# Audit: 2.3.7.1
# CIS Benchmark: 2.3.7.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.7.1 - Interactive Logon: Do Not Require CTRL+ALT+DEL ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "DisableCAD"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default behavior when value is not set depends on Windows version
                # Windows 7 or older: Disabled (CTRL+ALT+DEL required)
                # Windows 8.0 or newer: Enabled (CTRL+ALT+DEL not required)
                $osVersion = [System.Environment]::OSVersion.Version
                if ($osVersion.Major -eq 6 -and $osVersion.Minor -le 1) {
                    # Windows 7 or older
                    $currentStatus = "Disabled"
                    $details = "Registry value not set (defaults to Disabled - CTRL+ALT+DEL required on Windows 7 or older)"
                    $isCompliant = $true
                } else {
                    # Windows 8.0 or newer
                    $currentStatus = "Enabled"
                    $details = "Registry value not set (defaults to Enabled - CTRL+ALT+DEL not required on Windows 8.0 or newer)"
                    $isCompliant = $false
                }
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
            $result = New-CISResultObject -CIS_ID "2.3.7.1" -Title "Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Disabled" -ForegroundColor White
            
            # Determine default behavior based on Windows version
            $osVersion = [System.Environment]::OSVersion.Version
            if ($osVersion.Major -eq 6 -and $osVersion.Minor -le 1) {
                # Windows 7 or older
                $currentStatus = "Disabled"
                $details = "Registry key not found (defaults to Disabled - CTRL+ALT+DEL required on Windows 7 or older)"
                $isCompliant = $true
            } else {
                # Windows 8.0 or newer
                $currentStatus = "Enabled"
                $details = "Registry key not found (defaults to Enabled - CTRL+ALT+DEL not required on Windows 8.0 or newer)"
                $isCompliant = $false
            }
            
            Write-Host "Compliance: $(if ($isCompliant) { 'Compliant' } else { 'Non-Compliant' })" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            $result = New-CISResultObject -CIS_ID "2.3.7.1" -Title "Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'" -CurrentValue $currentStatus -RecommendedValue "Disabled" -ComplianceStatus $(if ($isCompliant) { "Compliant" } else { "Non-Compliant" }) -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
}
