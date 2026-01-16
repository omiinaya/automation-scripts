# Audit: Turn off Microsoft Peer-to-Peer Networking Services
# CIS Benchmark: 18.6.10.2 (L2) Ensure 'Turn off Microsoft Peer-to-Peer Networking Services' is set to 'Enabled'
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
        Write-SectionHeader -Title "Peer-to-Peer Networking Services Audit: Turn off Microsoft Peer-to-Peer Networking Services"
    }
    
    # Use Invoke-CISAudit with GroupPolicy audit type for Peer-to-Peer Networking Services
    $auditResult = Invoke-CISAudit -CIS_ID "18.6.10.2" -AuditType "GroupPolicy" -VerboseOutput:$VerboseOutput -Section "18" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Peernet" -RegistryValueName "Disabled"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform Peer-to-Peer Networking Services audit: $($_.Exception.Message)"
    } else {
        $false
    }
}