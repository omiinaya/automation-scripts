# Remediation: 2.3.1.2
# CIS Benchmark: 2.3.1.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.1.2 - Limit Blank Passwords to Console Logon Only ===" -ForegroundColor Cyan
        Write-Host "Configuring Security Options setting..." -ForegroundColor White
        
        # Registry path for Security Options setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "LimitBlankPasswordUse"
        $recommendedValue = 1  # Enabled
        
        # Check current value first
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            Write-Host "Current value: $currentValue" -ForegroundColor White
        } else {
            Write-Host "Registry key does not exist, creating..." -ForegroundColor Yellow
            # Create registry key if it doesn't exist
            New-Item -Path $registryPath -Force | Out-Null
            $currentValue = "Not Set"
        }
        
        Write-Host "Setting value to: $recommendedValue" -ForegroundColor White
        
        # Set registry value
        Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
        
        # Verify the change
        Start-Sleep -Seconds 1
        $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
        
        if ($newValue -eq $recommendedValue) {
            Write-Host "Setting successfully configured" -ForegroundColor Green
            
            # Create remediation result
            $result = New-CISRemediationResult -CIS_ID "2.3.1.2" -Title "Ensure 'Accounts: Limit local account use of blank passwords to console logon only' is set to 'Enabled'" -PreviousValue $currentValue -NewValue $recommendedValue -Status "Remediated" -Message "Security Options setting successfully configured to limit blank passwords to console logon only" -IsCompliant $true -RequiresManualAction $false -Source "Registry"
            
            return $result
        } else {
            Write-Host "Failed to verify setting configuration" -ForegroundColor Red
            
            $result = New-CISRemediationResult -CIS_ID "2.3.1.2" -Title "Ensure 'Accounts: Limit local account use of blank passwords to console logon only' is set to 'Enabled'" -PreviousValue $currentValue -NewValue $newValue -Status "PartiallyRemediated" -Message "Setting may not have been applied correctly" -IsCompliant $false -RequiresManualAction $false -Source "Registry"
            
            return $result
        }
}
