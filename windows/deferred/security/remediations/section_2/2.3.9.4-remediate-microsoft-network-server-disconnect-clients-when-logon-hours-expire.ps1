# Remediation: 2.3.9.4
# CIS Benchmark: 2.3.9.4 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.9.4 - Microsoft Network Server: Disconnect Clients When Logon Hours Expire ===" -ForegroundColor Cyan
        Write-Host "Configuring Microsoft network server disconnect clients when logon hours expire setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "enableforcedlogoff"
        
        # CIS recommendation: Enabled (value = 1)
        $recommendedValue = 1
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is "Enabled" when not set according to JSON
                $previousStatus = "Enabled"
                $previousValue = 1
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                $previousStatus = if ($currentValueInt -eq 1) { "Enabled" } else { "Disabled" }
                $previousValue = $currentValueInt
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is already compliant (Enabled = 1)
            if ($previousValue -eq 1) {
                Write-Host "Current setting is already compliant with CIS recommendation (Enabled)" -ForegroundColor Green
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
            
            # Convert to integer for comparison
            $newValueInt = [int]$newValue
            $newStatus = if ($newValueInt -eq 1) { "Enabled" } else { "Disabled" }
            
            if ($newValueInt -eq 1) {
                Write-Host "Microsoft network server disconnect clients when logon hours expire successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Clients will be disconnected when their logon hours expire" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server disconnect clients when logon hours expire successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server disconnect clients when logon hours expire to Enabled" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server disconnect clients when logon hours expire to Enabled"
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
            
            # Convert to integer for comparison
            $newValueInt = [int]$newValue
            $newStatus = if ($newValueInt -eq 1) { "Enabled" } else { "Disabled" }
            
            if ($newValueInt -eq 1) {
                Write-Host "Microsoft network server disconnect clients when logon hours expire successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Clients will be disconnected when their logon hours expire" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server disconnect clients when logon hours expire successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server disconnect clients when logon hours expire to Enabled" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server disconnect clients when logon hours expire to Enabled"
                    RemediationApplied = $true
                }
            }
        }
}
