# Audit: Enable Certificate Padding setting on Windows
# CIS Benchmark: 18.4.3 (L1) Ensure 'Enable Certificate Padding' is set to 'Enabled'
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
        Write-SectionHeader -Title "Certificate Padding Audit: Enable Certificate Padding"
    }
    
    # Use Invoke-CISAudit with custom script block for certificate padding audit
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.3" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "18" -CustomScriptBlock {
        # Check both registry locations for certificate padding
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Cryptography\Wintrust\Config",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"
        )
        
        $currentValue = "Not Set"
        $source = "Registry"
        $details = ""
        
        foreach ($registryPath in $registryPaths) {
            if (Test-Path $registryPath) {
                $value = Get-ItemProperty -Path $registryPath -Name "EnableCertPaddingCheck" -ErrorAction SilentlyContinue
                if ($value) {
                    $currentValue = $value.EnableCertPaddingCheck
                    $details = "Registry path: $registryPath"
                    break
                }
            }
        }
        
        return @{
            CurrentValue = $currentValue
            Source = $source
            Details = $details
        }
    }
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform certificate padding audit: $($_.Exception.Message)"
    } else {
        $false
    }
}