# Remediation: 2.3.7.1
# CIS Benchmark: 2.3.7.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.7.1 - Interactive Logon: Do Not Require CTRL+ALT+DEL ===" -ForegroundColor Cyan
        Write-Host "Disabling interactive logon do not require CTRL+ALT+DEL setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $valueName = "DisableCAD"
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Determine default behavior based on Windows version
                $osVersion = [System.Environment]::OSVersion.Version
                if ($osVersion.Major -eq 6 -and $osVersion.Minor -le 1) {
                    # Windows 7 or older - defaults to Disabled (CTRL+ALT+DEL required)
                    $previousStatus = "Disabled (default)"
                } else {
                    # Windows 8.0 or newer - defaults to Enabled (CTRL+ALT+DEL not required)
                    $previousStatus = "Enabled (default)"
                }
            } else {
                $previousStatus = if ($currentValue -eq 0) { "Disabled" } else { "Enabled" }
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Set registry value to disable (0 = disabled, meaning CTRL+ALT+DEL required)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 0) { "Disabled" } else { "Enabled" }
            
            if ($newStatus -eq "Disabled") {
                Write-Host "Interactive logon CTRL+ALT+DEL requirement successfully disabled" -ForegroundColor Green
                Write-Host "CTRL+ALT+DEL will now be required before logon" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Interactive logon CTRL+ALT+DEL requirement successfully disabled"
                }
            } else {
                Write-Host "Failed to disable interactive logon CTRL+ALT+DEL requirement" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to disable interactive logon CTRL+ALT+DEL requirement"
                }
            }
        } else {
            # Registry key doesn't exist, create it and set the value
            Write-Host "Registry key not found, creating it..." -ForegroundColor Yellow
            New-RegistryKey -KeyPath $registryPath
            
            # Set registry value to disable (0 = disabled, meaning CTRL+ALT+DEL required)
            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType "DWord"
            
            # Verify the change
            Start-Sleep -Seconds 2
            $newValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            $newStatus = if ($newValue -eq 0) { "Disabled" } else { "Enabled" }
            
            if ($newStatus -eq "Disabled") {
                Write-Host "Interactive logon CTRL+ALT+DEL requirement successfully configured" -ForegroundColor Green
                Write-Host "CTRL+ALT+DEL will now be required before logon" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Interactive logon CTRL+ALT+DEL requirement successfully configured"
                }
            } else {
                Write-Host "Failed to configure interactive logon CTRL+ALT+DEL requirement" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure interactive logon CTRL+ALT+DEL requirement"
                }
            }
        }
}
