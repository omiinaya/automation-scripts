# Remediation: 2.3.8.3
# CIS Benchmark: 2.3.8.3 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.8.3 - Microsoft Network Client: Send Unencrypted Password to Third-Party SMB Servers ===" -ForegroundColor Cyan
        Write-Host "Configuring Microsoft network client send unencrypted password to third-party SMB servers setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
        $valueName = "EnablePlainTextPassword"
        
        # CIS recommendation: Disabled (0)
        $recommendedValue = 0
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is "Disabled" when not set according to JSON
                $previousStatus = "Disabled"
                $previousValue = 0
            } else {
                # Map numeric values to their meanings
                switch ($currentValue) {
                    0 { $previousStatus = "Disabled" }
                    1 { $previousStatus = "Enabled" }
                    default { $previousStatus = "Unknown ($currentValue)" }
                }
                $previousValue = $currentValue
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is within CIS recommendation (0)
            if ($previousValue -eq 0) {
                Write-Host "Current setting is already within CIS recommendation (Disabled)" -ForegroundColor Green
                Write-Host "No remediation needed" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $previousStatus
                    Success = $true
                    Message = "Setting already compliant with CIS recommendation"
                    RemediationApplied = $false
                }
            }
            
            # Set registry value to recommended value
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            # Map new value to its meaning
            switch ($newValue) {
                0 { $newStatus = "Disabled" }
                1 { $newStatus = "Enabled" }
                default { $newStatus = "Unknown ($newValue)" }
            }
            
            if ($newValue -eq 0) {
                Write-Host "Microsoft network client send unencrypted password to third-party SMB servers successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Plaintext passwords will not be sent to third-party SMB servers" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network client send unencrypted password to third-party SMB servers successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network client send unencrypted password to third-party SMB servers within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network client send unencrypted password to third-party SMB servers within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to recommended value
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $recommendedValue -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            # Map new value to its meaning
            switch ($newValue) {
                0 { $newStatus = "Disabled" }
                1 { $newStatus = "Enabled" }
                default { $newStatus = "Unknown ($newValue)" }
            }
            
            if ($newValue -eq 0) {
                Write-Host "Microsoft network client send unencrypted password to third-party SMB servers successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Plaintext passwords will not be sent to third-party SMB servers" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network client send unencrypted password to third-party SMB servers successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network client send unencrypted password to third-party SMB servers within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network client send unencrypted password to third-party SMB servers within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        }
}
