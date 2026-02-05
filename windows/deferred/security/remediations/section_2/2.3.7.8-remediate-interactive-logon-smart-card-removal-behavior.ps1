# Remediation: 2.3.7.8
# CIS Benchmark: 2.3.7.8 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.7.8 - Interactive Logon: Smart Card Removal Behavior ===" -ForegroundColor Cyan
        Write-Host "Configuring smart card removal behavior setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $valueName = "ScRemoveOption"
        
        # CIS recommendation: Lock Workstation or higher (1, 2, or 3)
        # Using value 1 (Lock Workstation) as the recommended default
        $recommendedValue = 1
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is "No action" when not set
                $previousStatus = "No action"
                $previousValue = 0
            } else {
                # Map numeric values to their meanings
                switch ($currentValue) {
                    0 { $previousStatus = "No action" }
                    1 { $previousStatus = "Lock Workstation" }
                    2 { $previousStatus = "Force Logoff" }
                    3 { $previousStatus = "Disconnect if a Remote Desktop Services session" }
                    default { $previousStatus = "Unknown ($currentValue)" }
                }
                $previousValue = $currentValue
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is within CIS recommendation (1, 2, or 3)
            if ($previousValue -eq 1 -or $previousValue -eq 2 -or $previousValue -eq 3) {
                Write-Host "Current setting is already within CIS recommendation (Lock Workstation or higher)" -ForegroundColor Green
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
                0 { $newStatus = "No action" }
                1 { $newStatus = "Lock Workstation" }
                2 { $newStatus = "Force Logoff" }
                3 { $newStatus = "Disconnect if a Remote Desktop Services session" }
                default { $newStatus = "Unknown ($newValue)" }
            }
            
            if ($newValue -eq 1 -or $newValue -eq 2 -or $newValue -eq 3) {
                Write-Host "Smart card removal behavior successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Workstation will $newStatus when smart card is removed" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Smart card removal behavior successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure smart card removal behavior within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure smart card removal behavior within CIS recommendation"
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
                0 { $newStatus = "No action" }
                1 { $newStatus = "Lock Workstation" }
                2 { $newStatus = "Force Logoff" }
                3 { $newStatus = "Disconnect if a Remote Desktop Services session" }
                default { $newStatus = "Unknown ($newValue)" }
            }
            
            if ($newValue -eq 1 -or $newValue -eq 2 -or $newValue -eq 3) {
                Write-Host "Smart card removal behavior successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "Workstation will $newStatus when smart card is removed" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Smart card removal behavior successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure smart card removal behavior within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure smart card removal behavior within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        }
}
