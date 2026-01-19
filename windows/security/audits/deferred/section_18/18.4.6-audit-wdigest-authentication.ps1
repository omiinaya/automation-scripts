# Audit: WDigest Authentication setting on Windows
# CIS Benchmark: 18.4.6 (L1) Ensure 'WDigest Authentication' is set to 'Disabled'
# Refactored to use CIS Framework Module

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the required modules using ModuleIndex
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "WDigest Authentication Audit: WDigest Authentication"
    }
    
    # Use Invoke-CISAudit with registry audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.6" -AuditType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -RegistryValueName "UseLogonCredential" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform WDigest authentication audit: $($_.Exception.Message)"
    } else {
        $false
    }
}