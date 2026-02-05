# Remediation: 2.3.7.3
# CIS Benchmark: 2.3.7.3 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.7.3 - Interactive Logon: Machine Account Lockout Threshold ===" -ForegroundColor Cyan
        Write-Host "Setting machine account lockout threshold..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "MaxDevicePasswordFailedAttempts"
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default value is 0 (machine will never lock out)
                $previousStatus = "0 (default)"
            } else {
                $previousStatus = $currentValue.ToString()
            }
            
            Write-Host "Current threshold: $previousStatus failed attempts" -ForegroundColor White
            
            # Set registry value to 10 (recommended value)
            # Note: Values from 1 to 3 will be interpreted as 4, so we set 10 directly
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 10 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = $newValue.ToString()
            
            if ($newStatus -eq "10") {
                Write-Host "Machine account lockout threshold successfully set to 10 failed attempts" -ForegroundColor Green
                Write-Host "Machine will lock out after 10 failed logon attempts" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Machine account lockout threshold successfully set to 10 failed attempts"
                }
            } else {
                Write-Host "Failed to set machine account lockout threshold" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to set machine account lockout threshold"
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to 10 (recommended value)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 10 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = $newValue.ToString()
            
            if ($newStatus -eq "10") {
                Write-Host "Machine account lockout threshold successfully configured" -ForegroundColor Green
                Write-Host "Machine will lock out after 10 failed logon attempts" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Machine account lockout threshold successfully configured"
                }
            } else {
                Write-Host "Failed to configure machine account lockout threshold" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure machine account lockout threshold"
                }
            }
        }
}
