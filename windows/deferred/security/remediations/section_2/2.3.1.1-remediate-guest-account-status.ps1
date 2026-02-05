# Remediation: 2.3.1.1
# CIS Benchmark: 2.3.1.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
Write-Host ""
        Write-Host "=== CIS Remediation: 2.3.1.1 - Guest Account Status ===" -ForegroundColor Cyan
        Write-Host "Disabling Guest account..." -ForegroundColor White
        
        # Check if Guest account exists
        $guestAccount = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
        
        if ($guestAccount) {
            # Get current status
            $previousStatus = if ($guestAccount.Enabled) { "Enabled" } else { "Disabled" }
            Write-Host "Current Guest account status: $previousStatus" -ForegroundColor White
            
            if ($guestAccount.Enabled) {
                # Disable the Guest account
                Disable-LocalUser -Name "Guest"
                
                # Verify the change
                Start-Sleep -Seconds 2
                $updatedAccount = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
                $newStatus = if ($updatedAccount.Enabled) { "Enabled" } else { "Disabled" }
                
                if ($newStatus -eq "Disabled") {
                    Write-Host "Guest account successfully disabled" -ForegroundColor Green
                    return [PSCustomObject]@{
                        PreviousValue = $previousStatus
                        NewValue = $newStatus
                        Success = $true
                        Message = "Guest account successfully disabled"
                    }
                } else {
                    Write-Host "Failed to disable Guest account" -ForegroundColor Red
                    return [PSCustomObject]@{
                        PreviousValue = $previousStatus
                        NewValue = $newStatus
                        Success = $false
                        Message = "Failed to disable Guest account"
                    }
                }
            } else {
                Write-Host "Guest account is already disabled" -ForegroundColor Green
                return [PSCustomObject]@{
                    PreviousValue = $previousStatus
                    NewValue = $previousStatus
                    Success = $true
                    Message = "Guest account is already disabled"
                }
            }
        } else {
            Write-Host "Guest account not found (already disabled)" -ForegroundColor Green
            return [PSCustomObject]@{
                PreviousValue = "Not Found"
                NewValue = "Disabled"
                Success = $true
                Message = "Guest account not found (already disabled)"
            }
        }
}
