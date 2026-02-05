# Audit: 2.3.7.7
# CIS Benchmark: 2.3.7.7 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
Write-Host ""
        Write-Host "=== CIS Audit: 2.3.7.7 - Interactive Logon: Prompt User to Change Password Before Expiration ===" -ForegroundColor Cyan
        Write-Host "Checking registry setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $valueName = "PasswordExpiryWarning"
        
        # Check if registry key exists
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default value is 5 days when not set
                $currentDays = 5
                $details = "Registry value not set (defaults to 5 days)"
                $isCompliant = $true  # 5 days is within the 5-14 day range
            } else {
                $currentDays = [int]$currentValue
                $details = "Registry value: $currentDays days"
                
                # Check if value is between 5 and 14 (inclusive)
                $isCompliant = ($currentDays -ge 5 -and $currentDays -le 14)
            }
            
            Write-Host "Current setting: $currentDays days" -ForegroundColor White
            Write-Host "Recommended: Between 5 and 14 days" -ForegroundColor White
            
            # Check compliance
            $complianceStatus = if ($isCompliant) { "Compliant" } else { "Non-Compliant" }
            
            Write-Host "Compliance: $complianceStatus" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            # Create result object
            $result = New-CISResultObject -CIS_ID "2.3.7.7" -Title "Ensure 'Interactive logon: Prompt user to change password before expiration' is set to 'between 5 and 14 days'" -CurrentValue "$currentDays days" -RecommendedValue "Between 5 and 14 days" -ComplianceStatus $complianceStatus -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        } else {
            # Registry key not found
            Write-Host "Registry key not found: $registryPath" -ForegroundColor Yellow
            Write-Host "Recommended: Between 5 and 14 days" -ForegroundColor White
            
            # Default value is 5 days when key doesn't exist
            $currentDays = 5
            $details = "Registry key not found (defaults to 5 days)"
            $isCompliant = $true  # 5 days is within the 5-14 day range
            
            Write-Host "Compliance: $(if ($isCompliant) { 'Compliant' } else { 'Non-Compliant' })" -ForegroundColor $(if ($isCompliant) { "Green" } else { "Red" })
            
            $result = New-CISResultObject -CIS_ID "2.3.7.7" -Title "Ensure 'Interactive logon: Prompt user to change password before expiration' is set to 'between 5 and 14 days'" -CurrentValue "$currentDays days" -RecommendedValue "Between 5 and 14 days" -ComplianceStatus $(if ($isCompliant) { "Compliant" } else { "Non-Compliant" }) -Source "Registry" -Details $details -Profile "L1"
            
            return $result
        }
}
