# Remediation: 2.3.9.3
# CIS Benchmark: 2.3.9.3 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.9.3 - Microsoft Network Server: Digitally Sign Communications (If Client Agrees) ===" -ForegroundColor Cyan
        Write-Host "Configuring Microsoft network server digitally sign communications (if client agrees) setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "EnableSecuritySignature"
        
        # CIS recommendation: Enabled (1)
        $recommendedValue = 1
        
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
            
            # Check if current value is within CIS recommendation (1)
            if ($previousValue -eq 1) {
                Write-Host "Current setting is already within CIS recommendation (Enabled)" -ForegroundColor Green
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
            
            if ($newValue -eq 1) {
                Write-Host "Microsoft network server digitally sign communications (if client agrees) successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SMB packet signing will be negotiated with clients that request it" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server digitally sign communications (if client agrees) successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server digitally sign communications (if client agrees) within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server digitally sign communications (if client agrees) within CIS recommendation"
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
            
            if ($newValue -eq 1) {
                Write-Host "Microsoft network server digitally sign communications (if client agrees) successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SMB packet signing will be negotiated with clients that request it" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server digitally sign communications (if client agrees) successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server digitally sign communications (if client agrees) within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server digitally sign communications (if client agrees) within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        }
}
