# Remediation: 2.3.2.2
# CIS Benchmark: 2.3.2.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.2.2 - Shutdown System Immediately If Unable To Log Security Audits ===" -ForegroundColor Cyan
        Write-Host "Disabling shutdown system immediately if unable to log security audits..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        $valueName = "CrashOnAuditFail"
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                $previousStatus = "Disabled (default)"
            } else {
                $previousStatus = if ($currentValue -eq 0) { "Disabled" } else { "Enabled" }
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Set registry value to disable (0 = disabled)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 0) { "Disabled" } else { "Enabled" }
            
            if ($newStatus -eq "Disabled") {
                Write-Host "Shutdown system immediately setting successfully disabled" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Shutdown system immediately setting successfully disabled"
                }
            } else {
                Write-Host "Failed to disable shutdown system immediately setting" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to disable shutdown system immediately setting"
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to disable
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 0) { "Disabled" } else { "Enabled" }
            
            if ($newStatus -eq "Disabled") {
                Write-Host "Shutdown system immediately setting successfully configured" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Shutdown system immediately setting successfully configured"
                }
            } else {
                Write-Host "Failed to configure shutdown system immediately setting" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure shutdown system immediately setting"
                }
            }
        }
}
