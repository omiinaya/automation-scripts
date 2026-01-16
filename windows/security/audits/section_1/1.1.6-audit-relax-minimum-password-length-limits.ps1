# Audit: Relax minimum password length limits setting on Windows
# CIS Benchmark: 1.1.6 (L1) Ensure 'Relax minimum password length limits' is set to 'Enabled'
# Refactored to use CIS Framework Module

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the required modules using ModuleIndex
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "Password Policy Audit: Relax Minimum Password Length Limits"
    }
    
    # Use Invoke-CISAudit with registry audit for relax password length limits
    $auditResult = Invoke-CISAudit -CIS_ID "1.1.6" -AuditType "Registry" -VerboseOutput:$VerboseOutput -Section "1" -RegistryPath "HKLM:\System\CurrentControlSet\Control\SAM" -RegistryValueName "RelaxMinimumPasswordLengthLimits"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform password policy audit: $($_.Exception.Message)"
    } else {
        $false
    }
}