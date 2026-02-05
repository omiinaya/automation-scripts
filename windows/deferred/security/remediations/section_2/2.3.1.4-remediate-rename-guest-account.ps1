# Remediation: 2.3.1.4
# CIS Benchmark: 2.3.1.4 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
# Create security policy template
    $templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature=`"`$CHICAGO`$`"
Revision=1
[Registry Values]
MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\NewGuestName=$NewName
"@
    
    # Save template to temporary file
    $templateFile = [System.IO.Path]::GetTempFileName()
    $templateContent | Out-File -FilePath $templateFile -Encoding Unicode
    
    # Apply the security policy
    $databaseFile = [System.IO.Path]::GetTempFileName()
    secedit /configure /db $databaseFile /cfg $templateFile /quiet
    
    # Verify the change was applied
    $verifyFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $verifyFile /quiet
    
    $verifyContent = Get-Content $verifyFile
    $appliedValue = ($verifyContent | Where-Object { $_ -like "NewGuestName*" } | ForEach-Object { ($_ -split "=")[1].Trim() })
    
    if ($appliedValue -eq $NewName) {
        $result = @{
            Description = "Guest account name"
            Success = $true
            ErrorMessage = $null
        }
        Write-Host "  SUCCESS: Guest account renamed to '$NewName'" -ForegroundColor Green
    } else {
        $result = @{
            Description = "Guest account name"
            Success = $false
            ErrorMessage = "Failed to verify the name change was applied"
        }
        Write-Host "  FAILED: Could not verify Guest account rename" -ForegroundColor Red
        $OverallSuccess = $false
    }
    
    # Clean up temporary files
    Remove-Item $templateFile, $databaseFile, $verifyFile -ErrorAction SilentlyContinue
    
    $RemediationResults += $result
    
} catch {
    Write-Host "  ERROR: Failed to rename Guest account" -ForegroundColor Red
    Write-Host "    Exception: $($_.Exception.Message)" -ForegroundColor Red
    $OverallSuccess = $false
    $RemediationResults += @{
        Description = "Guest account name"
        Success = $false
        ErrorMessage = $_.Exception.Message
    }
}
