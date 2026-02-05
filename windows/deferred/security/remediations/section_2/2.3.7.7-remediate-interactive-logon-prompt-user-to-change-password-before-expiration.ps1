# Remediation: 2.3.7.7
# CIS Benchmark: 2.3.7.7 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.7.7 - Interactive Logon: Prompt User to Change Password Before Expiration ===" -ForegroundColor Cyan
        Write-Host "Configuring password expiration warning setting..." -ForegroundColor White
        
        # Registry path and value name for this setting
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $valueName = "PasswordExpiryWarning"
        
        # CIS recommendation: 5 to 14 days
        $recommendedValue = 14  # Using maximum recommended value for best user experience
        
        # Check current value
        if (Test-RegistryKey -KeyPath $registryPath) {
            $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "Not Set"
            
            if ($currentValue -eq "Not Set") {
                # Default is 5 days when not set
                $previousStatus = "5 days (default)"
                $previousValue = 5
            } else {
                $previousStatus = "$currentValue days"
                $previousValue = $currentValue
            }
            
            Write-Host "Current setting: $previousStatus" -ForegroundColor White
            
            # Check if current value is within CIS recommendation (5-14 days)
            if ($previousValue -ge 5 -and $previousValue -le 14) {
                Write-Host "Current setting is already within CIS recommendation (5-14 days)" -ForegroundColor Green
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
            $newStatus = if ($newValue -eq "Not Set") { "5 days (default)" } else { "$newValue days" }
            
            if ($newValue -ge 5 -and $newValue -le 14) {
                Write-Host "Password expiration warning successfully configured to $newValue days" -ForegroundColor Green
                Write-Host "Users will be warned $newValue days before password expiration" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $true
                    Message = "Password expiration warning successfully configured to $newValue days"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure password expiration warning within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure password expiration warning within CIS recommendation"
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
            $newStatus = if ($newValue -eq "Not Set") { "5 days (default)" } else { "$newValue days" }
            
            if ($newValue -ge 5 -and $newValue -le 14) {
                Write-Host "Password expiration warning successfully configured to $newValue days" -ForegroundColor Green
                Write-Host "Users will be warned $newValue days before password expiration" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $true
                    Message = "Password expiration warning successfully configured to $newValue days"
                    RemediationApplied = $true
                }
            } else {
                Write-Host "Failed to configure password expiration warning within CIS recommendation" -ForegroundColor Red
                return [PSCustomObject]@{
                    PreviousValue = "Not Configured"
                    NewValue = $newStatus
                    Success = $false
                    Message = "Failed to configure password expiration warning within CIS recommendation"
                    RemediationApplied = $true
                }
            }
        }
}
