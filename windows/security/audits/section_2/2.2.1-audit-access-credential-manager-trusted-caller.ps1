# Audit: Access Credential Manager as a trusted caller setting on Windows
# CIS Benchmark: 2.2.1 (L1) Ensure 'Access Credential Manager as a trusted caller' is set to 'No One'
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
        Write-SectionHeader -Title "User Rights Assignment Audit: Access Credential Manager as a trusted caller"
    }
    
    # Use Invoke-CISAudit with custom script block for user rights assignment audit
    $auditResult = Invoke-CISAudit -CIS_ID "2.2.1" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "2" -CustomScriptBlock {
        # Check user rights assignment using secedit
        try {
            # Export current security policy
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            # Read the exported policy
            $policyContent = Get-Content $tempFile
            $trustedCallerLine = $policyContent | Where-Object { $_ -like "SeTrustedCredManAccessPrivilege*" }
            
            if ($trustedCallerLine) {
                $trustedCallerValue = ($trustedCallerLine -split "=")[1].Trim()
                $source = "Local Policy"
                
                # Check if the value is "No One" (empty or specific value)
                if ([string]::IsNullOrWhiteSpace($trustedCallerValue) -or $trustedCallerValue -eq "") {
                    $currentValue = "No One"
                } else {
                    $currentValue = $trustedCallerValue
                }
            } else {
                $currentValue = "No One"
                $source = "Local Default"
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            $currentValue = "No One"
            $source = "Local Default (assumed)"
        }
        
        # Return custom audit result
        return @{
            CurrentValue = $currentValue
            Source = $source
            Details = "Access Credential Manager as a trusted caller user right assignment audit"
        }
    }
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform user rights assignment audit: $($_.Exception.Message)"
    } else {
        $false
    }
}