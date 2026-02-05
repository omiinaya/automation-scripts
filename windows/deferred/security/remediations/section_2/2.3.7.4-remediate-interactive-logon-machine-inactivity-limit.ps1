# Remediation: 2.3.7.4
# CIS Benchmark: 2.3.7.4 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.7.4 - Interactive Logon: Machine Inactivity Limit ===" -ForegroundColor Cyan
        Write-Host "Setting machine inactivity limit..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "InactivityTimeoutSec"
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default value is 0 (no inactivity limit)
                $previousStatus = "0 (default)"
            } else {
                $previousStatus = $currentValue.ToString()
            }
            
            Write-Host "Current inactivity limit: $previousStatus seconds" -ForegroundColor White
            
            # Set registry value to 900 (recommended value - 15 minutes)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 900 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = $newValue.ToString()
            
            if ($newStatus -eq "900") {
                Write-Host "Machine inactivity limit successfully set to 900 seconds (15 minutes)" -ForegroundColor Green
                Write-Host "Machine will require re-authentication after 15 minutes of inactivity" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Machine inactivity limit successfully set to 900 seconds"
                }
            } else {
                Write-Host "Failed to set machine inactivity limit" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to set machine inactivity limit"
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to 900 (recommended value - 15 minutes)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 900 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = $newValue.ToString()
            
            if ($newStatus -eq "900") {
                Write-Host "Machine inactivity limit successfully configured" -ForegroundColor Green
                Write-Host "Machine will require re-authentication after 15 minutes of inactivity" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Machine inactivity limit successfully configured"
                }
            } else {
                Write-Host "Failed to configure machine inactivity limit" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure machine inactivity limit"
                }
            }
        }
}
