# Audit: 2.3.1.3
# CIS Benchmark: 2.3.1.3 (L1)

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
    
    # Look for the NewAdministratorName setting
    $adminNameLine = $policyContent | Where-Object { $_ -like "NewAdministratorName*" }
    
    if ($adminNameLine) {
        $adminNameValue = ($adminNameLine -split "=")[1].Trim()
        $source = "Local Policy"
        
        # Check if the value is not "Administrator"
        if ($adminNameValue -ne "Administrator" -and -not [string]::IsNullOrWhiteSpace($adminNameValue)) {
            $currentValue = $adminNameValue
            $isCompliant = $true
        } else {
            $currentValue = "Administrator"
            $isCompliant = $false
        }
    } else {
        $currentValue = "Administrator"
        $source = "Local Default"
        $isCompliant = $false
    }
    
    # Clean up temp file
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    
    $result = @{
        Description = "Administrator account name"
        CurrentValue = $currentValue
        ExpectedValue = "Any value other than Administrator"
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
        Description = "Administrator account name"
        CurrentValue = "Unknown (Error)"
        ExpectedValue = "Any value other than Administrator"
        Source = "Error"
        Compliant = $false
    }
    
    $ComplianceResults += $result
    $OverallCompliant = $false
}
