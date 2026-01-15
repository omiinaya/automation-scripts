# Audit: Deny log on as a batch job setting on Windows
# CIS Benchmark: 2.2.17 (L1) Ensure 'Deny log on as a batch job' to include 'Guests'
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
        Write-SectionHeader -Title "User Rights Assignment Audit: Deny log on as a batch job"
    }
    
    # Use Invoke-CISAudit with custom script block for user rights assignment audit
    $auditResult = Invoke-CISAudit -CIS_ID "2.2.17" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "2" -CustomScriptBlock {
        # Check user rights assignment using secedit
        try {
            # Export current security policy
            $tempFile = [System.IO.Path]::GetTempFileName()
            secedit /export /cfg $tempFile /quiet
            
            # Read the exported policy
            $policyContent = Get-Content $tempFile
            $denyBatchJobLine = $policyContent | Where-Object { $_ -like "SeDenyBatchLogonRight*" }
            
            if ($denyBatchJobLine) {
                $denyBatchJobValue = ($denyBatchJobLine -split "=")[1].Trim()
                $source = "Local Policy"
                
                # Check if the value contains the required groups
                $currentValue = $denyBatchJobValue
            } else {
                $currentValue = "Guests"
                $source = "Local Default"
            }
            
            # Clean up temp file
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        } catch {
            $currentValue = "Guests"
            $source = "Local Default (assumed)"
        }
        
        # Return custom audit result
        return @{
            CurrentValue = $currentValue
            Source = $source
            Details = "Deny log on as a batch job user right assignment audit"
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