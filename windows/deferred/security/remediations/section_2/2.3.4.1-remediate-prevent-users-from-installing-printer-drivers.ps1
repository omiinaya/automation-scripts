# Remediation: 2.3.4.1
# CIS Benchmark: 2.3.4.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.4.1 - Prevent Users From Installing Printer Drivers ===" -ForegroundColor Cyan
        Write-Host "Enabling prevent users from installing printer drivers setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers"
        $valueName = "AddPrinterDrivers"
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                $previousStatus = "Disabled (default)"
            } else {
                $previousStatus = if ($currentValue -eq 1) { "Enabled" } else { "Disabled" }
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Set registry value to enable (1 = enabled)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 1 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 1) { "Enabled" } else { "Disabled" }
            
            if ($newStatus -eq "Enabled") {
                Write-Host "Prevent users from installing printer drivers setting successfully enabled" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Prevent users from installing printer drivers setting successfully enabled"
                }
            } else {
                Write-Host "Failed to enable prevent users from installing printer drivers setting" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to enable prevent users from installing printer drivers setting"
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to enable
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 1 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 1) { "Enabled" } else { "Disabled" }
            
            if ($newStatus -eq "Enabled") {
                Write-Host "Prevent users from installing printer drivers setting successfully configured" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Prevent users from installing printer drivers setting successfully configured"
                }
            } else {
                Write-Host "Failed to configure prevent users from installing printer drivers setting" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure prevent users from installing printer drivers setting"
                }
            }
        }
}
