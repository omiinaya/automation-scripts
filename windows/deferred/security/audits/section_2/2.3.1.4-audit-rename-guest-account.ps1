# Audit: 2.3.1.4
# CIS Benchmark: 2.3.1.4 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
# Export current security policy
    $tempFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $tempFile /quiet
    
    # Read the exported policy
    $policyContent = Get-Content $tempFile
    
    # Look for the NewGuestName setting
    $guestNameLine = $policyContent | Where-Object { $_ -like "NewGuestName*" }
    
    if ($guestNameLine) {
        $guestNameValue = ($guestNameLine -split "=")[1].Trim()
        $source = "Local Policy"
        
        # Check if the value is not "Guest"
        if ($guestNameValue -ne "Guest" -and -not [string]::IsNullOrWhiteSpace($guestNameValue)) {
            $currentValue = $guestNameValue
            $isCompliant = $true
        } else {
            $currentValue = "Guest"
            $isCompliant = $false
        }
    } else {
        $currentValue = "Guest"
        $source = "Local Default"
        $isCompliant = $false
    }
    
    # Clean up temp file
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    
    $result = @{
        Description = "Guest account name"
        CurrentValue = $currentValue
        ExpectedValue = "Any value other than Guest"
        Source = $source
        Compliant = $isCompliant
    }
    
    $ComplianceResults += $result
    
    if (-not $isCompliant) {
        $OverallCompliant = $false
    }
    
} catch {
    Write-Host "ERROR: Failed to check security policy setting" -ForegroundColor Red
    Write-Host "Exception: $($_.Exception.Message)" -ForegroundColor Red
    
    $result = @{
        Description = "Guest account name"
        CurrentValue = "Unknown (Error)"
        ExpectedValue = "Any value other than Guest"
        Source = "Error"
        Compliant = $false
    }
    
    $ComplianceResults += $result
    $OverallCompliant = $false
}
