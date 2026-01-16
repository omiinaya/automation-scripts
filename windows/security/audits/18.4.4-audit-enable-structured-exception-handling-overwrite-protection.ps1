# Audit: Enable Structured Exception Handling Overwrite Protection (SEHOP) setting on Windows
# CIS Benchmark: 18.4.4 (L1) Ensure 'Enable Structured Exception Handling Overwrite Protection (SEHOP)' is set to 'Enabled'
# Refactored to use CIS Framework Module

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the required modules using ModuleIndex
$modulePath = Join-Path $PSScriptRoot "..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "SEHOP Audit: Enable Structured Exception Handling Overwrite Protection"
    }
    
    # Use Invoke-CISAudit with registry audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.4" -AuditType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -RegistryValueName "DisableExceptionChainValidation" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform SEHOP audit: $($_.Exception.Message)"
    } else {
        $false
    }
}