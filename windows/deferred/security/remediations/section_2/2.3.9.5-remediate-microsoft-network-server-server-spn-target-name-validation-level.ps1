# Remediation: 2.3.9.5
# CIS Benchmark: 2.3.9.5 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.9.5 - Microsoft Network Server: Server SPN Target Name Validation Level ===" -ForegroundColor Cyan
        Write-Host "Configuring Microsoft network server server SPN target name validation level setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
        $valueName = "SMBServerNameHardeningLevel"
        
        # CIS recommendation: Accept if provided by client (value = 1) or Required from client (value = 2)
        $recommendedValue = 1  # Default to Accept if provided by client
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is "Off" when not set according to JSON
                $previousStatus = "Off"
                $previousValue = 0
            } else {
                # Convert to integer for comparison
                $currentValueInt = [int]$currentValue
                
                # Map values to descriptive names
                switch ($currentValueInt) {
                    0 { $previousStatus = "Off" }
                    1 { $previousStatus = "Accept if provided by client" }
                    2 { $previousStatus = "Required from client" }
                    default { $previousStatus = "Unknown ($currentValueInt)" }
                }
                $previousValue = $currentValueInt
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is already compliant (1 or 2)
            if ($previousValue -eq 1 -or $previousValue -eq 2) {
                Write-Host "Current setting is already compliant with CIS recommendation" -ForegroundColor Green
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
            
            # Map values to descriptive names
            switch ($newValueInt) {
                0 { $newStatus = "Off" }
                1 { $newStatus = "Accept if provided by client" }
                2 { $newStatus = "Required from client" }
                default { $newStatus = "Unknown ($newValueInt)" }
            }
            
            if ($newValueInt -eq 1 -or $newValueInt -eq 2) {
                Write-Host "Microsoft network server server SPN target name validation level successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SPN target name validation level set to $newStatus" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server server SPN target name validation level successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server server SPN target name validation level to compliant value" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server server SPN target name validation level to compliant value"
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
            
            # Map values to descriptive names
            switch ($newValueInt) {
                0 { $newStatus = "Off" }
                1 { $newStatus = "Accept if provided by client" }
                2 { $newStatus = "Required from client" }
                default { $newStatus = "Unknown ($newValueInt)" }
            }
            
            if ($newValueInt -eq 1 -or $newValueInt -eq 2) {
                Write-Host "Microsoft network server server SPN target name validation level successfully configured to $newStatus" -ForegroundColor Green
                Write-Host "SPN target name validation level set to $newStatus" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Microsoft network server server SPN target name validation level successfully configured to $newStatus"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure Microsoft network server server SPN target name validation level to compliant value" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure Microsoft network server server SPN target name validation level to compliant value"
                    RemediationApplied = $true
                }
            }
        }
}
