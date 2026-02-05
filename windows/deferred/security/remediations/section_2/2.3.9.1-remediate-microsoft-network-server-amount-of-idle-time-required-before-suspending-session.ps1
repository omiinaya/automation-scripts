# Remediation: 2.3.9.1
# CIS Benchmark: 2.3.9.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.9.1 - Microsoft Network Server: Amount of Idle Time Required Before Suspending Session ===" -ForegroundColor Cyan
        Write-Host "Configuring Microsoft network server amount of idle time required before suspending session setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "AutoDisconnect"
        
        # CIS recommendation: 15 or fewer minutes (15 or less)
        $recommendedValue = 15
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is "15 minutes" when not set according to JSON
                $previousStatus = "15 minutes"
                $previousValue = 15
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                $previousStatus = "$currentValueInt minute(s)"
                $previousValue = $currentValueInt
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is within CIS recommendation (15 or fewer)
            if ($previousValue -le 15) {
                Write-Host "Current setting is already within CIS recommendation (15 or fewer minutes)" -ForegroundColor Green
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
            $newStatus = "$newValueInt minute(s)"
            
            if ($newValueInt -le 15) {
                Write-Host "Microsoft network server amount of idle time required before suspending session successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SMB sessions will be suspended after $newValueInt minutes of inactivity" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server amount of idle time required before suspending session successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server amount of idle time required before suspending session within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server amount of idle time required before suspending session within CIS recommendation"
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
            $newStatus = "$newValueInt minute(s)"
            
            if ($newValueInt -le 15) {
                Write-Host "Microsoft network server amount of idle time required before suspending session successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SMB sessions will be suspended after $newValueInt minutes of inactivity" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server amount of idle time required before suspending session successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server amount of idle time required before suspending session within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server amount of idle time required before suspending session within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        }
}
